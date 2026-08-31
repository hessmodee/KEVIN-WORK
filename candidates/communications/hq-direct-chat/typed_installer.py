"""Typed, candidate-only installer contract for Kevin HQ direct chat.

This module deliberately does not fetch from the network and does not execute commands.
It applies a fixed four-file bundle from a supplied staging root into one fixed private
Kevin component root with exact SHA-256 pins, atomic replacement, backup, rollback,
and a deterministic postcondition callback supplied by the local trusted runner.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Mapping

SCHEMA = 1
KIND = "kevin-hq-chat-install-manifest"
AUTHORITY_CLASS = "GREEN"
AUTHORITY_DELTA = "NONE"
OWNER_POLICY = "Kevin Owner Authorization v1"
ABSENT = "0" * 64
MAX_FILES = 4
MAX_ATTEMPTS = 3

COMPONENTS = {
    "contract.py": "contract.py",
    "private_spool.py": "private_spool.py",
    "private_http_adapter.py": "private_http_adapter.py",
    "mobile_panel.html": "mobile_panel.html",
}

FORBIDDEN_KEYS = {
    "command", "cmd", "argv", "args", "executable", "shell", "powershell",
    "script", "url", "uri", "host", "port", "task", "task_name",
    "destination", "target", "target_path", "source", "source_path",
}


class InstallError(ValueError):
    pass


@dataclass(frozen=True)
class InstallReceipt:
    changed: bool
    idempotent: bool
    before: Mapping[str, str]
    after: Mapping[str, str]
    manifest_id: str


def sha256_file(path: Path) -> str:
    if not path.is_file():
        return ""
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def _is_sha(value: object) -> bool:
    if not isinstance(value, str) or len(value) != 64:
        return False
    try:
        int(value, 16)
    except ValueError:
        return False
    return True


def validate_manifest(manifest: Mapping[str, object]) -> None:
    unknown_forbidden = FORBIDDEN_KEYS.intersection(manifest.keys())
    if unknown_forbidden:
        raise InstallError("forbidden execution/path field present")
    if manifest.get("schema") != SCHEMA or manifest.get("kind") != KIND:
        raise InstallError("manifest identity mismatch")
    mid = manifest.get("id")
    if not isinstance(mid, str) or not (6 <= len(mid) <= 96) or not all(c.isalnum() or c in "._-" for c in mid):
        raise InstallError("manifest id invalid")
    if manifest.get("authority_class") != AUTHORITY_CLASS:
        raise InstallError("authority must be GREEN")
    if manifest.get("authority_delta") != AUTHORITY_DELTA:
        raise InstallError("authority delta must be NONE")
    if manifest.get("owner_policy") != OWNER_POLICY or manifest.get("preauthorized") is not True:
        raise InstallError("owner preauthorization mismatch")
    if manifest.get("operation") != "install_hq_private_chat_v01":
        raise InstallError("operation not allowlisted")

    files = manifest.get("files")
    if not isinstance(files, dict) or set(files) != set(COMPONENTS) or len(files) != MAX_FILES:
        raise InstallError("exact fixed component set required")
    for name, spec in files.items():
        if not isinstance(spec, dict) or set(spec) != {"source_sha256", "expected_current_sha256", "expected_after_sha256"}:
            raise InstallError("component hash contract invalid")
        for key in ("source_sha256", "expected_current_sha256", "expected_after_sha256"):
            if not _is_sha(spec.get(key)):
                raise InstallError("component hash invalid")
        if str(spec["source_sha256"]).upper() != str(spec["expected_after_sha256"]).upper():
            raise InstallError("source hash must equal after hash")


def _write_atomic(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=dst.name + ".tmp-", dir=str(dst.parent))
    os.close(fd)
    tmp = Path(tmp_name)
    try:
        shutil.copyfile(src, tmp)
        os.replace(tmp, dst)
    finally:
        if tmp.exists():
            tmp.unlink()


def apply_bundle(
    manifest: Mapping[str, object],
    staging_root: Path,
    private_root: Path,
    backup_root: Path,
    fixed_selftest: Callable[[Path], bool],
    benchmark_ok: Callable[[], bool],
) -> InstallReceipt:
    """Apply only the fixed chat bundle.

    Root paths are trusted local runner configuration, never manifest-controlled.
    The manifest can choose no path, process, command, host, port or executable.
    """
    validate_manifest(manifest)
    staging_root = staging_root.resolve()
    private_root = private_root.resolve()
    backup_root = backup_root.resolve()

    before: dict[str, str] = {}
    after_expected: dict[str, str] = {}
    sources: dict[str, Path] = {}
    targets: dict[str, Path] = {}
    changed_names: list[str] = []

    for name in COMPONENTS:
        source = (staging_root / name).resolve()
        target = (private_root / COMPONENTS[name]).resolve()
        if source.parent != staging_root or target.parent != private_root:
            raise InstallError("fixed-root containment failed")
        spec = manifest["files"][name]  # type: ignore[index]
        source_sha = sha256_file(source)
        if source_sha != str(spec["source_sha256"]).upper():
            raise InstallError("staged source hash mismatch")
        cur = sha256_file(target)
        expected_cur = str(spec["expected_current_sha256"]).upper()
        if cur:
            if cur != expected_cur and cur != str(spec["expected_after_sha256"]).upper():
                raise InstallError("expected-current mismatch")
        elif expected_cur != ABSENT:
            raise InstallError("missing component not authorized as absent")
        before[name] = cur or ABSENT
        after_expected[name] = str(spec["expected_after_sha256"]).upper()
        sources[name], targets[name] = source, target
        if cur != after_expected[name]:
            changed_names.append(name)

    if not changed_names:
        if not fixed_selftest(private_root) or not benchmark_ok():
            raise InstallError("idempotent postcondition failed")
        return InstallReceipt(False, True, before, dict(before), str(manifest["id"]))

    snapshot = backup_root / str(manifest["id"])
    if snapshot.exists():
        shutil.rmtree(snapshot)
    snapshot.mkdir(parents=True, exist_ok=False)
    existed: dict[str, bool] = {}
    try:
        for name in changed_names:
            target = targets[name]
            existed[name] = target.is_file()
            if existed[name]:
                shutil.copy2(target, snapshot / name)
            _write_atomic(sources[name], target)
            if sha256_file(target) != after_expected[name]:
                raise InstallError("after hash mismatch")

        if not fixed_selftest(private_root):
            raise InstallError("fixed chat selftest failed")
        if not benchmark_ok():
            raise InstallError("fresh benchmark postcondition failed")
    except Exception:
        for name in reversed(changed_names):
            target = targets[name]
            backup = snapshot / name
            if existed.get(name) and backup.is_file():
                _write_atomic(backup, target)
            elif target.exists():
                target.unlink()
        raise

    after = {name: sha256_file(targets[name]) for name in COMPONENTS}
    if after != after_expected:
        raise InstallError("independent bundle postcondition mismatch")
    return InstallReceipt(True, False, before, after, str(manifest["id"]))


def public_receipt(receipt: InstallReceipt) -> str:
    return json.dumps({
        "schema": 1,
        "kind": "kevin-hq-chat-install-proof",
        "manifest_id": receipt.manifest_id,
        "changed": receipt.changed,
        "idempotent": receipt.idempotent,
        "before_sha256": dict(receipt.before),
        "after_sha256": dict(receipt.after),
        "private_content_exposed": False,
        "arbitrary_shell": False,
        "authority_expansion": False,
    }, sort_keys=True)
