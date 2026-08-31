import hashlib
import json
import tempfile
import unittest
from datetime import datetime, timezone
from http import HTTPStatus
from pathlib import Path

from private_http_adapter import AdapterError, MAX_BODY_BYTES, assert_loopback_host, lookup_reply, submit_message


def message(content="hello Kevin", request_id="owner-adapter-test-0001"):
    return {
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


class AdapterTests(unittest.TestCase):
    def test_loopback_hosts_only(self):
        self.assertEqual(assert_loopback_host("127.0.0.1"), "127.0.0.1")
        self.assertEqual(assert_loopback_host("LOCALHOST"), "localhost")
        for host in ("0.0.0.0", "192.168.1.5", "10.0.0.8", "example.com", ""):
            with self.assertRaises(AdapterError):
                assert_loopback_host(host)

    def test_submit_and_duplicate_are_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            doc = message()
            body = json.dumps(doc).encode()
            status, proof = submit_message(Path(td), body)
            self.assertEqual(status, HTTPStatus.ACCEPTED)
            self.assertEqual(proof["state"], "QUEUED")
            self.assertNotIn("content", proof)
            status2, proof2 = submit_message(Path(td), body)
            self.assertEqual(status2, HTTPStatus.ACCEPTED)
            self.assertEqual(proof2["reason_code"], "DUPLICATE_SAME_CONTENT")

    def test_mismatched_replay_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            first = message("first")
            second = message("second")
            self.assertEqual(submit_message(Path(td), json.dumps(first).encode())[0], HTTPStatus.ACCEPTED)
            status, proof = submit_message(Path(td), json.dumps(second).encode())
            self.assertEqual(status, HTTPStatus.BAD_REQUEST)
            self.assertEqual(proof["reason_code"], "INVALID_MESSAGE")

    def test_unknown_command_surface_rejected_by_contract(self):
        with tempfile.TemporaryDirectory() as td:
            doc = message()
            doc["command"] = "whoami"
            status, _ = submit_message(Path(td), json.dumps(doc).encode())
            self.assertEqual(status, HTTPStatus.BAD_REQUEST)

    def test_body_bounds(self):
        with tempfile.TemporaryDirectory() as td:
            self.assertEqual(submit_message(Path(td), b"")[0], HTTPStatus.BAD_REQUEST)
            self.assertEqual(submit_message(Path(td), b"x" * (MAX_BODY_BYTES + 1))[0], HTTPStatus.BAD_REQUEST)

    def test_reply_lookup_is_correlated_and_body_private_to_adapter_response(self):
        with tempfile.TemporaryDirectory() as td:
            status, reply = lookup_reply(Path(td), "owner-adapter-test-0002")
            self.assertEqual(status, HTTPStatus.OK)
            self.assertEqual(reply["state"], "QUEUED")
            self.assertNotIn("content", reply)


if __name__ == "__main__":
    unittest.main()
