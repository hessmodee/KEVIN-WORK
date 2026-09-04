#!/usr/bin/env python3
import datetime as dt
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADM = ROOT / "control-plane" / "autonomy" / "kevin-work-admission-v1.py"
spec = importlib.util.spec_from_file_location("admission", ADM)
admission = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(admission)

NOW = dt.datetime(2026, 9, 4, 14, 30, tzinfo=dt.timezone.utc)
PROGRAMS = json.loads((ROOT / "control-plane/autonomy/standing-programs-v1.json").read_text())
# Prefer landed programs; fall back to repo copy during early edit.
if not any(p["id"] == "owner-value-skills" for p in PROGRAMS["programs"]):
    raise SystemExit("owner-value-skills missing from standing-programs fixture")

FAMILIES = {
    "schema": 1,
    "kind": "kevin-failure-family-registry",
    "policy": {
        "max_material_attempts": 3,
        "rename_does_not_reset_budget": True,
        "request_id_does_not_reset_budget": True,
        "iteration_does_not_reset_budget": True,
        "reopen_requires_material_new_evidence": True,
    },
    "families": [],
}
STATE = {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}
CATALOG = {"schema": 1, "standing_work": []}
SKILL_INV = {
    "capabilities": [{"id": "kevin_skill_lab_execute", "effective": True}],
    "workers": [{"id": "skill-lab", "effective": True, "capabilities": ["kevin_skill_lab_execute"]}],
    "agents": {"fixed:main": {"tools": False, "tool_count": 0}},
}


def run(items, inventory=None, catalog=None):
    return admission.admit(
        {"schema": 1, "kind": "kevin-work-items", "items": items},
        catalog or CATALOG,
        PROGRAMS,
        FAMILIES,
        STATE,
        inventory or SKILL_INV,
        {},
        {},
        {},
        [],
        NOW,
        ROOT / "control-plane/autonomy/kevin-work-selector-v1.2.py",
        ROOT / "control-plane/autonomy/kevin-work-supply-v1.py",
        ROOT / "control-plane/autonomy/kevin-capability-router-v1.py",
    )


def test_owner_skill_lab_selected_and_not_dispatched_to_main():
    items = [{
        "id": "owner-composite-appliance-repair-pack-v2-prove",
        "program": "owner-value-skills",
        "authority_class": "GREEN",
        "status": "OPEN",
        "lane": "skill-lab",
        "worker": "skill-lab",
        "work_type": "execution",
        "severity": "high",
        "owner_value": 5,
        "dependencies_ready": True,
        "blocked": False,
        "failure_attempts": 0,
        "required_capabilities": ["kevin_skill_lab_execute"],
        "acceptance_criteria": ["Skill Lab PROVEN via GREEN primitives"],
        "next_action": "Stage+prove appliance pack v2",
    }]
    # supply module must exist in tree
    supply_src = ROOT / "control-plane/autonomy/kevin-work-supply-v1.py"
    if not supply_src.exists():
        # copy expectation: tests run from full repo checkout
        raise AssertionError("kevin-work-supply-v1.py must be present")
    out = run(items)
    assert out["selection"]["selected_id"] == "owner-composite-appliance-repair-pack-v2-prove"
    assert out["supervisor_action"] == "DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN"
    assert out["routing"]["dispatch"] == "ROUTE_TO_SKILL_LAB"
    assert out["truth_state"] == "ELIGIBLE_WORK"
    assert out["invariants"]["no_skill_lab_to_fixed_main"] is True


def test_desktop_not_routed_to_toolless_main_via_supply():
    catalog = {
        "schema": 1,
        "standing_work": [{
            "id": "desktop-typed-crossing-runtime-proof-v1",
            "program": "computer-fluency",
            "lane": "production",
            "work_type": "verification",
            "severity": "high",
            "owner_value": 5,
            "worker": "operator",
            "required_capabilities": ["kevin_desktop_runtime_installed", "kevin_desktop_runtime_probe"],
            "effects": [],
            "trigger": {"kind": "always"},
            "acceptance_criteria": ["Desktop tools effective in fixed:main"],
            "next_action": "Install Desktop crossing",
        }],
    }
    # empty base items; supply generates blocked desktop item
    out = run([], inventory={
        "capabilities": [],
        "workers": [],
        "agents": {"fixed:main": {"tools": False, "tool_count": 0}},
    }, catalog=catalog)
    assert out["truth_state"] == "BLOCKED_WORK_PRESENT"
    assert out["supervisor_action"] in {
        "RECORD_BLOCKER_DO_NOT_CALL_MAIN",
        "IDLE_CHECK_ONLY",
        "DEFER_TO_TYPED_WORKER_DO_NOT_CALL_MAIN",
        "DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN",
        "DEFER_TO_ENGINEERING_RELAY_DO_NOT_CALL_MAIN",
    }
    assert out["supervisor_action"] != "DISPATCH_FIXED_MAIN"
    # If selector somehow picked it, router must block.
    if out["selection"]["selected_id"] == "desktop-typed-crossing-runtime-proof-v1":
        assert out["routing"]["dispatch"] == "BLOCKED"
        assert "DESKTOP_REQUIRED_BUT_FIXED_MAIN_TOOLLESS" in (out["routing"].get("route") or {}).get("reason", "")


def test_blocked_backlog_not_true_idle_when_selector_empty():
    items = [{
        "id": "finish-forge-v40-runtime-convergence",
        "program": "platform-reliability",
        "authority_class": "GREEN",
        "status": "BLOCKED",
        "lane": "production",
        "blocked": True,
        "dependencies_ready": False,
        "failure_attempts": 3,
        "acceptance_criteria": ["Forge demand-driven"],
        "next_action": "diagnosis only",
    }]
    out = run(items, inventory={
        "capabilities": [],
        "agents": {"fixed:main": {"tools": False, "tool_count": 0}},
    })
    assert out["selection"]["selected_id"] is None
    assert out["truth_state"] == "BLOCKED_WORK_PRESENT"
    assert out["supervisor_action"] == "IDLE_CHECK_ONLY"


if __name__ == "__main__":
    # Ensure supply module is available beside admission in landing dir or repo.
    supply = ROOT / "control-plane/autonomy/kevin-work-supply-v1.py"
    if not supply.exists():
        import shutil
        shutil.copy(Path("/workspace/kevin-work/control-plane/autonomy/kevin-work-supply-v1.py"), supply)
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
    print(f"KEVIN WORK ADMISSION v1 SELFTEST PASS ({len(tests)} tests)")
