import base64
import json
from pathlib import Path

import pytest

import kevin_gmail_adapter as k


def test_allowlist_accepts_only_owner():
    assert k.require_allowed_recipient("Matt <hessmodee@gmail.com>") == "hessmodee@gmail.com"
    with pytest.raises(ValueError):
        k.require_allowed_recipient("other@example.com")


def test_message_builder_refuses_arbitrary_recipient():
    with pytest.raises(ValueError):
        k.make_message("other@example.com", "x", "y")
    msg = k.make_message("hessmodee@gmail.com", "proof", "hello")
    assert set(msg) == {"raw"}
    decoded = base64.urlsafe_b64decode(msg["raw"].encode("ascii"))
    assert b"To: hessmodee@gmail.com" in decoded
    assert b"Subject: proof" in decoded


def test_extract_plain_text_from_nested_payload():
    data = base64.urlsafe_b64encode(b"reply task text").decode("ascii").rstrip("=")
    payload = {
        "mimeType": "multipart/alternative",
        "parts": [
            {"mimeType": "text/html", "body": {"data": base64.urlsafe_b64encode(b"<b>x</b>").decode("ascii")}},
            {"mimeType": "text/plain", "body": {"data": data}},
        ],
    }
    assert k.extract_text_plain(payload) == "reply task text"


def test_newest_owner_reply_filters_sender():
    messages = [
        {"id": "a", "internalDate": "200", "payload": {"headers": [{"name": "From", "value": "other@example.com"}]}},
        {"id": "b", "internalDate": "100", "payload": {"headers": [{"name": "From", "value": "Matt <hessmodee@gmail.com>"}]}},
        {"id": "c", "internalDate": "300", "payload": {"headers": [{"name": "From", "value": "hessmodee@gmail.com"}]}},
    ]
    assert k.newest_owner_reply(messages, "hessmodee@gmail.com")["id"] == "c"


def test_selftest_public_output_has_no_secret_material():
    result = k.cmd_selftest(type("A", (), {})())
    raw = json.dumps(result).lower()
    assert result["status"] == "SELFTEST_PASS"
    assert result["normal_password_supported"] is False
    assert result["credential_material_emitted"] is False
    for forbidden in ["refresh_token", "client_secret", "access_token", "recovery_code"]:
        assert forbidden not in raw


def test_state_path_stays_under_private_root(monkeypatch, tmp_path):
    monkeypatch.setenv("LOCALAPPDATA", str(tmp_path))
    assert k.private_root() == tmp_path / "Kevin" / "Private"
    assert k.state_path().parent == tmp_path / "Kevin" / "Private"
    assert k.inbox_dir().parent == tmp_path / "Kevin" / "Private"
