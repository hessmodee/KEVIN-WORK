#!/usr/bin/env python3
"""Source contract: HQ has one painter when V10 owns the document."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
core = (root / "docs/hq-core-v7.html").read_text()
console = (root / "docs/hq-owner-console-v10.js").read_text()
index = (root / "docs/index.html").read_text()
sw = (root / "docs/sw.js").read_text()

assert "stopAutonomousPaint" in core, "V7 must expose stopAutonomousPaint"
assert "coreOwnedByV10" in core, "V7 must detect V10 parent"
assert "window.__kevinOwnerConsoleV10" in console, "V10 must claim exclusive ownership"
assert "if(installed&&doc===installedDoc)return" in console.replace(" ", ""), "V10 install must be idempotent"
assert "opsV10Frame" in console and "replaceWith" in console, "V10 ops must update in place"
assert "window.__kevinOwnerConsoleV10={version:10,exclusive:true,pending:true}" in index.replace(" ", ""), "parent must claim V10 before iframe"
assert 'src="./hq-core-v7.html?v=19#overview"' in index, "core iframe must boot overview under V10"
assert "kevin-hq-shell-v8" in sw, "service worker cache must bump"
assert "hq-truth-v2.js" not in sw, "retired V8 painters must not be precached"
print("HQ SINGLE-PAINTER SOURCE CONTRACT PASS")
