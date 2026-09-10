#!/usr/bin/env python3
"""HQ must paint invocation fail-closed as BLOCKED, not DEGRADED."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPS = ROOT / "docs" / "ops" / "ops-v11.js"
OVERLAY = ROOT / "docs" / "ops" / "ops-blocked-truth-v1.js"
EMBED = ROOT / "docs" / "ops" / "embed.html"
CONSOLE = ROOT / "docs" / "hq-owner-console-v10.js"


class HqBlockedNotDegradedTests(unittest.TestCase):
    def test_overlay_maps_invocation_block(self) -> None:
        overlay = OVERLAY.read_text(encoding="utf-8")
        embed = EMBED.read_text(encoding="utf-8")
        self.assertIn("BLOCKED_INVOCATION_RUNTIME", overlay)
        self.assertIn("return ['blocked']", overlay)
        self.assertIn("ops-blocked-truth-v1.js", embed)
        self.assertIn("BLOCKED", embed)
        self.assertIn("<script src=\"./ops-v11.js", embed)
        self.assertGreater(len(embed), 2000)

    def test_owner_console_already_blocked(self) -> None:
        console = CONSOLE.read_text(encoding="utf-8")
        self.assertIn("if(cont==='BLOCKED_INVOCATION_RUNTIME')return{mode:'blocked'", console)

    def test_ops_v11_still_present(self) -> None:
        ops = OPS.read_text(encoding="utf-8")
        self.assertIn("function kevinStates", ops)


if __name__ == "__main__":
    unittest.main()
