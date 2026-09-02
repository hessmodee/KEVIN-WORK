import copy
import unittest

from contract import (
    ContractError,
    EXPECTED_BENCHMARK_SHA256,
    EXPECTED_CURRENT_CONFIG_SHA256,
    EXPECTED_PREVIOUS_CONFIG_SHA256,
    non_target_fingerprint,
    plan_rebaseline,
    semantic_leaf_map,
    validate_preconditions,
    validate_transition,
)


def baseline():
    return {
        "schema": 1,
        "kind": "kevin-benchmark-v1-baseline",
        "created_at": "2026-09-02T00:00:00-06:00",
        "openclaw": "2026.7.1-2",
        "hashes": {
            "supervisor": "A" * 64,
            "forge": "B" * 64,
            "production_config": EXPECTED_PREVIOUS_CONFIG_SHA256,
            "reader_config": "C" * 64,
            "goal_os": "D" * 64,
            "promotion_policy": "E" * 64,
            "benchmark_spec": "F" * 64,
            "benchmark_runner": EXPECTED_BENCHMARK_SHA256,
        },
        "policy": {
            "regression_required_percent": 100,
            "critical_model_required_percent": 100,
            "staging_to_shadow": "LOCKED_UNTIL_SEPARATE_SANDBOX_ADAPTER",
        },
    }


def latest():
    rows = []
    for i in range(1, 31):
        rows.append({"id": f"R{i:02d}", "pass": i != 4, "critical": i == 4})
    return {
        "status": "FAIL_CRITICAL_REGRESSION",
        "regression": {"passed": 29, "total": 30, "critical_failures": 1, "rows": rows},
    }


