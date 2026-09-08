import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "kevin_support_cron_truth_v1",
    ROOT / "control-plane" / "autonomy" / "kevin-support-cron-truth-v1.py",
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)

HEALTHY_LANES = [
    {"declaration_key": key, "enabled": True, "every_ms": 120000, "last_status": "ok", "consecutive_errors": 0}
    for key in mod.EXPECTED_LANES
]


class SupportCronTruthTests(unittest.TestCase):
    def test_warning_only_does_not_become_scheduler_false(self):
        out = mod.interpret_cron({"ok": False, "jobs": [], "error": "Config warnings:"})
        self.assertIsNone(out["scheduler_ok"])
        self.assertTrue(out["warning_only_parse"])
        self.assertTrue(out["support_ok_field_is_not_scheduler_health"])
        self.assertEqual("Config warnings:", out["config_warnings"])
        self.assertNotEqual(False, out["scheduler_ok"])

    def test_warning_only_plus_healthy_engineering_is_scheduler_ok(self):
        out = mod.interpret_cron(
            {"ok": False, "jobs": [], "error": "Config warnings:"},
            HEALTHY_LANES,
        )
        self.assertTrue(out["scheduler_ok"])
        self.assertEqual("engineering.action.cron", out["evidence_source"])
        self.assertEqual("Config warnings:", out["config_warnings"])
        self.assertEqual(6, len(out["jobs"]))

    def test_real_failed_job_stays_unhealthy(self):
        jobs = [{"declaration_key": "kevin-supervisor-v1", "enabled": True, "last_status": "error", "consecutive_errors": 3}]
        out = mod.interpret_cron({"ok": False, "jobs": jobs, "error": "cron failed"})
        self.assertFalse(out["scheduler_ok"])
        self.assertFalse(out["warning_only_parse"])
        self.assertEqual("", out["config_warnings"])

    def test_does_not_hardcode_healthy_when_engineering_missing_a_lane(self):
        incomplete = HEALTHY_LANES[:-1]
        out = mod.interpret_cron({"ok": False, "jobs": [], "error": "Config warnings:"}, incomplete)
        self.assertIsNone(out["scheduler_ok"])
        self.assertEqual("unverified", out["evidence_source"])


if __name__ == "__main__":
    unittest.main()
