#!/usr/bin/env python3
"""HQ must paint invocation fail-closed as BLOCKED, not DEGRADED."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPS = ROOT / "docs" / "ops" / "ops-v11.js"
EMBED = ROOT / "docs" / "ops" / "embed.html"
CONSOLE = ROOT / "docs" / "hq-owner-console-v10.js"
WORKFLOW = ROOT / ".github" / "workflows" / "hq-owner-refinement-v1.yml"
INDEX = ROOT / "docs" / "index.html"


class HqBlockedNotDegradedTests(unittest.TestCase):
    def test_ops_v11_maps_invocation_block(self) -> None:
        ops = OPS.read_text(encoding="utf-8")
        self.assertIn("if(cont==='BLOCKED_INVOCATION_RUNTIME')return ['blocked'];", ops)
        self.assertNotIn("cont==='CONTROLLER_ERROR'||cont==='BLOCKED_INVOCATION_RUNTIME'", ops)
        self.assertIn("blocked:'#f0c36a'", ops)
        self.assertIn("blocked:'BLOCKED'", ops)

    def test_embed_legend_has_blocked(self) -> None:
        embed = EMBED.read_text(encoding="utf-8")
        self.assertIn("BLOCKED", embed)
        self.assertIn("<script src=\"./ops-v11.js", embed)
        self.assertGreater(len(embed), 2000)

    def test_owner_console_already_blocked(self) -> None:
        console = CONSOLE.read_text(encoding="utf-8")
        self.assertIn("if(cont==='BLOCKED_INVOCATION_RUNTIME')return{mode:'blocked'", console)

    def test_ci_matches_live_v10_shell(self) -> None:
        wf = WORKFLOW.read_text(encoding="utf-8")
        idx = INDEX.read_text(encoding="utf-8")
        self.assertIn("hq-evidence-adapter-v1.js", wf)
        self.assertIn("hq-owner-console-v10.js", wf)
        self.assertIn("hq-evidence-adapter-v1.js", idx)
        self.assertIn("hq-owner-console-v10.js", idx)
        self.assertIn("assert 'hq-owner-console-v10.js' in sw", wf)

    def test_tools_chip_stale_canary_is_not_kevin_dead(self) -> None:
        console = CONSOLE.read_text(encoding="utf-8")
        self.assertIn("function toolsChip()", console)
        self.assertIn("5 · CANARY STALE", console)
        self.assertIn("?v=7", INDEX.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
