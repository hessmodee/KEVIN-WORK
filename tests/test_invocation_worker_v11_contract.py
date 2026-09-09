#!/usr/bin/env python3
"""Static contract for proven-skill invoke worker v1.1 wrap (source only)."""

from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKER_V11 = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invoke-worker-v1.1.ps1"
WORKER_V1 = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"
STUB = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invoke-worker-v1.ps1"

WORKER_V11_SHA = "7E1129B7FE2B21C90EED634B7A1A356B55630B56DD700A15A7A8C307AEB827AE"
WORKER_V1_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class InvocationWorkerV11ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = WORKER_V11.read_text(encoding="utf-8")
        cls.raw = WORKER_V11.read_bytes()
        cls.live = WORKER_V1.read_text(encoding="utf-8")
        cls.live_raw = WORKER_V1.read_bytes()

    def test_lf_only_identities(self) -> None:
        self.assertNotIn(b"\r", self.raw)
        self.assertNotIn(b"\r", self.live_raw)
        self.assertTrue(self.raw.startswith(b"param("))
        self.assertEqual(sha256(WORKER_V11), WORKER_V11_SHA)
        self.assertEqual(sha256(WORKER_V1), WORKER_V1_SHA)
        self.assertNotEqual(WORKER_V11_SHA, WORKER_V1_SHA)

    def test_continue_wrap_not_native_stop(self) -> None:
        self.assertIn("Kevin Proven Skill Invoke Worker v1.1", self.text)
        self.assertIn("$ErrorActionPreference = 'Continue'", self.text)
        self.assertIn("function Invoke-HiddenPython", self.text)
        self.assertIn("CreateNoWindow = $true", self.text)
        self.assertIn("NativeCommandError", self.text)
        self.assertIn("version = '1.1.0'", self.text)
        self.assertRegex(self.text, r"(?m)^\$ErrorActionPreference = 'Continue'")
        self.assertIsNone(re.search(r"(?m)^\$ErrorActionPreference = 'Stop'", self.text))
        self.assertIn("$ErrorActionPreference = 'Stop'", self.live)
        self.assertNotIn("Invoke-HiddenPython", self.live)

    def test_exact_five_skill_allowlist_unchanged(self) -> None:
        self.assertIn("west-motor-parts-chase-board-pack@1", self.text)
        self.assertIn("SKILL_KEY_NOT_INVOCATION_V1_COMPATIBLE", self.text)
        self.assertIn("outcome_proven = $false", self.text)
        self.assertIn("authority = 'GREEN'", self.text)
        self.assertNotIn("run_powershell", self.text)
        self.assertNotIn("Invoke-Expression", self.text)
        self.assertNotIn("kevin_shell", self.text)
        self.assertNotRegex(self.text, r"west-motor-parts-chase-board-pack@2")

    def test_github_controlplane_pin_not_promoted_in_source(self) -> None:
        self.assertIn("$ErrorActionPreference = 'Stop'", self.live)
        self.assertNotIn("CreateNoWindow", self.live)
        self.assertIn("west-motor-parts-chase-board-pack@1", self.live)
        self.assertTrue(STUB.exists())


if __name__ == "__main__":
    unittest.main()
