from __future__ import annotations

import hashlib
import tempfile
import unittest
from pathlib import Path

from typed_transport import TransportError, execute_typed_request, public_transport_receipt, validate_request

FILES = ["contract.py", "private_spool.py", "private_http_adapter.py", "mobile_panel.html"]

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()

class TypedTransportTests(unittest.TestCase):
    def make_request(self, root: Path):
        files = {}
        for name in FILES:
            data = ("payload:" + name).encode()
            (root / name).write_bytes(data)
            files[name] = {
                "source_sha256": sha(data),
                "expected_current_sha256": "0" * 64,
                "expected_after_sha256": sha(data),
            }
        manifest = {
            "schema": 1,
            "kind": "kevin-hq-chat-install-manifest",
            "id": "chat-transport-proof-01",
            "authority_class": "GREEN",
            "authority_delta": "NONE",
            "owner_policy": "Kevin Owner Authorization v1",
            "preauthorized": True,
            "operation": "install_hq_private_chat_v01",
            "files": files,
        }
        return {
            "schema": 1,
            "kind": "kevin-hq-chat-install-request",
            "request_id": "req-chat-00000001",
            "idempotency_key": "req-chat-00000001",
            "operation": "install_hq_private_chat_v01",
            "manifest": manifest,
        }

    def test_valid_request_and_idempotent_execute(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td); staging = base / "stage"; private = base / "private"; backup = base / "backup"
            staging.mkdir(); private.mkdir(); backup.mkdir()
            req = self.make_request(staging)
            rec1 = execute_typed_request(req, staging_root=staging, private_root=private, backup_root=backup,
                                         fixed_selftest=lambda p: all((p / n).is_file() for n in FILES), benchmark_ok=lambda: True)
            self.assertTrue(rec1.changed)
            for name in FILES:
                req["manifest"]["files"][name]["expected_current_sha256"] = req["manifest"]["files"][name]["expected_after_sha256"]
            rec2 = execute_typed_request(req, staging_root=staging, private_root=private, backup_root=backup,
                                         fixed_selftest=lambda p: True, benchmark_ok=lambda: True)
            self.assertTrue(rec2.idempotent)
            proof = public_transport_receipt(req["request_id"], rec2)
            self.assertFalse(proof["arbitrary_shell"])
            self.assertFalse(proof["network_fetch"])

    def test_rejects_unknown_or_exec_path_fields(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td); root.mkdir(exist_ok=True)
            req = self.make_request(root)
            for key, value in [("command", "whoami"), ("path", "C:/x"), ("host", "0.0.0.0"), ("url", "https://example.com")]:
                bad = dict(req); bad[key] = value
                with self.assertRaises(TransportError):
                    validate_request(bad)

    def test_rejects_idempotency_or_operation_drift(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td); req = self.make_request(root)
            bad = dict(req); bad["idempotency_key"] = "different"
            with self.assertRaises(TransportError): validate_request(bad)
            bad = dict(req); bad["operation"] = "anything_else"
            with self.assertRaises(TransportError): validate_request(bad)

if __name__ == "__main__":
    unittest.main()
