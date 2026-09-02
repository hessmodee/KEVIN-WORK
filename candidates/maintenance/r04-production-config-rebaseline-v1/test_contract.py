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


if __name__ == "__main__":
    unittest.main()
