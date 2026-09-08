#!/usr/bin/env python3
"""Static contract for Supervisor v1.8.12 worker-native fail-closed wrap."""

from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
V1811 = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.11.ps1"
V1812 = ROOT / "control-plane" / "autonomy" / "kevin-supervisor-v1.8.12.ps1"
WORKER = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"

V1811_SHA = "685B34F31B797915B6ADC6058FCCDF4AEACD3CDD49D6B084FB31800FA966AB79"
V1812_SHA = "F17F4B0AA151CAFC889D299C283EDF4A55DC395734BD1A9B4D3155D5843DECBB"
WORKER_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"
SELECTOR_SHA = "52EADBCA27070F3FF845ADF1E989F7E570AECC25D2C3F11EF7E0FF80DA000C6A"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class SupervisorV1812ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = V1812.read_text(encoding="utf-8")
        cls.raw = V1812.read_bytes()
        cls.parent = V1811.read_text(encoding="utf-8")

    def test_lf_only_identity(self) -> None:
        self.assertNotIn(b"\r", self.raw)
        self.assertTrue(self.raw.startswith(b"param("))
        self.assertEqual(sha256(V1812), V1812_SHA)
        self.assertEqual(sha256(V1811), V1811_SHA)
        self.assertEqual(sha256(WORKER), WORKER_SHA)

    def test_version_and_selftest_markers(self) -> None:
        self.assertIn("Kevin Supervisor v1.8.12", self.text)
        self.assertIn("version = '1.8.12'", self.text)
        self.assertIn("version='1.8.12'", self.text)
        self.assertIn("KEVIN SUPERVISOR v1.8.12 SELFTEST PASS", self.text)
        self.assertIn("invocation_worker_native_error_fail_closed=true", self.text)
        self.assertIn("proven_skill_before_skill_lab=true", self.text)
        self.assertIn("invocation_not_main=true", self.text)
        self.assertIn(SELECTOR_SHA, self.text)
        self.assertNotIn("version = '1.8.11'", self.text)
        self.assertNotIn("version='1.8.11'", self.text)

    def test_worker_invoke_is_continue_wrapped(self) -> None:
        start = self.text.index("$workerArgs = @(")
        end = self.text.index("Save-Latest 'ROUTED_TO_PROVEN_SKILL_INVOCATION'", start)
        block = self.text[start:end]
        self.assertIn("$ErrorActionPreference = 'Continue'", block)
        self.assertIn("Save-Latest 'BLOCKED_INVOCATION_RUNTIME'", block)
        self.assertIn("reason='INVOCATION_WORKER_FAILED'", block)
        self.assertIn("turn_charged=$false", block)
        self.assertIn("return", block)
        self.assertNotIn("throw", block)
        # Unwrapped native invoke from v1.8.11 must not remain.
        self.assertNotIn("$workerOut = & powershell @workerArgs 2>&1\n            $workerCode = [int]$LASTEXITCODE", block)

    def test_parent_v1811_still_unwrapped(self) -> None:
        self.assertIn("$workerOut = & powershell @workerArgs 2>&1", self.parent)
        self.assertNotIn("invocation_worker_native_error_fail_closed=true", self.parent)

    def test_controller_error_still_fail_closed_for_unexpected(self) -> None:
        self.assertIn("Save-Latest 'CONTROLLER_ERROR'", self.text)
        self.assertIn("ROUTED_TO_PROVEN_SKILL_INVOCATION", self.text)
        self.assertIn("BLOCKED_INVOCATION_RUNTIME", self.text)
        self.assertIn("west-motor-parts-chase-board-pack@1" if False else "required_skill_key", self.text)

    def test_no_forbidden_execution_surface(self) -> None:
        for pattern in (
            r"(?im)^\s*Invoke-Expression\b",
            r"(?im)^\s*kevin_shell\b",
            r"(?im)^\s*Start-Process\s+cmd\.exe\b",
        ):
            self.assertIsNone(re.search(pattern, self.text), pattern)
        self.assertIn("never calls fixed:main", self.text)
        self.assertNotIn("Invoke-Expression", self.text)

    def test_does_not_widen_worker_allowlist(self) -> None:
        worker = WORKER.read_text(encoding="utf-8")
        self.assertIn("west-motor-parts-chase-board-pack@1", worker)
        self.assertIn("SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE", worker)


if __name__ == "__main__":
    unittest.main()
