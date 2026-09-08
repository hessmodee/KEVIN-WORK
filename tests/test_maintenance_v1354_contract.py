#!/usr/bin/env python3
"""Static contract for Maintenance v1.3.54 StrictMode idempotent receipt."""

from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.54.ps1"
PARENT = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.53.ps1"
SUPERVISOR = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.12.ps1"
WORKER = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"

PARENT_SHA = "EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50"
RUNNER_SHA = "CD035301E8711E18E4AB03A3556F1197CCF0AB20E109287EDBBDBF277BD5CAE7"
SUPERVISOR_AFTER = "F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB"
WORKER_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"

PARENT_OPS = [
    "replace_pinned_component",
    "restart_ui_bridge",
    "install_autonomy_controller_v1810",
    "install_autonomy_controller_v1811",
    "install_autonomy_controller_v1812",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class MaintenanceV1354ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = RUNNER.read_text(encoding="utf-8")
        cls.raw = RUNNER.read_bytes()

    def test_lf_only_identity(self) -> None:
        self.assertNotIn(b"\r", self.raw, "runner must be LF so Windows Get-FileHash matches Git blob")
        self.assertTrue(self.raw.startswith(b"param("))
        self.assertEqual(sha256(RUNNER), RUNNER_SHA)

    def test_parent_pin_and_no_identity_drift(self) -> None:
        self.assertEqual(sha256(PARENT), PARENT_SHA)
        self.assertEqual(sha256(SUPERVISOR), SUPERVISOR_AFTER)
        self.assertEqual(sha256(WORKER), WORKER_SHA)
        self.assertIn(PARENT_SHA, self.text)
        self.assertIn(SUPERVISOR_AFTER, self.text)
        self.assertIn(WORKER_SHA, self.text)
        self.assertIn("control-plane/maintenance/kevin-maintenance-runner-v1.3.53.ps1", self.text)

    def test_selftest_marker_and_strict_receipt(self) -> None:
        self.assertIn("KEVIN MAINTENANCE v1.3.3 SELFTEST PASS", self.text)
        self.assertIn("compatibility=v1.3.54", self.text)
        self.assertIn("receipt_idempotent=strict_safe", self.text)
        self.assertIn("parent=v1.3.53_exact", self.text)
        self.assertIn("function Get-InstallStatus", self.text)
        self.assertIn("idempotent=$false", self.text)
        self.assertIn("$status=Get-InstallStatus $result", self.text)
        self.assertNotIn("$status=if([bool]$result.idempotent)", self.text)
        self.assertIn("strict mode did not catch missing idempotent", self.text)
        self.assertIn("changed receipt status mismatch", self.text)
        self.assertIn("replay receipt status mismatch", self.text)

    def test_first_apply_return_includes_idempotent(self) -> None:
        self.assertRegex(
            self.text,
            r"return \[ordered\]@\{changed=\$true;idempotent=\$false;",
        )
        self.assertIn("changed=$false;idempotent=$true", self.text)

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

    def test_does_not_widen_worker_or_invent_relay(self) -> None:
        self.assertIn("west-motor-parts-chase-board-pack@1", self.text)
        self.assertNotIn("run_powershell", self.text)
        self.assertNotIn("execute_command", self.text)
        self.assertIn("history_preserved=$true", self.text)
        self.assertIn("work_items_preserved=$true", self.text)
        self.assertIn("mission_leases_preserved=$true", self.text)

    def test_live_workitem_unblocked_histories_preserved(self) -> None:
        items = json.loads((ROOT / "inbox" / "autonomy" / "work-items.json").read_text(encoding="utf-8"))
        item = next(x for x in items["items"] if x["id"] == "owner-west-motor-parts-chase-fresh-8-v1")
        self.assertFalse(item.get("blocked"))
        self.assertEqual(item.get("required_skill_key"), "west-motor-parts-chase-board-pack@1")
        self.assertEqual(item.get("status"), "OPEN")
        self.assertEqual(item.get("authority_class"), "GREEN")


if __name__ == "__main__":
    unittest.main()
