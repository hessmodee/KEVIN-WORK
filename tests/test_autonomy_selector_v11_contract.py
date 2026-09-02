"""CI-only admission fixtures. Never enqueue work or mutate runtime state."""
from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "kevin_selector_v11", ROOT / "control-plane/autonomy/kevin-work-selector-v1.1.py"
)
selector = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = selector
SPEC.loader.exec_module(selector)
NOW = dt.datetime(2026, 9, 2, 6, 0, tzinfo=dt.timezone.utc)
PROGRAMS = {"schema": 1, "kind": "kevin-standing-program-registry", "programs": [
    {"id": "fixture-program", "base_priority": 100}
]}
FAMILIES = {"schema": 1, "kind": "kevin-failure-family-registry", "policy": {
    "max_material_attempts": 3, "rename_does_not_reset_budget": True,
    "request_id_does_not_reset_budget": True, "iteration_does_not_reset_budget": True,
    "reopen_requires_material_new_evidence": True
}, "families": [{"id": "fixture-blocked-family", "state": "BLOCKED", "attempts": 3}]}
STATE = {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}


def item(identity="fixture-ready", **updates):
    value = {"id": identity, "program": "fixture-program", "authority_class": "GREEN",
             "status": "READY", "lane": "production", "dependencies_ready": True,
             "acceptance_criteria": ["CI fixture only; never dispatched"], "failure_attempts": 0}
    value.update(updates)
    return value


def run_fixture(items, state=None):
    docs = copy.deepcopy((PROGRAMS, {"schema": 1, "kind": "kevin-work-items", "items": items},
                          STATE if state is None else state, FAMILIES))
    before = copy.deepcopy(docs)
    result = selector.select(*docs, NOW)
    if docs != before:
        raise AssertionError("selector mutated its input contracts")
    return result


def check_result(result, expected_ids):
    """Independent expected set supplied by fixture or current-input oracle."""
    assert result["authority_effect"] == "NONE_SELECTION_ONLY"
    assert result["advisory_only"] is True
    assert result["semantic_failure_families"] is True
    actual = [entry["id"] for entry in result["eligible"]]
    assert len(actual) == len(set(actual))
    assert set(actual) == set(expected_ids), (actual, expected_ids)
    assert result["eligible_count"] == len(expected_ids)
    if expected_ids:
        assert result["status"] == "SELECTED"
        assert result["selection"] == result["eligible"][0]
        assert result["selection"]["id"] in expected_ids
    else:
        assert result["status"] == "NO_ELIGIBLE_WORK"
        assert result["selection"] is None


def expected_current_ids(programs, inventory, state, families, now):
    """Eligibility oracle independent of selector admission/score functions.

    Current-inventory smoke validation is not a substitute for fixed fixtures.
    Keep this predicate aligned with the v1.1 documented contract, never with
    assumptions that a particular owner task must remain READY forever.
    """
    known_programs = {p["id"] for p in programs["programs"]}
    family_by_id = {f["id"]: f for f in families["families"]}
    result = set()
    seen = set()
    for row in inventory["items"]:
        identity = row.get("id")
        if identity in seen:
            continue
        seen.add(identity)
        lane = str(row.get("lane", "")).lower()
        work_type = str(row.get("work_type", "execution")).lower()
        criteria = row.get("acceptance_criteria")
        attempts = row.get("failure_attempts", 0)
        if not identity or row.get("authority_class") != "GREEN":
            continue
        if str(row.get("status", "")).upper() not in {"OPEN", "READY"}:
            continue
        if row.get("program") not in known_programs or lane not in {"production", "staging", "research"}:
            continue
        if state["wip"][lane] >= 1 or row.get("blocked") is True or row.get("dependencies_ready") is False:
            continue
        if row.get("owner_checkpoint_required") is True or row.get("reserved_effect") is True or row.get("duplicate_of"):
            continue
        if not isinstance(criteria, list) or not any(str(c).strip() for c in criteria):
            continue
        if not isinstance(attempts, int) or attempts < 0 or (attempts >= 3 and not row.get("material_new_evidence", False)):
            continue
        if row.get("cooldown_until"):
            until = dt.datetime.fromisoformat(str(row["cooldown_until"]).replace("Z", "+00:00"))
            if until.tzinfo is None:
                raise AssertionError("current cooldown lacks timezone")
            if until > now:
                continue
        family_id = str(row.get("failure_family", "")).strip()
        if family_id:
            family = family_by_id.get(family_id)
            if family is None:
                continue
            diagnosis = (work_type == "research" and row.get("read_only_diagnosis") is True
                         and row.get("production_effect") in {None, "NONE"})
            if str(family["state"]).upper() in {"BLOCKED", "COOLED"} and not diagnosis:
                continue
        if work_type in {"candidate", "research", "design"} and not str(row.get("downstream_consumer", "")).strip():
            continue
        if work_type in {"candidate", "design"} and not str(row.get("hypothesis_id", "")).strip():
            continue
        result.add(identity)
    return result


