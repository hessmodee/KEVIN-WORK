#!/usr/bin/env python3
"""Fail-closed source proof for Kevin main-chat execution truth doctrine."""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
POLICY_FILES = [
    "AGENTS.md",
    "HEARTBEAT.md",
    "MEMORY.md",
    "SOUL.md",
    "TOOLS.md",
]
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


agents = read("workspace/AGENTS.md")
soul = read("workspace/SOUL.md")
tools = read("workspace/TOOLS.md")
lesson = read("docs/engineering/LESSON-main-chat-side-effect-claims-require-receipts-2026-09-07.md")

eval_path = ROOT / "docs/engineering/evals/NEG-side-effect-claim-without-receipt-v1.json"
try:
    neg = json.loads(eval_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"negative eval JSON invalid: {exc}")

for name, text, marker in (
    ("AGENTS.md", agents, "Execution integrity — highest priority"),
    ("SOUL.md", soul, "Execution integrity — highest priority"),
):
    for required in (
        marker,
        "NOT_EXECUTED: capability_unavailable",
        "ATTEMPTED_UNVERIFIED",
        "kevin_app_launch",
        "same-turn",
    ):
        if required not in text:
            fail(f"{name} missing required truth marker: {required}")

# Compatibility markers required by the installed typed runtime-policy validator.
if "Standing Order 1" not in agents:
    fail("AGENTS.md lost Maintenance compatibility marker Standing Order 1")
if "Chief of Staff" not in soul:
    fail("SOUL.md lost Maintenance compatibility marker Chief of Staff")
if "typed" not in tools:
    fail("TOOLS.md lost Maintenance compatibility marker typed")

if "## Execution truth boundary" not in tools:
    fail("TOOLS.md missing execution truth boundary")
if "**Not in fixed:main exact-5:**" not in tools:
    fail("TOOLS.md missing explicit absent-capability boundary")

# Parse only the fixed:main inventory section and require the exact five names, no more/no fewer.
match = re.search(
    r"## fixed:main live inventory.*?\n(?P<body>.*?)(?:\n## |\Z)",
    tools,
    flags=re.IGNORECASE | re.DOTALL,
)
if not match:
    fail("TOOLS.md fixed:main inventory section missing")
body = match.group("body")
listed = re.findall(r"(?m)^- `([A-Za-z0-9_-]+)`", body)
if listed != EXACT5:
    fail(f"fixed:main inventory must be exact-five in canonical order, got {listed!r}")

for forbidden_live in (
    "kevin_app_close",
    "kevin_ui_click",
    "kevin_ui_type",
    "kevin_file_write",
    "kevin_shell",
):
    if re.search(rf"(?m)^- `{re.escape(forbidden_live)}`", body):
        fail(f"forbidden/unproven capability listed live: {forbidden_live}")

if neg.get("id") != "NEG-side-effect-claim-without-receipt-v1":
    fail("negative eval id mismatch")
if neg.get("scenario", {}).get("visible_tools") != EXACT5:
    fail("negative eval visible tool inventory is not exact-five")
required_behavior = "\n".join(neg.get("required_behavior", []))
for marker in (
    "NOT_EXECUTED: capability_unavailable",
    "ATTEMPTED_UNVERIFIED",
    "kevin_app_launch",
):
    if marker not in required_behavior:
        fail(f"negative eval missing required behavior marker {marker}")

for marker in (
    "PLAN / SAY / DISPLAY",
    "Persistent-artifact rule",
    "App-launch rule",
    "Durable-memory rule",
    "Missing capability is a reason to learn and build",
):
    if marker not in lesson:
        fail(f"lesson missing marker: {marker}")

hashes = {
    name: sha256(f"workspace/{name}")
    for name in POLICY_FILES
}
print(json.dumps({"policy_sha256": hashes}, sort_keys=True))
print("KEVIN CLAIM INTEGRITY SOURCE PROOF PASS exact5=true receipt_bound_claims=true policy_hashes_emitted=true")
