#!/usr/bin/env python3
"""HQ stable shell: one ops painter, no height loop, no 1s X-eyes overlay, in-place V10 paint."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
embed = (root / "docs/ops/embed.html").read_text()
ops = (root / "docs/ops/ops-v11.js").read_text()
console = (root / "docs/hq-owner-console-v10.js").read_text()
index = (root / "docs/index.html").read_text()
sw = (root / "docs/sw.js").read_text()

live_embed = re.sub(r"<!--.*?-->", "", embed, flags=re.S)
active_scripts = re.findall(r'<script src="([^"]+)"', live_embed)
assert active_scripts == ["./ops-v11.js?v=22"], f"embed must load only ops-v11, got {active_scripts}"
assert "ResizeObserver" not in live_embed
assert "kevin-ops-height" not in live_embed
assert "addEventListener('resize',()=>load())" not in ops
assert "function paintWorkers" in ops
assert "lastKmode" in ops
assert "fresh(cache.dashboard,900)" in console
assert "existing.length===TABS.length" in console
assert "htmlFor" in console
assert "v10Chart" in console
assert 'src="./hq-core-v7.html?v=21#overview"' in index
assert "sw.js?v=10" in index
assert "kevin-hq-shell-v9" in sw
assert "ops-live-truth-v2.js" not in sw
assert "ops-truth-patch-v1.js" not in sw
print("HQ STABLE SHELL SOURCE CONTRACT PASS")