class AdmissionContract(unittest.TestCase):
    def test_eligible_work_must_not_idle(self):
        check_result(run_fixture([item()]), {"fixture-ready"})

    def test_empty_inventory_must_idle(self):
        check_result(run_fixture([]), set())

    def test_completed_and_blocked_inventory_must_idle(self):
        check_result(run_fixture([item("fixture-done", status="COMPLETE"),
                                  item("fixture-held", blocked=True)]), set())

    def test_completed_high_value_work_cannot_hide_ready_alternative(self):
        result = run_fixture([item("fixture-done", status="COMPLETE", severity="critical", owner_value=5),
                              item("fixture-alternative", lane="staging")])
        check_result(result, {"fixture-alternative"})

    def test_production_wip_does_not_block_staging(self):
        state = copy.deepcopy(STATE)
        state["wip"]["production"] = 1
        check_result(run_fixture([item(), item("fixture-staging", lane="staging")], state),
                     {"fixture-staging"})

    def test_family_rename_and_prose_cannot_reopen_blocked_family(self):
        rows = [item("fixture-renamed-" + str(n), failure_family="fixture-blocked-family",
                     material_new_evidence=True, next_action="different prose " + str(n)) for n in range(3)]
        result = run_fixture(rows)
        check_result(result, set())
        self.assertTrue(all("FAILURE_FAMILY_BLOCKED" in r["reasons"] for r in result["blocked"]))

    def test_other_admission_boundaries_remain_blocking(self):
        cases = [{"authority_class": "YELLOW"}, {"authority_class": "RED"},
                 {"dependencies_ready": False}, {"owner_checkpoint_required": True},
                 {"reserved_effect": True}, {"duplicate_of": "fixture-other"},
                 {"failure_attempts": 3}, {"failure_attempts": -1},
                 {"cooldown_until": "2099-01-01T00:00:00Z"},
                 {"failure_family": "fixture-unknown"}, {"acceptance_criteria": []},
                 {"work_type": "research"}, {"program": "unknown"}, {"lane": "unknown"}]
        for case in cases:
            with self.subTest(case=case):
                check_result(run_fixture([item(**case)]), set())

    def test_readonly_research_requires_named_consumer(self):
        row = item(work_type="research", lane="research", read_only_diagnosis=True,
                   production_effect="NONE", failure_family="fixture-blocked-family",
                   downstream_consumer="fixture-controller-qualification")
        check_result(run_fixture([row]), {"fixture-ready"})
        row["production_effect"] = "MUTATION"
        check_result(run_fixture([row]), set())

    def test_deterministic_priority_and_tie_break(self):
        result = run_fixture([item("fixture-z"), item("fixture-b"),
                              item("fixture-a", owner_value=5)])
        check_result(result, {"fixture-a", "fixture-b", "fixture-z"})
        self.assertEqual([r["id"] for r in result["eligible"]], ["fixture-a", "fixture-b", "fixture-z"])

    def test_oracle_rejects_false_idle(self):
        false_idle = run_fixture([])
        with self.assertRaises(AssertionError):
            check_result(false_idle, {"fixture-ready"})

    def test_oracle_rejects_false_eligible(self):
        false_selected = run_fixture([item()])
        with self.assertRaises(AssertionError):
            check_result(false_selected, set())

    def test_malformed_registry_fails_closed(self):
        with self.assertRaises(selector.ContractError):
            selector.select(PROGRAMS, {"schema": 99}, STATE, FAMILIES, NOW)

    def test_current_inventory_matches_independent_oracle_without_mutation(self):
        paths = ["control-plane/autonomy/standing-programs-v1.json", "inbox/autonomy/work-items.json",
                 "inbox/autonomy/state.json", "control-plane/autonomy/failure-families-v1.json"]
        raw = [(ROOT / path).read_bytes() for path in paths]
        docs = [json.loads(blob) for blob in raw]
        before = copy.deepcopy(docs)
        now = dt.datetime.now(dt.timezone.utc)
        expected = expected_current_ids(*docs, now)
        result = selector.select(*docs, now)
        check_result(result, expected)
        self.assertEqual(docs, before)
        self.assertEqual([(ROOT / path).read_bytes() for path in paths], raw)
        print("CURRENT_INVENTORY_CONTRACT PASS eligible_count=" + str(len(expected)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
