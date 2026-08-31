from __future__ import annotations

import hashlib
import re
from datetime import datetime
from typing import Any, Dict

HEX64 = re.compile(r"^[0-9A-F]{64}$")
ID_RE = re.compile(r"^(owner|kevin)-[A-Za-z0-9._:-]{8,128}$")
OWNER_STATES = {"QUEUED", "RECEIVED", "THINKING", "REPLIED", "FAILED"}
MAX_CONTENT = 12000

OWNER_FIELDS = {
    "schema", "kind", "request_id", "idempotency_key", "created_at", "channel",
    "sender", "recipient", "content", "content_sha256"
}
REPLY_FIELDS = {
    "schema", "kind", "request_id", "reply_id", "created_at", "channel", "sender",
    "recipient", "status", "content", "content_sha256"
}

class ContractError(ValueError):
    pass


def _utcish_timestamp(value: Any) -> datetime:
    if not isinstance(value, str) or len(value) > 64:
        raise ContractError("invalid timestamp")
    text = value.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except ValueError as exc:
        raise ContractError("invalid timestamp") from exc
    if dt.tzinfo is None:
        raise ContractError("timestamp must include timezone")
    return dt


def _content_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


def _validate_content(doc: Dict[str, Any]) -> None:
    content = doc.get("content")
    if not isinstance(content, str) or not content.strip() or len(content) > MAX_CONTENT:
        raise ContractError("invalid content")
    claimed = doc.get("content_sha256")
    if not isinstance(claimed, str) or not HEX64.fullmatch(claimed):
        raise ContractError("invalid content hash")
    if _content_hash(content) != claimed:
        raise ContractError("content hash mismatch")


def validate_owner_message(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(doc, dict) or set(doc) != OWNER_FIELDS:
        raise ContractError("owner envelope fields mismatch")
    if doc["schema"] != 1 or doc["kind"] != "kevin-owner-message":
        raise ContractError("owner envelope identity mismatch")
    if doc["channel"] != "hq-private" or doc["sender"] != "owner" or doc["recipient"] != "kevin":
        raise ContractError("owner routing mismatch")
    if not isinstance(doc["request_id"], str) or not ID_RE.fullmatch(doc["request_id"]) or not doc["request_id"].startswith("owner-"):
        raise ContractError("invalid request id")
    if doc["idempotency_key"] != doc["request_id"]:
        raise ContractError("idempotency key must equal request id")
    _utcish_timestamp(doc["created_at"])
    _validate_content(doc)
    return doc


def validate_reply(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(doc, dict) or set(doc) != REPLY_FIELDS:
        raise ContractError("reply envelope fields mismatch")
    if doc["schema"] != 1 or doc["kind"] != "kevin-owner-reply":
        raise ContractError("reply envelope identity mismatch")
    if doc["channel"] != "hq-private" or doc["sender"] != "kevin" or doc["recipient"] != "owner":
        raise ContractError("reply routing mismatch")
    if not isinstance(doc["request_id"], str) or not ID_RE.fullmatch(doc["request_id"]) or not doc["request_id"].startswith("owner-"):
        raise ContractError("invalid request id")
    if not isinstance(doc["reply_id"], str) or not ID_RE.fullmatch(doc["reply_id"]) or not doc["reply_id"].startswith("kevin-"):
        raise ContractError("invalid reply id")
    if doc["status"] not in OWNER_STATES or doc["status"] != "REPLIED":
        raise ContractError("reply must be REPLIED")
    _utcish_timestamp(doc["created_at"])
    _validate_content(doc)
    return doc


def public_proof(envelope: Dict[str, Any], *, state: str, elapsed_ms: int | None = None, reason_code: str | None = None) -> Dict[str, Any]:
    if state not in OWNER_STATES:
        raise ContractError("invalid lifecycle state")
    if elapsed_ms is not None and (not isinstance(elapsed_ms, int) or elapsed_ms < 0 or elapsed_ms > 86_400_000):
        raise ContractError("invalid elapsed_ms")
    proof = {
        "schema": 1,
        "kind": "kevin-owner-chat-public-proof",
        "request_id": envelope["request_id"],
        "state": state,
        "created_at": envelope["created_at"],
        "content_sha256": envelope["content_sha256"],
    }
    if "reply_id" in envelope:
        proof["reply_id"] = envelope["reply_id"]
    if elapsed_ms is not None:
        proof["elapsed_ms"] = elapsed_ms
    if reason_code is not None:
        if not re.fullmatch(r"[A-Z0-9_]{2,64}", reason_code):
            raise ContractError("invalid reason code")
        proof["reason_code"] = reason_code
    return proof
