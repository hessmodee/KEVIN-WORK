#!/usr/bin/env python3
"""Pure policy model for Bess↔Kevin typed GREEN work orders.

Candidate only. Performs no network calls, process launches, production writes,
permission changes, or external sends.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone

GREEN_VERBS = {
    "dispatch_mission",
    "run_reconcile",
    "run_benchmark",
    "run_support_bridge",
    "refresh_autonomy_telemetry",
}
EXACT_TARGETS = {
    "run_reconcile": {"autonomy"},
    "run_benchmark": {"kevin-benchmark-v1"},
    "run_support_bridge": {"kevin-support-bridge-v1"},
    "refresh_autonomy_telemetry": {"autonomy-telemetry"},
}
FORBIDDEN_AUTHORITY = {
    "permissions",
    "arbitrary_shell",
    "production_chat_tools",
    "financial_transactions",
    "purchases",
    "external_sends",
    "credential_access",
    "safety_weakening",
    "automatic_production_promotion",
}


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def fingerprint(value):
    return hashlib.sha256(canonical(value).encode("utf-8")).hexdigest()


def parse_dt(value):
    d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


def current_precondition(snapshot):
    """Fingerprint only stable, public decision inputs; never secrets/raw prompts."""
    support = snapshot.get("support") or {}
    autonomy = snapshot.get("autonomy") or {}
    material = {
        "support_semantic_hash": support.get("semantic_hash"),
        "autonomy_semantic_hash": autonomy.get("semantic_hash"),
        "governance_ok": (support.get("governance") or {}).get("ok"),
        "benchmark_status": (support.get("benchmark") or {}).get("status"),
        "autonomy_state": autonomy.get("state"),
    }
    return fingerprint(material)


def validate_shape(order):
    allowed = {
        "schema", "kind", "id", "idempotency_key", "created_at", "expires_at",
        "authority_class", "verb", "target", "reason", "precondition_fingerprint",
        "cooldown_key",
    }
    unknown = sorted(set(order) - allowed)
    if unknown:
        raise ValueError("unknown properties: " + ",".join(unknown))
    required = {
        "schema", "kind", "id", "idempotency_key", "created_at", "expires_at",
        "authority_class", "verb", "target", "precondition_fingerprint",
    }
    missing = sorted(k for k in required if k not in order)
    if missing:
        raise ValueError("missing properties: " + ",".join(missing))
    if order.get("schema") != 1 or order.get("kind") != "kevin-work-order":
        raise ValueError("schema/kind mismatch")
    if order.get("authority_class") != "GREEN":
        raise ValueError("authority_class must be GREEN")
    if order.get("verb") not in GREEN_VERBS:
        raise ValueError("verb is not GREEN allowlisted")
    if not isinstance(order.get("id"), str) or not (8 <= len(order["id"]) <= 80):
        raise ValueError("id length invalid")
    if not isinstance(order.get("idempotency_key"), str) or not (8 <= len(order["idempotency_key"]) <= 120):
        raise ValueError("idempotency_key length invalid")
    pf = str(order.get("precondition_fingerprint") or "")
    if len(pf) != 64 or any(c not in "0123456789abcdefABCDEF" for c in pf):
        raise ValueError("precondition_fingerprint must be sha256 hex")
    target = str(order.get("target") or "")
    if not target or len(target) > 128:
        raise ValueError("target invalid")
    exact = EXACT_TARGETS.get(order["verb"])
    if exact is not None and target not in exact:
        raise ValueError("target mismatch for verb")


def evaluate(order, snapshot, ledger, catalog, now):
    """Return a deterministic admission decision. Never executes the order."""
    validate_shape(order)
    now = now if now.tzinfo else now.replace(tzinfo=timezone.utc)
    created, expires = parse_dt(order["created_at"]), parse_dt(order["expires_at"])
    if expires <= now:
        return {"decision": "EXPIRED", "execute": False}
    if created > now.astimezone(created.tzinfo).replace(microsecond=created.microsecond):
        # Keep the policy deterministic; future-skew allowance belongs to transport.
        return {"decision": "FUTURE_CREATED_AT", "execute": False}
    if (expires - created).total_seconds() > 24 * 3600:
        return {"decision": "VALIDITY_TOO_LONG", "execute": False}

    governance = ((snapshot.get("support") or {}).get("governance") or {})
    if governance.get("ok") is not True:
        return {"decision": "BLOCKED_GOVERNANCE", "execute": False}
    live_forbidden = set(governance.get("never_self_authorize") or [])
    if not FORBIDDEN_AUTHORITY <= live_forbidden:
        return {"decision": "BLOCKED_GOVERNANCE_DRIFT", "execute": False}

    processed = ledger.get("processed") or []
    if any(str(x.get("idempotency_key")) == order["idempotency_key"] for x in processed):
        return {"decision": "REPLAY", "execute": False}

    expected = current_precondition(snapshot)
    if order["precondition_fingerprint"].lower() != expected.lower():
        return {"decision": "PRECONDITION_MISMATCH", "execute": False, "expected_precondition": expected}

    cooldown_key = str(order.get("cooldown_key") or f"{order['verb']}:{order['target']}")
    for item in ledger.get("cooldowns") or []:
        if str(item.get("key")) != cooldown_key:
            continue
        until = parse_dt(item.get("until"))
        if until.astimezone(timezone.utc) > now.astimezone(timezone.utc):
            return {"decision": "COOLDOWN", "execute": False, "cooldown_until": item.get("until")}

    if order["verb"] == "dispatch_mission":
        allowed_missions = {str(x.get("id")) for x in catalog.get("missions") or []}
        if str(order["target"]) not in allowed_missions:
            return {"decision": "TARGET_NOT_ALLOWLISTED", "execute": False}
        policy = catalog.get("policy") or {}
        if policy.get("candidate_only") is not True or policy.get("allow_production_mutation") or policy.get("allow_arbitrary_shell"):
            return {"decision": "CATALOG_AUTHORITY_VIOLATION", "execute": False}

    return {
        "decision": "ACCEPT_GREEN",
        "execute": True,
        "precondition_fingerprint": expected,
        "idempotency_key": order["idempotency_key"],
        "cooldown_key": cooldown_key,
    }
