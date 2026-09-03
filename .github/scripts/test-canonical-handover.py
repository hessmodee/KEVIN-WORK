#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HANDOVER = ROOT / "AI-HANDOVER.md"
TWIN = ROOT / "reports" / "handoff-latest.json"
BUILDER = ROOT / ".github" / "scripts" / "build-canonical-handover.py"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


md = HANDOVER.read_text(encoding="utf-8-sig")
data = json.loads(TWIN.read_text(encoding="utf-8-sig"))

required_md = [
    "THIS IS THE ONE CURRENT HANDOVER FOR KEVIN",
    "Local-only work is unfinished work.",
    "Cross-AI local-work convergence contract",
    "reports/support-latest.json",
    "reports/engineering/latest.json",
    "DESIGNED -> CI-PROVEN",
    "T0 BESS-DEPENDENT",
    "Heartbeat timestamps alone do not move `main`",
]
for marker in required_md:
    assert marker in md, f"missing canonical handover marker: {marker}"

assert data["schema"] == 4
assert data["kind"] == "kevin-canonical-handover-machine-twin"
assert data["canonical_human_authority"] == "AI-HANDOVER.md"
assert data["cross_ai_rule"]["one_handover"] is True
assert data["cross_ai_rule"]["durable_local_work_must_be_published"] is True
assert data["cross_ai_rule"]["local_only_changes_are_not_complete"] is True
assert data["cross_ai_rule"]["semantic_no_churn"] is True
assert isinstance(data["semantic_fingerprint_sha256"], str)
assert len(data["semantic_fingerprint_sha256"]) == 64
assert data["privacy"]["secrets_allowed"] is False
assert data["privacy"]["private_message_bodies_allowed"] is False
for key in ("github", "raw", "hq"):
    assert data["universal_access"][key].startswith("https://")

# A second build against unchanged semantic state must preserve the canonical
# checkpoint byte-for-byte. This protects active branches from telemetry-only
# repository churn.
before = (digest(HANDOVER), digest(TWIN))
subprocess.run(["python", str(BUILDER)], cwd=ROOT, check=True)
after = (digest(HANDOVER), digest(TWIN))
assert before == after, "canonical builder churned unchanged semantic checkpoint"

print("CANONICAL_HANDOVER_TEST_PASS schema=4 semantic_no_churn=true one_handover=true")
