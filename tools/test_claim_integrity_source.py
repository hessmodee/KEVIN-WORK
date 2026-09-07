#!/usr/bin/env python3
"""Fail-closed source proof for Kevin main-chat execution truth doctrine."""
from __future__ import annotations
import hashlib, json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parents[1]
POLICY = ["AGENTS.md", "HEARTBEAT.md", "MEMORY.md", "SOUL.md", "TOOLS.md"]
EXACT5 = [
    "kevin_system_status",
    "kevin_desktop_find_folder",
    "kevin_desktop_open_folder",
    "kevin_desktop_list_folder",
    "kevin_app_launch",
]

def fail(message: str) -> None:
    raise SystemExit(f"KEVIN CLAIM INTEGRITY SOURCE PROOF FAIL: {message}")

def read(rel: str) -> str:
    p = ROOT / rel
    if not p.is_file():
        fail(f"missing {rel}")
    return p.read_text(encoding="utf-8-sig")

def sha256(rel: str) -> str:
    return hashlib.sha256((ROOT / rel).read_bytes()).hexdigest().upper()

lesson = read("docs/engineering/LESSON-main-chat-side-effect-claims-require-receipts-2026-09-07.md")
neg_path = ROOT / "docs/engineering/evals/NEG-side-effect-claim-without-receipt-v1.json"
try:
    neg = json.loads(neg_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"negative eval JSON invalid: {exc}")

for marker in (
    "PLAN / SAY / DISPLAY is not EXECUTE",
    "Persistent-artifact rule",
    "App-launch rule",
    "Durable-memory rule",
    "NOT_EXECUTED: capability_unavailable",
    "ATTEMPTED_UNVERIFIED",
    "Missing capability is a reason to learn and build",
):
    if marker not in lesson:
        fail(f"lesson missing marker: {marker}")

if neg.get("id") != "NEG-side-effect-claim-without-receipt-v1":
    fail("negative eval id mismatch")
if neg.get("scenario", {}).get("visible_tools") != EXACT5:
    fail("negative eval visible tool inventory is not exact-five")
required = "\n".join(neg.get("required_behavior", []))
for marker in ("NOT_EXECUTED: capability_unavailable", "ATTEMPTED_UNVERIFIED", "kevin_app_launch"):
    if marker not in required:
        fail(f"negative eval missing required behavior marker: {marker}")

for rel in ("workspace/AGENTS.md", "workspace/SOUL.md"):
    text = read(rel)
    if "Execution integrity — highest priority" in text:
        for marker in ("NOT_EXECUTED: capability_unavailable", "ATTEMPTED_UNVERIFIED", "kevin_app_launch", "same-turn"):
            if marker not in text:
                fail(f"{rel} partial execution-integrity block missing {marker}")

tools = read("workspace/TOOLS.md")
section = re.search(r"## fixed:main live inventory.*?\n(?P<body>.*?)(?:\n## |\Z)", tools, re.I|re.S)
if not section:
    fail("TOOLS.md fixed:main inventory section missing")
listed = re.findall(r"(?m)^- `([A-Za-z0-9_-]+)`", section.group("body"))
if listed != EXACT5:
    fail(f"fixed:main inventory must remain exact-five, got {listed!r}")

policy_hashes = {name: sha256(f"workspace/{name}") for name in POLICY}
print("KEVIN_POLICY_SHA256 " + json.dumps(policy_hashes, sort_keys=True, separators=(",", ":")))
print("KEVIN CLAIM INTEGRITY SOURCE PROOF PASS exact5=true lesson=true negative_eval=true fail_closed=true policy_hashes=true")
