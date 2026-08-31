from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from email.message import EmailMessage
from email.utils import parseaddr
from pathlib import Path
from typing import Any, Iterable

ALLOWED_TO = {"hessmodee@gmail.com"}
SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]
KEYRING_SERVICE = "Kevin.Gmail.OAuth"
KEYRING_USER = "authorized-user"
DEFAULT_SUBJECT = "Kevin communication proof"


def private_root() -> Path:
    base = os.environ.get("LOCALAPPDATA") or str(Path.home() / ".local" / "share")
    root = Path(base) / "Kevin" / "Private"
    root.mkdir(parents=True, exist_ok=True)
    return root


def state_path() -> Path:
    return private_root() / "gmail-state.json"


def inbox_dir() -> Path:
    p = private_root() / "gmail-inbox"
    p.mkdir(parents=True, exist_ok=True)
    return p


def normalize_email(value: str) -> str:
    _name, addr = parseaddr(value or "")
    return addr.strip().lower()


def require_allowed_recipient(value: str) -> str:
    addr = normalize_email(value)
    if addr not in ALLOWED_TO:
        raise ValueError(f"recipient_not_allowlisted:{addr or '<empty>'}")
    return addr


def b64url_decode(data: str) -> bytes:
    raw = (data or "").encode("ascii")
    raw += b"=" * ((4 - len(raw) % 4) % 4)
    return base64.urlsafe_b64decode(raw)


def extract_text_plain(payload: dict[str, Any] | None) -> str:
    if not payload:
        return ""
    mime = str(payload.get("mimeType") or "").lower()
    body = payload.get("body") or {}
    if mime == "text/plain" and body.get("data"):
        return b64url_decode(str(body["data"])).decode("utf-8", errors="replace").strip()
    for part in payload.get("parts") or []:
        text = extract_text_plain(part)
        if text:
            return text
    if body.get("data") and mime.startswith("text/"):
        return b64url_decode(str(body["data"])).decode("utf-8", errors="replace").strip()
    return ""


def header_map(payload: dict[str, Any] | None) -> dict[str, str]:
    out: dict[str, str] = {}
    for h in (payload or {}).get("headers") or []:
        name = str(h.get("name") or "").lower()
        if name:
            out[name] = str(h.get("value") or "")
    return out


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


def save_json_private(path: Path, obj: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(obj, indent=2, sort_keys=True), encoding="utf-8")
    os.replace(tmp, path)


def load_state() -> dict[str, Any]:
    p = state_path()
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def _imports():
    try:
        import keyring  # type: ignore
        from google.auth.transport.requests import Request  # type: ignore
        from google.oauth2.credentials import Credentials  # type: ignore
        from google_auth_oauthlib.flow import InstalledAppFlow  # type: ignore
        from googleapiclient.discovery import build  # type: ignore
    except Exception as exc:  # pragma: no cover - depends on local environment
        raise RuntimeError(
            "gmail_dependencies_missing: install google-api-python-client google-auth "
            "google-auth-httplib2 google-auth-oauthlib keyring"
        ) from exc
    return keyring, Request, Credentials, InstalledAppFlow, build


def store_credentials(creds: Any) -> None:
    keyring, _Request, _Credentials, _InstalledAppFlow, _build = _imports()
    keyring.set_password(KEYRING_SERVICE, KEYRING_USER, creds.to_json())


