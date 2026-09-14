#!/usr/bin/env python3
"""Source contract: HQ cycle authority is hq-live-floor.json, never support.supervisor.cycle."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
docs = root / "docs"
fails = []

def read(p):
    return p.read_text(encoding="utf-8", errors="replace")

painter = read(docs / "hq-p0-floor-painter-v1.js")
if "atob(" in painter and "b64." in painter and len(painter) < 2000:
    fails.append("floor painter is still the b64 loader")
if "reports/hq-live-floor.json" not in painter:
    fails.append("floor painter does not fetch hq-live-floor.json")
if "support.supervisor.cycle" not in painter:
    fails.append("floor painter must explicitly ban support.supervisor.cycle")

v10 = read(docs / "hq-owner-console-v10.js")
if "reports/hq-live-floor.json" not in v10:
    fails.append("V10 PATHS missing hq-live-floor.json")
if "function floorCycle(" not in v10:
    fails.append("V10 missing floorCycle()")
if "function floorBleed(" not in v10:
    fails.append("V10 missing floorBleed()")

index = read(docs / "index.html")
if "hq-p0-floor-painter-v1.js" not in index:
    fails.append("index.html does not load floor painter")
if "sw.js?v=17" not in index:
    fails.append("index.html must register sw.js?v=17")

sw = read(docs / "sw.js")
if "kevin-hq-shell-v17" not in sw:
    fails.append("sw.js VERSION is not v17")
if "hq-p0-floor-painter-v1.b64." in sw:
    fails.append("sw.js still precaches b64 painter chunks")

pub = read(root / "tools" / "Publish-Kevin-HqLiveFloor-v1.ps1")
if "invoke-owner-*.json" not in pub:
    fails.append("Publish-Kevin-HqLiveFloor does not scan invoke-owner-* done receipts")
if "$lastDone = if ($transportAt)" in pub:
    fails.append("Publish-Kevin-HqLiveFloor still freezes lastDone on transport")

contract = read(docs / "HQ-TRUTH-CONTRACT.md")
if "hq-live-floor.json" not in contract:
    fails.append("HQ-TRUTH-CONTRACT missing hq-live-floor.json as one clock")

if fails:
    print("FAIL")
    for f in fails:
        print(" -", f)
    sys.exit(1)
print("PASS hq-one-clock-v1")
