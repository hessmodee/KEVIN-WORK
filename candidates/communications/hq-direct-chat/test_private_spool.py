import hashlib
import tempfile
import unittest
from pathlib import Path

from private_spool import SpoolError, enqueue_owner_message, read_reply, store_kevin_reply


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


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


class PrivateSpoolTests(unittest.TestCase):
    def test_enqueue_and_read_reply(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            proof = enqueue_owner_message(root, owner())
            self.assertEqual(proof["state"], "QUEUED")
            self.assertNotIn("content", proof)
            reply_proof = store_kevin_reply(root, reply(), elapsed_ms=3000)
            self.assertEqual(reply_proof["state"], "REPLIED")
            self.assertNotIn("content", reply_proof)
            self.assertEqual(read_reply(root, owner()["request_id"])["content"], "All systems checked")

    def test_duplicate_same_request_is_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            enqueue_owner_message(root, owner())
            proof = enqueue_owner_message(root, owner())
            self.assertEqual(proof["reason_code"], "DUPLICATE_SAME_CONTENT")
            self.assertEqual(len(list((root / "inbox").glob("*.json"))), 1)

    def test_duplicate_request_with_new_content_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            enqueue_owner_message(root, owner())
            changed = owner("different request")
            with self.assertRaises(SpoolError):
                enqueue_owner_message(root, changed)

    def test_reply_requires_accepted_request(self):
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaises(SpoolError):
                store_kevin_reply(Path(td), reply(), elapsed_ms=100)

    def test_duplicate_same_reply_is_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            enqueue_owner_message(root, owner())
            store_kevin_reply(root, reply(), elapsed_ms=3000)
            proof = store_kevin_reply(root, reply(), elapsed_ms=3000)
            self.assertEqual(proof["reason_code"], "DUPLICATE_SAME_REPLY")
            self.assertEqual(len(list((root / "replies").glob("*.json"))), 1)

    def test_changed_reply_for_same_request_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            enqueue_owner_message(root, owner())
            store_kevin_reply(root, reply(), elapsed_ms=3000)
            changed = reply("different response")
            with self.assertRaises(SpoolError):
                store_kevin_reply(root, changed, elapsed_ms=3000)

    def test_unsafe_identifier_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            bad = owner()
            bad["request_id"] = "owner-../../escape"
            bad["idempotency_key"] = bad["request_id"]
            with self.assertRaises(SpoolError):
                enqueue_owner_message(Path(td), bad)

    def test_public_proof_contains_no_body(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            enqueue_owner_message(root, owner("private owner text"))
            store_kevin_reply(root, reply("private Kevin reply"), elapsed_ms=42)
            proof_text = (root / "public-proof" / "owner-12345678-abcd.json").read_text(encoding="utf-8")
            self.assertNotIn("private owner text", proof_text)
            self.assertNotIn("private Kevin reply", proof_text)
            self.assertNotIn('"content"', proof_text)


if __name__ == "__main__":
    unittest.main()
