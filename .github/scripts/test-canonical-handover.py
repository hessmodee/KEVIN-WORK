#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
md = (ROOT / "AI-HANDOVER.md").read_text(encoding="utf-8-sig")
data = json.loads((ROOT / "reports" / "handoff-latest.json").read_text(encoding="utf-8-sig"))

required_md = [
    "THIS IS THE ONE CURRENT HANDOVER FOR KEVIN",
    "Local-only work is unfinished work.",
    "Cross-AI local-work convergence contract",
    "reports/support-latest.json",
    "reports/engineering/latest.json",
    "DESIGNED -> CI-PROVEN",
    "T0 BESS-DEPENDENT",
]
for marker in required_md:
    assert marker in md, f"missing canonical handover marker: {marker}"

assert data["schema"] == 3
assert data["kind"] == "kevin-canonical-handover-machine-twin"
assert data["canonical_human_authority"] == "AI-HANDOVER.md"
assert data["cross_ai_rule"]["one_handover"] is True
assert data["cross_ai_rule"]["durable_local_work_must_be_published"] is True
assert data["cross_ai_rule"]["local_only_changes_are_not_complete"] is True
assert data["privacy"]["secrets_allowed"] is False
assert data["privacy"]["private_message_bodies_allowed"] is False
for key in ("github", "raw", "hq"):
    assert data["universal_access"][key].startswith("https://")

print("CANONICAL_HANDOVER_TEST_PASS schema=3 one_handover=true local_only_complete=false")
