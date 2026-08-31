from __future__ import annotations

import json
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Dict, Tuple
from urllib.parse import parse_qs, urlparse

from private_spool import SpoolError, enqueue_owner_message, read_reply

MAX_BODY_BYTES = 16_384
LOOPBACK_HOSTS = {"127.0.0.1", "::1", "localhost"}


class AdapterError(ValueError):
    pass


def assert_loopback_host(host: str) -> str:
    if not isinstance(host, str) or host.strip().lower() not in LOOPBACK_HOSTS:
        raise AdapterError("adapter must bind loopback only")
    return host.strip().lower()


def _json_bytes(document: Dict[str, Any]) -> bytes:
    return (json.dumps(document, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def submit_message(root: Path, body: bytes) -> Tuple[int, Dict[str, Any]]:
    if not isinstance(body, (bytes, bytearray)) or not body or len(body) > MAX_BODY_BYTES:
        return HTTPStatus.BAD_REQUEST, {"ok": False, "reason_code": "INVALID_BODY"}
    try:
        document = json.loads(bytes(body).decode("utf-8"))
        if not isinstance(document, dict):
            raise ValueError("message must be object")
        proof = enqueue_owner_message(root, document)
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError, SpoolError):
        return HTTPStatus.BAD_REQUEST, {"ok": False, "reason_code": "INVALID_MESSAGE"}
    return HTTPStatus.ACCEPTED, {"ok": True, "state": proof["state"], "request_id": proof["request_id"], "content_sha256": proof["content_sha256"], "reason_code": proof.get("reason_code")}


def lookup_reply(root: Path, request_id: str) -> Tuple[int, Dict[str, Any]]:
    try:
        reply = read_reply(root, request_id)
    except SpoolError:
        return HTTPStatus.BAD_REQUEST, {"ok": False, "reason_code": "INVALID_REQUEST_ID"}
    if reply is None:
        return HTTPStatus.OK, {"ok": True, "state": "QUEUED", "request_id": request_id}
    return HTTPStatus.OK, {
        "ok": True,
        "state": "REPLIED",
        "request_id": reply["request_id"],
        "reply_id": reply["reply_id"],
        "created_at": reply["created_at"],
        "content": reply["content"],
        "content_sha256": reply["content_sha256"],
    }


class PrivateChatHandler(BaseHTTPRequestHandler):
    server_version = "KevinHQPrivateChat/0.1"

    def _write_json(self, status: int, document: Dict[str, Any]) -> None:
        payload = _json_bytes(document)
        self.send_response(int(status))
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        self.wfile.write(payload)

    @property
    def spool_root(self) -> Path:
        return Path(getattr(self.server, "spool_root"))

    def do_POST(self) -> None:
        if self.path != "/api/v1/messages":
            self._write_json(HTTPStatus.NOT_FOUND, {"ok": False, "reason_code": "NOT_FOUND"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = -1
        if length <= 0 or length > MAX_BODY_BYTES:
            self._write_json(HTTPStatus.BAD_REQUEST, {"ok": False, "reason_code": "INVALID_BODY"})
            return
        status, document = submit_message(self.spool_root, self.rfile.read(length))
        self._write_json(status, document)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/healthz":
            self._write_json(HTTPStatus.OK, {"ok": True, "kind": "kevin-hq-private-chat-adapter", "version": "0.1", "transport": "loopback-only"})
            return
        if parsed.path == "/api/v1/replies":
            values = parse_qs(parsed.query, keep_blank_values=True)
            ids = values.get("request_id", [])
            if len(ids) != 1:
                self._write_json(HTTPStatus.BAD_REQUEST, {"ok": False, "reason_code": "INVALID_REQUEST_ID"})
                return
            status, document = lookup_reply(self.spool_root, ids[0])
            self._write_json(status, document)
            return
        self._write_json(HTTPStatus.NOT_FOUND, {"ok": False, "reason_code": "NOT_FOUND"})

    def log_message(self, format: str, *args: Any) -> None:
        # Private message bodies and query contents must never be copied to console logs.
        return


def build_server(root: Path, *, host: str = "127.0.0.1", port: int = 8765) -> ThreadingHTTPServer:
    host = assert_loopback_host(host)
    if not isinstance(port, int) or port < 1024 or port > 65535:
        raise AdapterError("port outside bounded range")
    server = ThreadingHTTPServer((host, port), PrivateChatHandler)
    server.spool_root = str(Path(root).resolve())  # type: ignore[attr-defined]
    return server


def selftest() -> None:
    import hashlib
    import tempfile
    from datetime import datetime, timezone

    content = "benign private chat adapter selftest"
    request_id = "owner-adapter-selftest-0001"
    message = {
        "schema": 1,
        "kind": "kevin-owner-message",
        "request_id": request_id,
        "idempotency_key": request_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "channel": "hq-private",
        "sender": "owner",
        "recipient": "kevin",
        "content": content,
        "content_sha256": hashlib.sha256(content.encode("utf-8")).hexdigest().upper(),
    }
    with tempfile.TemporaryDirectory() as td:
        status, proof = submit_message(Path(td), _json_bytes(message))
        if status != HTTPStatus.ACCEPTED or proof.get("state") != "QUEUED":
            raise AdapterError("selftest enqueue failed")
        status2, proof2 = submit_message(Path(td), _json_bytes(message))
        if status2 != HTTPStatus.ACCEPTED or proof2.get("reason_code") != "DUPLICATE_SAME_CONTENT":
            raise AdapterError("selftest idempotency failed")
    assert_loopback_host("127.0.0.1")
    blocked = False
    try:
        assert_loopback_host("0.0.0.0")
    except AdapterError:
        blocked = True
    if not blocked:
        raise AdapterError("non-loopback bind accepted")
    print("KEVIN HQ PRIVATE CHAT ADAPTER v0.1 SELFTEST PASS loopback_only=true arbitrary_shell=false outbound_network=false")


if __name__ == "__main__":
    selftest()
