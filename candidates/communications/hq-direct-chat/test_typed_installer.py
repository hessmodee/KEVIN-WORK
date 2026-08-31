import hashlib
import json
from pathlib import Path

import pytest

from typed_installer import ABSENT, InstallError, apply_bundle, public_receipt

FILES = ["contract.py", "private_spool.py", "private_http_adapter.py", "mobile_panel.html"]


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def make_manifest(stage: Path, current=None):
    current = current or {name: ABSENT for name in FILES}
    files = {}
    for name in FILES:
        h = sha_bytes((stage / name).read_bytes())
        files[name] = {"source_sha256": h, "expected_current_sha256": current[name], "expected_after_sha256": h}
    return {
        "schema": 1,
        "kind": "kevin-hq-chat-install-manifest",
        "id": "hq-chat-install-test-v01",
        "authority_class": "GREEN",
        "authority_delta": "NONE",
        "owner_policy": "Kevin Owner Authorization v1",
        "preauthorized": True,
        "operation": "install_hq_private_chat_v01",
        "files": files,
    }


def prepare(tmp_path):
    stage = tmp_path / "stage"
    private = tmp_path / "private"
    backups = tmp_path / "backups"
    stage.mkdir()
    for i, name in enumerate(FILES):
        (stage / name).write_text(f"component-{i}\n", encoding="utf-8")
    return stage, private, backups


def test_fresh_install_and_public_proof(tmp_path):
    stage, private, backups = prepare(tmp_path)
    manifest = make_manifest(stage)
    seen = {"selftest": 0, "bench": 0}
    def selftest(root):
        seen["selftest"] += 1
        return all((root / n).is_file() for n in FILES)
    def bench():
        seen["bench"] += 1
        return True
    receipt = apply_bundle(manifest, stage, private, backups, selftest, bench)
    assert receipt.changed and not receipt.idempotent
    assert seen == {"selftest": 1, "bench": 1}
    proof = json.loads(public_receipt(receipt))
    assert proof["private_content_exposed"] is False
    assert proof["arbitrary_shell"] is False
    assert proof["authority_expansion"] is False
    assert "content" not in proof and "body" not in proof


def test_replay_is_idempotent(tmp_path):
    stage, private, backups = prepare(tmp_path)
    apply_bundle(make_manifest(stage), stage, private, backups, lambda _: True, lambda: True)
    current = {name: sha_bytes((private / name).read_bytes()) for name in FILES}
    receipt = apply_bundle(make_manifest(stage, current), stage, private, backups, lambda _: True, lambda: True)
    assert not receipt.changed and receipt.idempotent


def test_expected_current_mismatch_fails_closed(tmp_path):
    stage, private, backups = prepare(tmp_path)
    private.mkdir()
    (private / "contract.py").write_text("unexpected", encoding="utf-8")
    with pytest.raises(InstallError, match="expected-current mismatch"):
        apply_bundle(make_manifest(stage), stage, private, backups, lambda _: True, lambda: True)


def test_source_tamper_fails_closed(tmp_path):
    stage, private, backups = prepare(tmp_path)
    manifest = make_manifest(stage)
    (stage / "private_spool.py").write_text("tampered", encoding="utf-8")
    with pytest.raises(InstallError, match="staged source hash mismatch"):
        apply_bundle(manifest, stage, private, backups, lambda _: True, lambda: True)


def test_forbidden_control_fields_rejected(tmp_path):
    stage, private, backups = prepare(tmp_path)
    for field in ("command", "target_path", "host", "url"):
        manifest = make_manifest(stage)
        manifest[field] = "NOT_ALLOWED"
        with pytest.raises(InstallError, match="forbidden execution/path field"):
            apply_bundle(manifest, stage, private, backups, lambda _: True, lambda: True)


def test_exact_component_set_required(tmp_path):
    stage, private, backups = prepare(tmp_path)
    manifest = make_manifest(stage)
    manifest["files"]["extra.py"] = manifest["files"]["contract.py"].copy()
    with pytest.raises(InstallError, match="exact fixed component set"):
        apply_bundle(manifest, stage, private, backups, lambda _: True, lambda: True)


def test_selftest_failure_rolls_back(tmp_path):
    stage, private, backups = prepare(tmp_path)
    private.mkdir()
    old = {}
    for i, name in enumerate(FILES):
        data = f"old-{i}\n"
        (private / name).write_text(data, encoding="utf-8")
        old[name] = sha_bytes(data.encode())
    with pytest.raises(InstallError, match="fixed chat selftest failed"):
        apply_bundle(make_manifest(stage, old), stage, private, backups, lambda _: False, lambda: True)
    for name in FILES:
        assert sha_bytes((private / name).read_bytes()) == old[name]


def test_benchmark_failure_rolls_back(tmp_path):
    stage, private, backups = prepare(tmp_path)
    with pytest.raises(InstallError, match="fresh benchmark postcondition failed"):
        apply_bundle(make_manifest(stage), stage, private, backups, lambda _: True, lambda: False)
    assert all(not (private / name).exists() for name in FILES)
