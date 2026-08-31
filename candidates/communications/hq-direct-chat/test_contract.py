import hashlib
import unittest

from contract import ContractError, public_proof, validate_owner_message, validate_reply


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest().upper()


def owner(content="Kevin, status please"):
    return {
        "schema": 1,
        "kind": "kevin-owner-message",
        "request_id": "owner-12345678-abcd",
        "idempotency_key": "owner-12345678-abcd",
        "created_at": "2026-08-31T01:20:00-06:00",
        "channel": "hq-private",
        "sender": "owner",
        "recipient": "kevin",
        "content": content,
        "content_sha256": sha(content),
    }


def reply(content="All systems checked"):
    return {
        "schema": 1,
        "kind": "kevin-owner-reply",
        "request_id": "owner-12345678-abcd",
        "reply_id": "kevin-12345678-abcd",
        "created_at": "2026-08-31T01:20:03-06:00",
        "channel": "hq-private",
        "sender": "kevin",
        "recipient": "owner",
        "status": "REPLIED",
        "content": content,
        "content_sha256": sha(content),
    }


class ContractTests(unittest.TestCase):
    def test_valid_owner(self):
        self.assertEqual(validate_owner_message(owner())["sender"], "owner")

    def test_valid_reply(self):
        self.assertEqual(validate_reply(reply())["status"], "REPLIED")

    def test_hash_tamper_rejected(self):
        d = owner()
        d["content"] = "different"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_replay_key_cannot_change(self):
        d = owner()
        d["idempotency_key"] = "owner-87654321-dcba"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_public_channel_rejected(self):
        d = owner()
        d["channel"] = "github-pages"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_route_expansion_rejected(self):
        d = owner()
        d["recipient"] = "third-party"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_unknown_field_rejected(self):
        d = owner()
        d["command"] = "powershell.exe"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_naive_timestamp_rejected(self):
        d = owner()
        d["created_at"] = "2026-08-31T01:20:00"
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_nonterminal_reply_rejected(self):
        d = reply()
        d["status"] = "THINKING"
        with self.assertRaises(ContractError): validate_reply(d)

    def test_public_proof_has_no_body(self):
        d = owner("private message")
        p = public_proof(d, state="RECEIVED", elapsed_ms=35)
        self.assertNotIn("content", p)
        self.assertNotIn("endpoint", p)
        self.assertEqual(p["content_sha256"], sha("private message"))

    def test_public_reason_code_bounded(self):
        with self.assertRaises(ContractError):
            public_proof(owner(), state="FAILED", reason_code="contains private detail")

    def test_content_size_bounded(self):
        text = "x" * 12001
        d = owner(text)
        with self.assertRaises(ContractError): validate_owner_message(d)

    def test_invalid_state_rejected(self):
        with self.assertRaises(ContractError): public_proof(owner(), state="EXECUTE_SHELL")


if __name__ == "__main__":
    unittest.main()
