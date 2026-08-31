from __future__ import annotations

import hashlib
import json
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict

from contract import ContractError, public_proof, validate_owner_message, validate_reply


class SpoolError(RuntimeError):
    pass


@dataclass(frozen=True)
class SpoolPaths:
    root: Path
    inbox: Path
    replies: Path
    public_proof: Path


def make_paths(root: Path) -> SpoolPaths:
    root = root.resolve()
    return SpoolPaths(
        root=root,
        inbox=root / "inbox",
        replies=root / "replies",
        public_proof=root / "public-proof",
    )


def initialize(root: Path) -> SpoolPaths:
    paths = make_paths(root)
    for path in (paths.root, paths.inbox, paths.replies, paths.public_proof):
        path.mkdir(parents=True, exist_ok=True)
    return paths


def _validate_id(value: str) -> str:
    if not isinstance(value, str) or not value or len(value) > 160:
        raise SpoolError("unsafe identifier")
    allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:-"
    if any(ch not in allowed for ch in value):
        raise SpoolError("unsafe identifier")
    return value


def _file_key(request_id: str) -> str:
    request_id = _validate_id(request_id)
    return hashlib.sha256(request_id.encode("utf-8")).hexdigest().upper()


def _atomic_json(path: Path, document: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(document, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n"
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent), text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def _load_json(path: Path) -> Dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
        doc = json.loads(raw)
    except (OSError, json.JSONDecodeError) as exc:
        raise SpoolError("invalid spool document") from exc
    if not isinstance(doc, dict):
        raise SpoolError("spool document must be object")
    return doc


def enqueue_owner_message(root: Path, document: Dict[str, Any]) -> Dict[str, Any]:
    paths = initialize(root)
    try:
        message = validate_owner_message(document)
    except ContractError as exc:
        raise SpoolError(str(exc)) from exc

    request_id = _validate_id(message["request_id"])
    target = paths.inbox / f"{_file_key(request_id)}.json"

    if target.exists():
        existing = _load_json(target)
        try:
            validate_owner_message(existing)
        except ContractError as exc:
            raise SpoolError("existing request is invalid") from exc
        if existing["request_id"] != request_id or existing["idempotency_key"] != message["idempotency_key"] or existing["content_sha256"] != message["content_sha256"]:
            raise SpoolError("replay mismatch")
        return public_proof(existing, state="QUEUED", reason_code="DUPLICATE_SAME_CONTENT")

    _atomic_json(target, message)
    return public_proof(message, state="QUEUED")


def store_kevin_reply(root: Path, document: Dict[str, Any], *, elapsed_ms: int) -> Dict[str, Any]:
    paths = initialize(root)
    try:
        reply = validate_reply(document)
    except ContractError as exc:
        raise SpoolError(str(exc)) from exc

    request_id = _validate_id(reply["request_id"])
    reply_id = _validate_id(reply["reply_id"])
    key = _file_key(request_id)
    request_path = paths.inbox / f"{key}.json"
    if not request_path.exists():
        raise SpoolError("reply has no accepted request")

    request = _load_json(request_path)
    try:
        validate_owner_message(request)
    except ContractError as exc:
        raise SpoolError("accepted request is invalid") from exc
    if request["request_id"] != request_id:
        raise SpoolError("request correlation mismatch")

    target = paths.replies / f"{key}.json"
    if target.exists():
        existing = _load_json(target)
        try:
            validate_reply(existing)
        except ContractError as exc:
            raise SpoolError("existing reply is invalid") from exc
        if existing["request_id"] != request_id or existing["reply_id"] != reply_id or existing["content_sha256"] != reply["content_sha256"]:
            raise SpoolError("reply replay mismatch")
        proof = public_proof(existing, state="REPLIED", elapsed_ms=elapsed_ms, reason_code="DUPLICATE_SAME_REPLY")
        _atomic_json(paths.public_proof / f"{key}.json", proof)
        return proof

    _atomic_json(target, reply)
    proof = public_proof(reply, state="REPLIED", elapsed_ms=elapsed_ms)
    _atomic_json(paths.public_proof / f"{key}.json", proof)
    return proof


def read_reply(root: Path, request_id: str) -> Dict[str, Any] | None:
    paths = initialize(root)
    request_id = _validate_id(request_id)
    target = paths.replies / f"{_file_key(request_id)}.json"
    if not target.exists():
        return None
    reply = _load_json(target)
    try:
        reply = validate_reply(reply)
    except ContractError as exc:
        raise SpoolError("stored reply is invalid") from exc
    if reply["request_id"] != request_id:
        raise SpoolError("stored reply correlation mismatch")
    return reply
