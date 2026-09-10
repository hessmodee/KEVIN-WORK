#!/usr/bin/env python3
"""Static contract for Maintenance v1.3.55 invocation worker v1.1 promotion."""

from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.55.ps1"
PARENT = ROOT / "control-plane" / "maintenance" / "kevin-maintenance-runner-v1.3.53.ps1"
SUPERVISOR = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.12.ps1"
WORKER = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"
WORKER_V11 = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invoke-worker-v1.1.ps1"

PARENT_SHA = "EF32D990488F1B44C2122032DD5CB21DD15C97F9C851AEDF0657C193335C5C50"
RUNNER_SHA = "3E11C429D4540DBD5C4F6F7AD60AA1729D2C0A78D7DA209E76F196654589C261"
SUPERVISOR_AFTER = "F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB"
WORKER_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"
WORKER_V11_SHA = "7E1129B7FE2B21C90EED634B7A1A356B55630B56DD700A15A7A8C307AEB827AE"

PARENT_OPS = [
    "replace_pinned_component",
    "restart_ui_bridge",
    "install_autonomy_controller_v1810",
    "install_autonomy_controller_v1811",
    "install_autonomy_controller_v1812",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class MaintenanceV1355ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = RUNNER.read_text(encoding="utf-8")
        cls.raw = RUNNER.read_bytes()

    def test_lf_only_identity(self) -> None:
        self.assertNotIn(b"\r", self.raw, "runner must be LF so Windows Get-FileHash matches Git blob")
        self.assertTrue(self.raw.startswith(b"param("))
        self.assertEqual(sha256(RUNNER), RUNNER_SHA)

    def test_parent_pin_and_github_worker_pin_unchanged(self) -> None:
        self.assertEqual(sha256(PARENT), PARENT_SHA)
        self.assertEqual(sha256(SUPERVISOR), SUPERVISOR_AFTER)
        self.assertEqual(sha256(WORKER), WORKER_SHA)
        self.assertEqual(sha256(WORKER_V11), WORKER_V11_SHA)
        for pin in (PARENT_SHA, SUPERVISOR_AFTER, WORKER_SHA, WORKER_V11_SHA):
            self.assertIn(pin, self.text)
        self.assertIn("control-plane/maintenance/kevin-maintenance-runner-v1.3.53.ps1", self.text)
        self.assertIn("control-plane/autonomy/kevin-proven-skill-invoke-worker-v1.1.ps1", self.text)
        self.assertIn("ControlPlane/kevin-proven-skill-invoke-worker-v1.ps1", self.text)

    def test_selftest_marker_and_worker_v11_allowlist(self) -> None:
        self.assertIn("KEVIN MAINTENANCE v1.3.3 SELFTEST PASS", self.text)
        self.assertIn("compatibility=v1.3.55", self.text)
        self.assertIn("parent=v1.3.53_exact", self.text)
        self.assertIn("worker_v11=promotable", self.text)
        self.assertIn("receipt_idempotent=strict_safe", self.text)
        self.assertIn("supervisor_untouched=true", self.text)
        self.assertIn("install_invocation_worker_v11", self.text)
        self.assertIn("Install-InvocationWorkerV11", self.text)
        self.assertIn("function Get-InstallStatus", self.text)
        self.assertIn("idempotent=$false", self.text)
        self.assertIn("$status=Get-InstallStatus $result", self.text)
        self.assertNotIn("$status=if([bool]$result.idempotent)", self.text)
        self.assertIn("strict mode did not catch missing idempotent", self.text)
        self.assertIn("changed receipt status mismatch", self.text)
        self.assertIn("replay receipt status mismatch", self.text)
        self.assertNotIn("Install-AutonomyControllerV1812", self.text)
        self.assertNotIn("Get-RemoteV1812Bytes", self.text)
        self.assertIn("do not recopy", self.text)
        self.assertIn("Get-RemoteWorkerV11Bytes", self.text)

    def test_first_apply_return_includes_idempotent(self) -> None:
        self.assertRegex(
            self.text,
            r"return \[ordered\]@\{changed=\$true;idempotent=\$false;",
        )
        self.assertIn("changed=$false;idempotent=$true", self.text)

    def test_parent_ops_preserved(self) -> None:
        for op in PARENT_OPS:
            self.assertIn("'" + op + "'", self.text, op)
        self.assertIn("'install_invocation_worker_v11'", self.text)

    def test_no_forbidden_execution_surface(self) -> None:
        for pattern in (
            r"(?im)^\s*Invoke-Expression\b",
            r"(?im)^\s*kevin_shell\b",
            r"(?im)^\s*Start-Process\s+cmd\.exe\b",
        ):
            self.assertIsNone(re.search(pattern, self.text), pattern)
        self.assertNotIn("run_powershell", self.text)
        self.assertNotIn("execute_command", self.text)

    def test_does_not_mutate_live_manifest_slot(self) -> None:
        self.assertIn("inbox/maintenance/manifest.json", self.text)
        self.assertNotIn("Set-Content", self.text)
        self.assertIn("parent_invoked=$false", self.text)
        self.assertIn("execution_attempted=$false", self.text)

    def test_fail_closed_fetch_allowlist(self) -> None:
        self.assertIn("invocation worker v1.1 source path rejected", self.text)
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

    def test_live_manifest_is_v1355_replace_pinned_component(self) -> None:
        manifest = json.loads((ROOT / "inbox" / "maintenance" / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest.get("operation"), "replace_pinned_component")
        self.assertEqual(manifest.get("id"), "grok-install-maint-v1355-20260909-1850")
        self.assertEqual(manifest.get("target_alias"), "maintenance_runner")
        self.assertEqual(manifest.get("source_path"), "control-plane/maintenance/kevin-maintenance-runner-v1.3.55.ps1")
        self.assertEqual(manifest.get("source_sha256"), RUNNER_SHA)
        self.assertEqual(manifest.get("expected_current_sha256"), PARENT_SHA)
        self.assertEqual(manifest.get("expected_after_sha256"), RUNNER_SHA)
        self.assertEqual(manifest.get("expires_at"), "2026-09-10T22:00:00Z")
        self.assertNotEqual(manifest.get("operation"), "install_invocation_worker_v11")
        self.assertNotEqual(manifest.get("operation"), "install_autonomy_controller_v1812")
        allowed = {
            "schema",
            "kind",
            "id",
            "authority_class",
            "authority_delta",
            "production_effect",
            "owner_policy",
            "preauthorized",
            "operation",
            "target_alias",
            "source_path",
            "source_sha256",
            "expected_current_sha256",
            "expected_after_sha256",
            "expires_at",
        }
        self.assertEqual(set(manifest.keys()), allowed)
        self.assertEqual(manifest.get("schema"), 3)
        self.assertEqual(manifest.get("kind"), "kevin-self-maintenance-manifest")
        self.assertEqual(manifest.get("authority_class"), "GREEN")
        self.assertEqual(manifest.get("authority_delta"), "NONE")
        self.assertEqual(manifest.get("production_effect"), "NONE")
        self.assertTrue(manifest.get("preauthorized"))
        self.assertNotIn("notes", manifest)

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
