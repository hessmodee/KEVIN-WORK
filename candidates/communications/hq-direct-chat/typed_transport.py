"""Typed transport shim for the fixed Kevin HQ direct-chat installer.

Candidate-only. No shell, subprocess, network, caller-selected path, or dynamic import.
The trusted local runner supplies fixed roots and callbacks. Remote/intake data may only
select the one allowlisted operation and exact hashes for the fixed four components.
"""
from __future__ import annotations

from pathlib import Path
from typing import Callable, Mapping

from typed_installer import InstallReceipt, apply_bundle, public_receipt, validate_manifest

SCHEMA = 1
KIND = "kevin-hq-chat-install-request"
OPERATION = "install_hq_private_chat_v01"
ALLOWED_KEYS = {"schema", "kind", "request_id", "idempotency_key", "operation", "manifest"}
FORBIDDEN_KEYS = {
    "command", "cmd", "argv", "args", "shell", "powershell", "executable", "script",
    "url", "uri", "host", "port", "path", "source", "destination", "target", "env",
}

class TransportError(ValueError):
    pass


def validate_request(doc: Mapping[str, object]) -> Mapping[str, object]:
    if not isinstance(doc, Mapping) or set(doc) != ALLOWED_KEYS:
        raise TransportError("request fields mismatch")
    if FORBIDDEN_KEYS.intersection(doc.keys()):
        raise TransportError("forbidden execution or path field present")
    if doc.get("schema") != SCHEMA or doc.get("kind") != KIND:
        raise TransportError("request identity mismatch")
    rid = doc.get("request_id")
    idem = doc.get("idempotency_key")
    if not isinstance(rid, str) or not (8 <= len(rid) <= 96) or rid != idem:
        raise TransportError("request id/idempotency mismatch")
    if doc.get("operation") != OPERATION:
        raise TransportError("operation not allowlisted")
    manifest = doc.get("manifest")
    if not isinstance(manifest, Mapping):
        raise TransportError("manifest missing")
    validate_manifest(manifest)
    if manifest.get("operation") != OPERATION:
        raise TransportError("nested operation mismatch")
    return doc


def execute_typed_request(
    doc: Mapping[str, object],
    *,
    staging_root: Path,
    private_root: Path,
    backup_root: Path,
    fixed_selftest: Callable[[Path], bool],
    benchmark_ok: Callable[[], bool],
) -> InstallReceipt:
    """Execute the single fixed install request through the already-bounded installer."""
    validate_request(doc)
    manifest = doc["manifest"]
    assert isinstance(manifest, Mapping)
    return apply_bundle(
        manifest,
        staging_root=staging_root,
        private_root=private_root,
        backup_root=backup_root,
        fixed_selftest=fixed_selftest,
        benchmark_ok=benchmark_ok,
    )


def public_transport_receipt(request_id: str, receipt: InstallReceipt) -> dict[str, object]:
    """Metadata-only receipt; no message body, endpoint, path, credential, or configuration."""
    return {
        "schema": 1,
        "kind": "kevin-hq-chat-install-transport-proof",
        "request_id": request_id,
        "installer_receipt": public_receipt(receipt),
        "arbitrary_shell": False,
        "network_fetch": False,
        "caller_selected_path": False,
        "authority_expansion": False,
    }
