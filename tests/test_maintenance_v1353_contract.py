#!/usr/bin/env python3
"""Static contract for Maintenance v1.3.53 / Supervisor v1.8.12 install."""

from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.53.ps1"
PARENT = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.52.ps1"
SUPERVISOR = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.12.ps1"
SUPERVISOR_BEFORE = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.11.ps1"
WORKER = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"
BUILDER = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-request-builder-v1.py"
INVOKER = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.py"
SELECTOR = ROOT / "control-plane" / "autonomy" / "kevin-work-selector-v1.2.py"

PARENT_SHA = "C5ECCE66FF2DB764E8C6EC4449F76D9086A8DCCED37428F515B0C14DD803DD24"
RUNNER_SHA = "EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50"
SUPERVISOR_BEFORE_SHA = "685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79"
SUPERVISOR_AFTER = "F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB"
WORKER_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"
BUILDER_SHA = "8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9"
INVOKER_SHA = "63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C"
SELECTOR_SHA = "52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A"

PARENT_OPS = [
    "replace_pinned_component",
    "restart_ui_bridge",
    "audit_runtime_convergence",
    "publish_runtime_convergence",
    "publish_runtime_capabilities",
    "replace_runtime_policy_bundle",
    "migrate_design_forge_v40",
    "configure_skill_workshop_guardrails",
    "run_reader_status_canary",
    "diagnose_forge_r03_contract",
    "diagnose_goal_os_forge_anchor",
    "diagnose_benchmark_baseline_forge_anchor",
    "migrate_supervisor_forge_demand_gated_v17",
    "repair_supervisor_v171_forge_pin",
    "ensure_autonomy_continuation_automation",
    "run_main_agent_canary",
    "install_autonomy_controller_v183",
    "install_autonomy_controller_v1810",
    "install_autonomy_controller_v1811",
    "diagnose_gateway_rpc",
    "run_self_reliance_watchdog_once",
    "diagnose_gateway_failure_detail",
    "repair_openclaw_windows_lkg",
    "reconcile_maintenance_cron_backoff",
    "diagnose_main_tool_policy",
    "ensure_ui_bridge_watchdog",
    "refresh_full_autonomy_assessment",
    "sync_local_desired_state_v19",
    "retire_legacy_night_forge",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class MaintenanceV1353ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = RUNNER.read_text(encoding="utf-8")
        cls.raw = RUNNER.read_bytes()

    def test_lf_only_identity(self) -> None:
        self.assertNotIn(b"\r", self.raw, "runner must be LF so Windows Get-FileHash matches Git blob")
        self.assertTrue(self.raw.startswith(b"param("))

    def test_parent_and_component_pins_match_tree(self) -> None:
        self.assertEqual(sha256(PARENT), PARENT_SHA)
        self.assertEqual(sha256(SUPERVISOR), SUPERVISOR_AFTER)
        self.assertEqual(sha256(SUPERVISOR_BEFORE), SUPERVISOR_BEFORE_SHA)
        self.assertEqual(sha256(WORKER), WORKER_SHA)
        self.assertEqual(sha256(BUILDER), BUILDER_SHA)
        self.assertEqual(sha256(INVOKER), INVOKER_SHA)
        self.assertEqual(sha256(SELECTOR), SELECTOR_SHA)
        for pin in (PARENT_SHA, SUPERVISOR_BEFORE_SHA, SUPERVISOR_AFTER, WORKER_SHA, BUILDER_SHA, INVOKER_SHA, SELECTOR_SHA):
            self.assertIn(pin, self.text)

    def test_selftest_marker_and_v1812_allowlist(self) -> None:
        self.assertIn("KEVIN MAINTENANCE v1.3.3 SELFTEST PASS", self.text)
        self.assertIn("compatibility=v1.3.53", self.text)
        self.assertIn("install_autonomy_controller_v1812", self.text)
        self.assertIn("Install-AutonomyControllerV1812", self.text)
        self.assertIn("proven_skill_before_skill_lab=true", self.text)
        self.assertIn("invocation_not_main=true", self.text)
        self.assertIn("invocation_worker_native_error_fail_closed=true", self.text)
        self.assertIn("ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1", self.text)
        self.assertIn("control-plane/autonomy/kevin-supervisor-v1.8.12.ps1", self.text)
        self.assertIn("worker_native_error=fail_closed", self.text)

    def test_parent_ops_preserved(self) -> None:
        for op in PARENT_OPS:
            self.assertIn("'" + op + "'", self.text, op)

    def test_no_forbidden_execution_surface(self) -> None:
        for pattern in (
            r"(?im)^\s*Invoke-Expression\b",
            r"(?im)^\s*kevin_shell\b",
            r"(?im)^\s*Start-Process\s+cmd\.exe\b",
        ):
            self.assertIsNone(re.search(pattern, self.text), pattern)

    def test_does_not_mutate_live_manifest_slot(self) -> None:
        self.assertIn("inbox/maintenance/manifest.json", self.text)
        self.assertNotIn("Set-Content", self.text)
        self.assertIn("parent_invoked=$false", self.text)
        self.assertIn("execution_attempted=$false", self.text)

    def test_fail_closed_fetch_allowlist(self) -> None:
        self.assertIn("v1.8.12 autonomy source path rejected", self.text)
        self.assertIn("repo path rejected", self.text)
        self.assertIn("?ref=main", self.text)
        self.assertNotRegex(self.text, r"ref=grok/")
        self.assertIn("history_preserved=$true", self.text)
        self.assertIn("work_items_preserved=$true", self.text)
        self.assertIn("mission_leases_preserved=$true", self.text)
        self.assertIn("rollback completed", self.text)
        self.assertIn("Assert-Benchmark30", self.text)

    def test_does_not_alias_supervisor_replace(self) -> None:
        self.assertIsNone(re.search(r"target_alias.*=\s*'supervisor'", self.text))
        self.assertIn("must not supply", self.text)

    def test_live_manifest_slot_is_green_and_bounded(self) -> None:
        manifest = json.loads((ROOT / "inbox" / "maintenance" / "manifest.json").read_text(encoding="utf-8"))
        op = manifest.get("operation")
        # Operational slot. After v1.3.53 is installed, v1812 is the legitimate next GREEN op.
        self.assertIn(op, {
            "install_autonomy_controller_v1812",
            "replace_pinned_component",
            "run_main_agent_canary",
        })
        self.assertEqual(manifest.get("authority_class"), "GREEN")
        self.assertEqual(manifest.get("authority_delta"), "NONE")
        if op == "replace_pinned_component":
            self.assertEqual(manifest.get("target_alias"), "maintenance_runner")
            self.assertIn("kevin-maintenance-runner-v1.3.5", str(manifest.get("source_path")))

    def test_live_workitem_unblocked_histories_preserved(self) -> None:
        items = json.loads((ROOT / "inbox" / "autonomy" / "work-items.json").read_text(encoding="utf-8"))
        item = next(x for x in items["items"] if x["id"] == "owner-west-motor-parts-chase-fresh-8-v1")
        self.assertFalse(item.get("blocked"))
        self.assertEqual(item.get("required_skill_key"), "west-motor-parts-chase-board-pack@1")
        self.assertEqual(item.get("status"), "OPEN")
        self.assertEqual(item.get("authority_class"), "GREEN")
        self.assertIn("west-motor-parts-chase-board-pack@1", str(item.get("next_action")))


if __name__ == "__main__":
    unittest.main()