class R04ContractTests(unittest.TestCase):
    def test_exact_one_leaf_plan(self):
        before = baseline()
        after = plan_rebaseline(before)
        self.assertEqual(after["hashes"]["production_config"], EXPECTED_CURRENT_CONFIG_SHA256)
        self.assertEqual(non_target_fingerprint(before), non_target_fingerprint(after))
        changed = [
            k for k, v in semantic_leaf_map(before).items()
            if semantic_leaf_map(after).get(k) != v
        ]
        self.assertEqual(changed, ["$.hashes.production_config"])
        validate_transition(before, after)

    def test_valid_preconditions(self):
        validate_preconditions(
            current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
            benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
            baseline=baseline(),
            latest_benchmark=latest(),
        )

    def test_reject_unrecognized_current_config(self):
        with self.assertRaises(ContractError):
            validate_preconditions(
                current_config_sha256="0" * 64,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=baseline(), latest_benchmark=latest())

    def test_reject_unrecognized_previous_baseline(self):
        b = baseline()
        b["hashes"]["production_config"] = "9" * 64
        with self.assertRaises(ContractError):
            validate_preconditions(
                current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=b, latest_benchmark=latest())

    def test_reject_non_r04_failure(self):
        x = latest()
        x["regression"]["rows"][3]["pass"] = True
        x["regression"]["rows"][6]["pass"] = False
        with self.assertRaises(ContractError):
            validate_preconditions(
                current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=baseline(), latest_benchmark=x)

    def test_reject_multiple_failures(self):
        x = latest()
        x["regression"]["passed"] = 28
        x["regression"]["critical_failures"] = 2
        x["regression"]["rows"][5]["pass"] = False
        with self.assertRaises(ContractError):
            validate_preconditions(
                current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=baseline(), latest_benchmark=x)

    def test_transition_rejects_other_leaf_change(self):
        before = baseline()
        after = plan_rebaseline(before)
        after["policy"]["regression_required_percent"] = 99
        with self.assertRaises(ContractError):
            validate_transition(before, after)

    def test_planner_does_not_mutate_input(self):
        before = baseline()
        saved = copy.deepcopy(before)
        plan_rebaseline(before)
        self.assertEqual(before, saved)

    def test_reject_missing_required_anchor(self):
        b = baseline()
        del b["hashes"]["goal_os"]
        with self.assertRaises(ContractError):
            plan_rebaseline(b)


    def assert_invalid_evidence(self, evidence):
        with self.assertRaises(ContractError):
            validate_preconditions(current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=baseline(), latest_benchmark=evidence)

    def test_missing_empty_short_and_nonlist_rows_rejected(self):
        for rows in (None, [], latest()["regression"]["rows"][:29], "rows", {}):
            with self.subTest(rows=type(rows).__name__):
                x = latest(); x["regression"]["rows"] = rows
                self.assert_invalid_evidence(x)
        x = latest(); del x["regression"]["rows"]
        self.assert_invalid_evidence(x)

    def test_duplicate_unknown_and_malformed_rows_rejected(self):
        for replacement in ({"id": "R01", "pass": True, "critical": False},
                            {"id": "R99", "pass": True, "critical": False}, None, "R30"):
            with self.subTest(replacement=replacement):
                x = latest(); x["regression"]["rows"][-1] = replacement
                self.assert_invalid_evidence(x)

    def test_string_verdicts_and_noncritical_r04_rejected(self):
        for field, value in (("pass", "false"), ("pass", 0), ("critical", "true"), ("critical", False)):
            with self.subTest(field=field, value=value):
                x = latest(); x["regression"]["rows"][3][field] = value
                self.assert_invalid_evidence(x)

    def test_counts_are_exact_integers(self):
        for field, value in (("passed", "29"), ("total", 30.1), ("critical_failures", True)):
            with self.subTest(field=field):
                x = latest(); x["regression"][field] = value
                self.assert_invalid_evidence(x)

    def test_inconsistent_status_rejected(self):
        x = latest(); x["status"] = "PASS"
        self.assert_invalid_evidence(x)

    def test_baseline_runner_must_match(self):
        b = baseline(); b["hashes"]["benchmark_runner"] = "9" * 64
        with self.assertRaises(ContractError):
            validate_preconditions(current_config_sha256=EXPECTED_CURRENT_CONFIG_SHA256,
                benchmark_runner_sha256=EXPECTED_BENCHMARK_SHA256,
                baseline=b, latest_benchmark=latest())

    def test_added_removed_empty_containers_rejected(self):
        for empty in ({}, []):
            with self.subTest(empty=empty):
                b = baseline(); a = plan_rebaseline(b); a["policy"]["new"] = empty
                with self.assertRaises(ContractError): validate_transition(b, a)
                b["policy"]["old"] = empty; a = plan_rebaseline(b); del a["policy"]["old"]
                with self.assertRaises(ContractError): validate_transition(b, a)

    def test_container_type_swap_rejected(self):
        b = baseline(); b["policy"]["empty"] = {}; a = plan_rebaseline(b)
        a["policy"]["empty"] = []
        with self.assertRaises(ContractError): validate_transition(b, a)

    def test_dotted_key_and_nested_key_are_distinct(self):
        b = baseline(); b["policy"]["x.y"] = True; a = plan_rebaseline(b)
        del a["policy"]["x.y"]; a["policy"]["x"] = {"y": True}
        with self.assertRaises(ContractError): validate_transition(b, a)

    def test_target_named_literal_key_is_not_excluded(self):
        b = baseline(); b["hashes.production_config"] = "original"; a = plan_rebaseline(b)
        a["hashes.production_config"] = "changed"
        with self.assertRaises(ContractError): validate_transition(b, a)

    def test_array_like_literal_key_is_distinct(self):
        b = baseline(); b["policy"]["x"] = {"[0]": True}; a = plan_rebaseline(b)
        a["policy"]["x"] = [True]
        with self.assertRaises(ContractError): validate_transition(b, a)

    def test_unknown_before_identity_not_blessed_by_planner_or_transition(self):
        b = baseline(); a = plan_rebaseline(b); b["hashes"]["production_config"] = "9" * 64
        with self.assertRaises(ContractError): plan_rebaseline(b)
        with self.assertRaises(ContractError): validate_transition(b, a)

    def test_boolean_schema_is_not_schema_one(self):
        b = baseline(); b["schema"] = True
        with self.assertRaises(ContractError): plan_rebaseline(b)

    def test_object_key_order_is_semantically_irrelevant(self):
        b = baseline(); a = plan_rebaseline(b)
        a["hashes"] = dict(reversed(list(a["hashes"].items())))
        validate_transition(b, a)


if __name__ == "__main__":
    unittest.main()
