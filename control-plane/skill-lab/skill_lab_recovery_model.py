#!/usr/bin/env python3
"""Pure reference model for Skill Lab v1.0.3 crash/restart reconciliation.

No filesystem, process, shell, network, or authority surface. This exists so CI can
adversarially verify the state machine independently of the PowerShell runner.
"""
from __future__ import annotations
from dataclasses import dataclass
from hashlib import sha256
import json

MAX_RECOVERY_ATTEMPTS = 3
STALE_MINUTES = 15
ALLOWED_OPS = {"create_text", "create_spreadsheet", "ui_notepad_write"}


def canonical_hash(value) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return sha256(payload.encode("utf-8")).hexdigest().upper()


def descriptor(manifest: dict, index: int) -> dict:
    step = manifest["steps"][index]
    op = step["operation"]
    if op not in ALLOWED_OPS:
        raise ValueError("unproven primitive")
    return {
        "id": f"skill-{manifest['id']}-{manifest['version']}-s{index+1:02d}",
        "semantic_key": f"skill:{manifest['id']}:{manifest['version']}:step:{index+1}",
        "operation": op,
        "payload_sha256": canonical_hash(step["payload"]),
    }


def order_matches(order: dict, d: dict) -> bool:
    return bool(order) and all((
        order.get("schema") == 1,
        order.get("kind") == "kevin-green-work-order",
        order.get("id") == d["id"],
        order.get("semantic_key") == d["semantic_key"],
        order.get("authority") == "GREEN",
        order.get("operation") == d["operation"],
        canonical_hash(order.get("payload")) == d["payload_sha256"],
    ))


def valid_done(order: dict, d: dict) -> bool:
    if not order_matches(order, d) or order.get("status") != "DONE":
        return False
    r = order.get("result") or {}
    if r.get("status") != "DONE" or not r.get("completed_at") or not r.get("output_name"):
        return False
    h = str(r.get("sha256") or "")
    if len(h) != 64 or any(c not in "0123456789abcdefABCDEF" for c in h):
        return False
    if not isinstance(r.get("bytes"), int) or r["bytes"] < 0:
        return False
    if d["operation"] == "ui_notepad_write":
        sh = str(r.get("screenshot_sha256") or "")
        if len(sh) != 64 or any(c not in "0123456789abcdefABCDEF" for c in sh):
            return False
        if not r.get("screenshot_name"):
            return False
    return True


@dataclass(frozen=True)
class Decision:
    action: str
    reason: str
    enqueue: bool = False
    consume: bool = False
    adopt: bool = False
    fail: bool = False
    recovery_attempts: int = 0


def reconcile(state: dict, records: list[dict], *, age_minutes: float = 0) -> Decision:
    manifest = state["manifest"]
    index = int(state.get("step_index", 0))
    if index >= len(manifest["steps"]):
        return Decision("COMPLETE", "all steps evidenced")
    d = descriptor(manifest, index)
    hits = [r for r in records if r.get("order", {}).get("id") == d["id"]]
    if len(hits) > 1:
        return Decision("FAIL", "duplicate queue records", fail=True)
    rec = hits[0] if hits else None
    current = str(state.get("current_order_id") or "")
    attempts = int(state.get("recovery_attempts", 0))
    if current and current != d["id"]:
        return Decision("FAIL", "state order id mismatch", fail=True, recovery_attempts=attempts)
    if rec and not order_matches(rec["order"], d):
        return Decision("FAIL", "collision/replay fingerprint mismatch", fail=True, recovery_attempts=attempts)
    if rec:
        qstate = rec["state"]
        if qstate == "FAILED":
            return Decision("FAIL", "operator failed", fail=True, recovery_attempts=attempts)
        if qstate == "DONE":
            if not valid_done(rec["order"], d):
                return Decision("FAIL", "invalid DONE evidence", fail=True, recovery_attempts=attempts)
            prior = {x.get("order_id") for x in state.get("step_results", [])}
            if d["id"] in prior:
                return Decision("FAIL", "completion replay", fail=True, recovery_attempts=attempts)
            return Decision("CONSUME", "matching DONE recovered", consume=True, recovery_attempts=0)
        if qstate in {"READY", "RUNNING"}:
            return Decision("ADOPT", f"matching {qstate} recovered", adopt=True, recovery_attempts=attempts)
        return Decision("FAIL", "unknown queue state", fail=True, recovery_attempts=attempts)
    if current:
        if age_minutes < STALE_MINUTES:
            return Decision("WAIT", "transient missing order", recovery_attempts=attempts)
        attempts += 1
        if attempts > MAX_RECOVERY_ATTEMPTS:
            return Decision("FAIL", "stale recovery budget exhausted", fail=True, recovery_attempts=attempts)
        return Decision("REENQUEUE", "stale missing order reset", enqueue=True, recovery_attempts=attempts)
    return Decision("ENQUEUE", "new deterministic step", enqueue=True, recovery_attempts=attempts)
