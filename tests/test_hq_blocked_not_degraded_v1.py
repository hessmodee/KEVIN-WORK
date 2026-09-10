#!/usr/bin/env python3
"""HQ ops-v11 must paint invocation fail-closed as BLOCKED, not DEGRADED."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPS = ROOT / "docs" / "ops" / "ops-v11.js"
CSS = ROOT / "docs" / "ops" / "ops-v11.css"
CONSOLE = ROOT / "docs" / "hq-owner-console-v10.js"


class HqBlockedNotDegradedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.ops = OPS.read_text(encoding="utf-8")
        cls.css = CSS.read_text(encoding="utf-8")
        cls.console = CONSOLE.read_text(encoding="utf-8")

    def test_ops_maps_invocation_block_to_blocked(self) -> None:
        self.assertIn("if(cont==='BLOCKED_INVOCATION_RUNTIME')return ['blocked'];", self.ops)
        self.assertNotIn("if(cont==='CONTROLLER_ERROR'||cont==='BLOCKED_INVOCATION_RUNTIME')return ['degraded'];", self.ops)
        self.assertIn("if(cont==='CONTROLLER_ERROR')return ['degraded'];", self.ops)
        self.assertIn("blocked:'BLOCKED'", self.ops)
        self.assertIn("blocked:'#f0c36a'", self.ops)
        self.assertIn("ks==='blocked'?'blocked'", self.ops)

    def test_owner_console_already_blocked(self) -> None:
        self.assertIn("if(cont==='BLOCKED_INVOCATION_RUNTIME')return{mode:'blocked'", self.console)

    def test_css_has_blocked_token(self) -> None:
        self.assertIn("--blocked:#f0c36a", self.css)
        self.assertIn(".kevin-avatar-prod.mode-blocked", self.css)


if __name__ == "__main__":
    unittest.main()
