from __future__ import annotations

import re
from datetime import datetime, timezone

ALLOWED_TYPES = {"FACT", "DECISION", "PROJECT", "SKILL", "POSTMORTEM", "OPPORTUNITY"}
ALLOWED_TRUST = {"VERIFIED", "CANDIDATE", "REJECTED"}
SHA256 = re.compile(r"^[0-9a-fA-F]{64}$")
REQUIRED = {"record_id","record_type","statement","source_refs","observed_at","stale_after","confidence","trust_state","authority_class"}


def _dt(value: str) -> datetime:
    d = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if d.tzinfo is None:
        raise ValueError("timestamp must be timezone-aware")
    return d.astimezone(timezone.utc)


def validate(record: dict, now: datetime | None = None) -> tuple[bool, str]:
    if set(record) != REQUIRED:
        return False, "schema_mismatch"
    if record["record_type"] not in ALLOWED_TYPES:
        return False, "record_type"
    if record["trust_state"] not in ALLOWED_TRUST:
        return False, "trust_state"
    if record["authority_class"] != "KNOWLEDGE_ONLY":
        return False, "authority_expansion"
    if not isinstance(record["statement"], str) or not record["statement"].strip():
        return False, "empty_statement"
    refs = record["source_refs"]
    if not isinstance(refs, list) or not refs:
        return False, "missing_sources"
    ids = set()
    for ref in refs:
        if set(ref) != {"source_id","sha256","trust_level"}:
            return False, "source_schema"
        if ref["source_id"] in ids:
            return False, "duplicate_source"
        ids.add(ref["source_id"])
        if not SHA256.fullmatch(str(ref["sha256"])):
            return False, "source_hash"
        if ref["trust_level"] not in {"PRIMARY","CORROBORATED","UNVERIFIED"}:
            return False, "source_trust"
    try:
        observed = _dt(record["observed_at"])
        stale = _dt(record["stale_after"])
    except Exception:
        return False, "timestamp"
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    if stale <= observed:
        return False, "invalid_freshness_window"
    if observed > now:
        return False, "future_observation"
    if not isinstance(record["confidence"], (int, float)) or not (0 <= record["confidence"] <= 1):
        return False, "confidence"
    if record["trust_state"] == "VERIFIED":
        if now >= stale:
            return False, "stale_verified_claim"
        if any(r["trust_level"] == "UNVERIFIED" for r in refs):
            return False, "unverified_source"
        if record["confidence"] < 0.7:
            return False, "low_confidence_verified"
    return True, "ok"


if __name__ == "__main__":
    raise SystemExit("library-only validator; no executor surface")