def load_credentials() -> Any:
    keyring, Request, Credentials, _InstalledAppFlow, _build = _imports()
    raw = keyring.get_password(KEYRING_SERVICE, KEYRING_USER)
    if not raw:
        raise RuntimeError("gmail_not_enrolled")
    info = json.loads(raw)
    creds = Credentials.from_authorized_user_info(info, SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        keyring.set_password(KEYRING_SERVICE, KEYRING_USER, creds.to_json())
    if not creds.valid:
        raise RuntimeError("gmail_credentials_invalid")
    return creds


def gmail_service() -> Any:
    _keyring, _Request, _Credentials, _InstalledAppFlow, build = _imports()
    return build("gmail", "v1", credentials=load_credentials(), cache_discovery=False)


def cmd_enroll(args: argparse.Namespace) -> dict[str, Any]:
    config = Path(args.client_config).expanduser().resolve()
    if not config.is_file():
        raise FileNotFoundError(f"client_config_missing:{config}")
    _keyring, _Request, _Credentials, InstalledAppFlow, _build = _imports()
    flow = InstalledAppFlow.from_client_secrets_file(str(config), SCOPES)
    creds = flow.run_local_server(port=0, open_browser=True)
    store_credentials(creds)
    return {
        "status": "ENROLLED_LOCAL_SECRET_STORE",
        "scopes": list(SCOPES),
        "secret_store": KEYRING_SERVICE,
        "client_config_persisted_by_adapter": False,
        "credential_material_emitted": False,
    }


def make_message(to_addr: str, subject: str, body: str) -> dict[str, str]:
    to_addr = require_allowed_recipient(to_addr)
    msg = EmailMessage()
    msg["To"] = to_addr
    msg["Subject"] = subject
    msg.set_content(body)
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode("ascii")
    return {"raw": raw}


def cmd_send_test(args: argparse.Namespace) -> dict[str, Any]:
    to_addr = require_allowed_recipient(args.to)
    subject = args.subject or DEFAULT_SUBJECT
    body = (
        "Hello Matt,\n\n"
        "This is Kevin's first controlled Gmail communication proof. "
        "Please reply to this message with a short task for me to understand.\n\n"
        "- Kevin\n"
    )
    service = gmail_service()
    result = service.users().messages().send(
        userId="me", body=make_message(to_addr, subject, body)
    ).execute()
    state = {
        "schema": 1,
        "kind": "kevin-gmail-proof-state",
        "sent_at": now_iso(),
        "to": to_addr,
        "subject": subject,
        "message_id": result.get("id"),
        "thread_id": result.get("threadId"),
    }
    if not state["message_id"] or not state["thread_id"]:
        raise RuntimeError("gmail_send_missing_message_or_thread_id")
    save_json_private(state_path(), state)
    return {
        "status": "SENT",
        "to": to_addr,
        "message_id": state["message_id"],
        "thread_id": state["thread_id"],
        "state_file": state_path().name,
        "credential_material_emitted": False,
    }


def newest_owner_reply(messages: Iterable[dict[str, Any]], owner: str) -> dict[str, Any] | None:
    owner = normalize_email(owner)
    candidates: list[dict[str, Any]] = []
    for m in messages:
        headers = header_map((m or {}).get("payload"))
        if normalize_email(headers.get("from", "")) != owner:
            continue
        candidates.append(m)
    if not candidates:
        return None
    return max(candidates, key=lambda m: int(m.get("internalDate") or 0))


def cmd_check_reply(args: argparse.Namespace) -> dict[str, Any]:
    state = load_state()
    thread_id = state.get("thread_id")
    if not thread_id:
        raise RuntimeError("gmail_no_probe_thread")
    service = gmail_service()
    thread = service.users().threads().get(userId="me", id=thread_id, format="full").execute()
    reply = newest_owner_reply(thread.get("messages") or [], args.from_addr)
    if not reply:
        return {"status": "NO_REPLY_YET", "thread_id": thread_id}
    headers = header_map(reply.get("payload"))
    body = extract_text_plain(reply.get("payload"))
    if not body:
        raise RuntimeError("gmail_reply_has_no_readable_text_plain_body")
    msg_id = str(reply.get("id") or "unknown")
    body_path = inbox_dir() / f"reply-{msg_id}.txt"
    body_path.write_text(body, encoding="utf-8")
    proof = {
        "schema": 1,
        "kind": "kevin-gmail-reply-proof",
        "status": "REPLY_STORED_LOCAL_PRIVATE",
        "thread_id": thread_id,
        "message_id": msg_id,
        "from": normalize_email(headers.get("from", "")),
        "subject": headers.get("subject", ""),
        "internal_date_ms": int(reply.get("internalDate") or 0),
        "body_sha256": sha256_text(body),
        "body_length": len(body),
        "private_body_file": body_path.name,
        "body_emitted_publicly": False,
        "credential_material_emitted": False,
    }
    state["latest_reply"] = {k: v for k, v in proof.items() if k not in {"schema", "kind"}}
    save_json_private(state_path(), state)
    return proof


def cmd_selftest(_args: argparse.Namespace) -> dict[str, Any]:
    assert require_allowed_recipient("Matt <hessmodee@gmail.com>") == "hessmodee@gmail.com"
    try:
        require_allowed_recipient("someone@example.com")
    except ValueError:
        pass
    else:
        raise AssertionError("allowlist_failed")
    sample = base64.urlsafe_b64encode(b"do the safe test task").decode("ascii").rstrip("=")
    payload = {"mimeType": "multipart/alternative", "parts": [{"mimeType": "text/plain", "body": {"data": sample}}]}
    assert extract_text_plain(payload) == "do the safe test task"
    msgs = [
        {"id": "1", "internalDate": "10", "payload": {"headers": [{"name": "From", "value": "other@example.com"}]}},
        {"id": "2", "internalDate": "20", "payload": {"headers": [{"name": "From", "value": "Matt <hessmodee@gmail.com>"}]}},
    ]
    assert newest_owner_reply(msgs, "hessmodee@gmail.com")["id"] == "2"
    return {
        "status": "SELFTEST_PASS",
        "recipient_allowlist": sorted(ALLOWED_TO),
        "scopes": list(SCOPES),
        "normal_password_supported": False,
        "credential_material_emitted": False,
    }


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Narrow Kevin Gmail OAuth candidate")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("selftest")
    e = sub.add_parser("enroll")
    e.add_argument("--client-config", required=True)
    s = sub.add_parser("send-test")
    s.add_argument("--to", default="hessmodee@gmail.com")
    s.add_argument("--subject", default=DEFAULT_SUBJECT)
    c = sub.add_parser("check-reply")
    c.add_argument("--from-addr", default="hessmodee@gmail.com")
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "selftest":
            result = cmd_selftest(args)
        elif args.command == "enroll":
            result = cmd_enroll(args)
        elif args.command == "send-test":
            result = cmd_send_test(args)
        elif args.command == "check-reply":
            result = cmd_check_reply(args)
        else:  # pragma: no cover
            raise RuntimeError("unknown_command")
        print(json.dumps(result, sort_keys=True))
        return 0
    except Exception as exc:
        print(json.dumps({"status": "ERROR", "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
