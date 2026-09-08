#!/usr/bin/env python3
"""Kevin Proven Skill Invocation v1.

Stages fresh GREEN work orders for an already-PROVEN composite skill without
mutating Skill Lab qualification history. Reconcile mode consumes only
correlated DONE/FAILED work-order evidence and emits an invocation receipt.

Authority delta: NONE. No promotion, arbitrary shell/code, permission change,
or primitive allowlist expansion is possible through this lane.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

VERSION = "1.0.0"
ALLOWED_PRIMITIVES = {"create_text", "create_spreadsheet"}
SAFE_EXTENSIONS = {"create_text": {".md", ".txt"}, "create_spreadsheet": {".xlsx"}}
ID_RE = re.compile(r"^[A-Za-z0-9._-]{4,96}$")
SKILL_KEY_RE = re.compile(r"^[A-Za-z0-9._-]{4,80}@[A-Za-z0-9._-]{1,32}$")
HASH_RE = re.compile(r"^[A-Fa-f0-9]{64}$")
RESULT_FILE_RE = re.compile(r"^[A-Za-z0-9._-]+\.json$")


class InvocationError(RuntimeError):
    pass


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha256_obj(value: Any) -> str:
    return hashlib.sha256(canonical(value)).hexdigest().upper()


def read_json(path: Path, max_bytes: int = 2_097_152) -> Dict[str, Any]:
    if not path.is_file() or path.is_symlink():
        raise InvocationError(f"JSON_MISSING_OR_UNSAFE:{path}")
    size = path.stat().st_size
    if size < 2 or size > max_bytes:
        raise InvocationError(f"JSON_SIZE_INVALID:{path}")
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    try:
        value = json.loads(raw.decode("utf-8"))
    except Exception as exc:
        raise InvocationError(f"JSON_UNREADABLE:{path}") from exc
    if not isinstance(value, dict):
        raise InvocationError(f"JSON_ROOT_NOT_OBJECT:{path}")
    return value


def atomic_write_json(path: Path, value: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(value, indent=2, ensure_ascii=False) + "\n"
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".tmp-", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def valid_timestamp(value: Any) -> bool:
    if not isinstance(value, str) or not value or len(value) > 40:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except ValueError:
        return False


def validate_registry(registry: Dict[str, Any]) -> None:
    if registry.get("schema") != 1 or registry.get("kind") != "kevin-composite-skill-registry":
        raise InvocationError("SKILL_REGISTRY_INVALID_SCHEMA")
    skills = registry.get("skills")
    if not isinstance(skills, list) or len(skills) > 2048 or not valid_timestamp(registry.get("updated_at")):
        raise InvocationError("SKILL_REGISTRY_INVALID_SKILLS_OR_TIMESTAMP")
    seen = set()
    for entry in skills:
        if not isinstance(entry, dict):
            raise InvocationError("SKILL_REGISTRY_INVALID_ENTRY")
        fields = ("id", "version", "key", "authority", "status", "name", "manifest_sha256", "proof_sha256", "result_file")
        if any(not isinstance(entry.get(field), str) for field in fields):
            raise InvocationError("SKILL_REGISTRY_INVALID_FIELD_TYPE")
        key = entry["key"]
        if key != f'{entry["id"]}@{entry["version"]}' or key.lower() in seen:
            raise InvocationError("SKILL_REGISTRY_DUPLICATE_OR_MISMATCHED_KEY")
        seen.add(key.lower())
        if entry["authority"] != "GREEN" or entry["status"] != "PROVEN":
            raise InvocationError("SKILL_REGISTRY_UNPROVEN_OR_UNAUTHORIZED_ENTRY")
        if not HASH_RE.fullmatch(entry["manifest_sha256"]) or not HASH_RE.fullmatch(entry["proof_sha256"]):
            raise InvocationError("SKILL_REGISTRY_INVALID_PROOF_HASH")
        if not valid_timestamp(entry.get("proven_at")):
            raise InvocationError("SKILL_REGISTRY_INVALID_PROOF_TIMESTAMP")
        if not RESULT_FILE_RE.fullmatch(entry["result_file"]) or ".." in entry["result_file"]:
            raise InvocationError("SKILL_REGISTRY_INVALID_RESULT_NAME")
        primitives = entry.get("primitive_steps")
        if not isinstance(primitives, list) or not (1 <= len(primitives) <= 12):
            raise InvocationError("SKILL_REGISTRY_INVALID_PRIMITIVES")
        if any(p not in ALLOWED_PRIMITIVES for p in primitives):
            raise InvocationError("SKILL_REGISTRY_UNAUTHORIZED_PRIMITIVE")


def validate_filename(name: Any, allowed: Iterable[str]) -> None:
    if not isinstance(name, str) or not name or len(name) > 96 or ".." in name or any(ch in name for ch in '\\/:*?"<>|'):
        raise InvocationError("FILENAME_INVALID")
    if Path(name).suffix.lower() not in set(allowed):
        raise InvocationError("FILE_EXTENSION_NOT_ALLOWLISTED")


def validate_workbook(workbook: Any) -> None:
    if not isinstance(workbook, dict) or workbook.get("schema") != 1 or workbook.get("kind") != "kevin-xlsx-spec":
        raise InvocationError("WORKBOOK_INVALID")
    sheets = workbook.get("sheets")
    if not isinstance(sheets, list) or not (1 <= len(sheets) <= 5):
        raise InvocationError("WORKBOOK_SHEETS_INVALID")
    chars = 0
    for sheet in sheets:
        if not isinstance(sheet, dict):
            raise InvocationError("WORKBOOK_SHEET_INVALID")
        name = sheet.get("name")
        if not isinstance(name, str) or not name or len(name) > 31 or any(ch in name for ch in '\\/*?:[]'):
            raise InvocationError("WORKBOOK_SHEET_NAME_INVALID")
        rows = sheet.get("rows")
        if not isinstance(rows, list) or len(rows) > 200:
            raise InvocationError("WORKBOOK_ROW_CAP")
        for row in rows:
            if not isinstance(row, list) or len(row) > 16:
                raise InvocationError("WORKBOOK_COLUMN_CAP")
            chars += sum(len(str(cell)) for cell in row)
    if chars > 120000:
        raise InvocationError("WORKBOOK_CONTENT_CAP")


def validate_step(step: Any) -> None:
    if not isinstance(step, dict) or step.get("operation") not in ALLOWED_PRIMITIVES:
        raise InvocationError("STEP_PRIMITIVE_NOT_INVOCATION_ALLOWLISTED")
    op = step["operation"]
    payload = step.get("payload")
    if not isinstance(payload, dict):
        raise InvocationError("PAYLOAD_MISSING")
    if op == "create_text":
        validate_filename(payload.get("filename"), SAFE_EXTENSIONS[op])
        content = payload.get("content")
        if not isinstance(content, str) or len(content) > 60000 or "\x00" in content:
            raise InvocationError("TEXT_CONTENT_INVALID")
    else:
        validate_filename(payload.get("filename"), SAFE_EXTENSIONS[op])
        validate_workbook(payload.get("workbook"))


def validate_request(request: Dict[str, Any]) -> None:
    if request.get("schema") != 1 or request.get("kind") != "kevin-proven-skill-invocation":
        raise InvocationError("INVOCATION_REQUEST_INVALID_SCHEMA")
    if request.get("authority") != "GREEN":
        raise InvocationError("INVOCATION_AUTHORITY_NOT_GREEN")
    if not isinstance(request.get("skill_key"), str) or not SKILL_KEY_RE.fullmatch(request["skill_key"]):
        raise InvocationError("INVOCATION_SKILL_KEY_INVALID")
    if not isinstance(request.get("invocation_id"), str) or not ID_RE.fullmatch(request["invocation_id"]):
        raise InvocationError("INVOCATION_ID_INVALID")
    steps = request.get("steps")
    if not isinstance(steps, list) or not (1 <= len(steps) <= 12):
        raise InvocationError("INVOCATION_STEP_COUNT_INVALID")
    for step in steps:
        validate_step(step)


def find_entry(registry: Dict[str, Any], skill_key: str) -> Dict[str, Any]:
    matches = [entry for entry in registry["skills"] if entry["key"] == skill_key]
    if len(matches) != 1:
        raise InvocationError("PROVEN_SKILL_NOT_FOUND")
    return matches[0]


def validate_preserved_proof(entry: Dict[str, Any], proof: Dict[str, Any]) -> None:
    if proof.get("schema") != 1 or proof.get("kind") != "kevin-composite-skill-run" or proof.get("status") != "PROVEN":
        raise InvocationError("PRESERVED_PROOF_NOT_PROVEN")
    manifest = proof.get("manifest")
    if not isinstance(manifest, dict):
        raise InvocationError("PRESERVED_PROOF_MANIFEST_MISSING")
    if sha256_obj(manifest) != entry["manifest_sha256"] or proof.get("manifest_sha256") != entry["manifest_sha256"]:
        raise InvocationError("PRESERVED_PROOF_MANIFEST_MISMATCH")
    if proof.get("proof_sha256") != entry["proof_sha256"]:
        raise InvocationError("PRESERVED_PROOF_IDENTITY_MISMATCH")
    if not valid_timestamp(proof.get("completed_at")):
        raise InvocationError("PRESERVED_PROOF_TIMESTAMP_INVALID")
    results = proof.get("step_results")
    original_steps = manifest.get("steps")
    if not isinstance(results, list) or not isinstance(original_steps, list) or len(results) != len(original_steps):
        raise InvocationError("PRESERVED_PROOF_INCOMPLETE")
    if [s.get("operation") for s in original_steps] != entry["primitive_steps"]:
        raise InvocationError("PRESERVED_PROOF_PRIMITIVE_MISMATCH")


def bind_request_to_proof(entry: Dict[str, Any], proof: Dict[str, Any], request: Dict[str, Any]) -> None:
    requested = [step["operation"] for step in request["steps"]]
    if requested != entry["primitive_steps"] or requested != [step["operation"] for step in proof["manifest"]["steps"]]:
        raise InvocationError("INVOCATION_PRIMITIVE_SEQUENCE_MISMATCH")


def make_order(request: Dict[str, Any], index: int, step: Dict[str, Any]) -> Dict[str, Any]:
    iid, key = request["invocation_id"], request["skill_key"]
    return {"schema": 1, "kind": "kevin-green-work-order", "id": f"invoke-{iid}-s{index+1:02d}", "semantic_key": f"invoke:{key}:{iid}:step:{index+1}", "authority": "GREEN", "operation": step["operation"], "payload": copy.deepcopy(step["payload"])}


def stage(registry_path: Path, proof_root: Path, request_path: Path, state_path: Path, queue_ready: Path) -> Dict[str, Any]:
    registry = read_json(registry_path); validate_registry(registry)
    request = read_json(request_path); validate_request(request)
    entry = find_entry(registry, request["skill_key"])
    proof = read_json(proof_root / entry["result_file"]); validate_preserved_proof(entry, proof)
    bind_request_to_proof(entry, proof, request)
    request_hash = sha256_obj(request)
    if state_path.exists():
        old = read_json(state_path)
        if old.get("request_sha256") != request_hash:
            raise InvocationError("INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST")
        return old
    orders = [make_order(request, i, step) for i, step in enumerate(request["steps"])]
    for order in orders:
        target = queue_ready / f'{order["id"]}.json'
        if target.exists():
            if sha256_obj(read_json(target)) != sha256_obj(order):
                raise InvocationError("WORK_ORDER_ID_COLLISION")
        else:
            atomic_write_json(target, order)
    state = {"schema": 1, "kind": "kevin-proven-skill-invocation-run", "version": VERSION, "status": "RUNNING", "authority": "GREEN", "started_at": now_iso(), "invocation_id": request["invocation_id"], "skill_key": request["skill_key"], "proven_identity": {"manifest_sha256": entry["manifest_sha256"], "proof_sha256": entry["proof_sha256"], "result_file": entry["result_file"], "primitive_steps": copy.deepcopy(entry["primitive_steps"]), "proven_at": entry["proven_at"]}, "request_sha256": request_hash, "orders": [{"index": i, "id": order["id"], "semantic_key": order["semantic_key"], "operation": order["operation"], "payload_sha256": sha256_obj(order["payload"]), "order_sha256": sha256_obj(order)} for i, order in enumerate(orders)], "step_results": []}
    atomic_write_json(state_path, state)
    return state


def locate_final(order_id: str, queue_done: Path, queue_failed: Path) -> Tuple[str, Dict[str, Any]]:
    hits = [(state, path) for state, path in (("DONE", queue_done / f"{order_id}.json"), ("FAILED", queue_failed / f"{order_id}.json")) if path.exists()]
    if len(hits) > 1:
        raise InvocationError("DUPLICATE_FINAL_ORDER_RECORD")
    return ("PENDING", {}) if not hits else (hits[0][0], read_json(hits[0][1]))


def validate_final(expected: Dict[str, Any], record: Dict[str, Any], final_state: str) -> Dict[str, Any]:
    expected_fields = {"schema": 1, "kind": "kevin-green-work-order", "id": expected["id"], "semantic_key": expected["semantic_key"], "authority": "GREEN", "operation": expected["operation"]}
    if any(record.get(k) != v for k, v in expected_fields.items()) or sha256_obj(record.get("payload")) != expected["payload_sha256"]:
        raise InvocationError("FINAL_ORDER_CORRELATION_MISMATCH")
    if record.get("status") != final_state:
        raise InvocationError("FINAL_ORDER_STATUS_MISMATCH")
    result = record.get("result")
    if final_state == "DONE":
        if not isinstance(result, dict) or result.get("status") != "DONE" or not valid_timestamp(result.get("completed_at")):
            raise InvocationError("DONE_RESULT_INVALID")
        if not isinstance(result.get("output_name"), str) or not result["output_name"] or not isinstance(result.get("bytes"), int) or result["bytes"] < 0 or not isinstance(result.get("sha256"), str) or not HASH_RE.fullmatch(result["sha256"]):
            raise InvocationError("DONE_RESULT_EVIDENCE_INVALID")
        return result
    failure = record.get("failure")
    if not isinstance(failure, dict):
        raise InvocationError("FAILED_RESULT_EVIDENCE_INVALID")
    return failure


def reconcile(state_path: Path, queue_done: Path, queue_failed: Path, receipt_path: Path) -> Dict[str, Any]:
    if receipt_path.exists():
        receipt = read_json(receipt_path)
        if receipt.get("status") not in {"PROVEN", "FAILED"}:
            raise InvocationError("EXISTING_RECEIPT_INVALID")
        return receipt
    state = read_json(state_path)
    if state.get("schema") != 1 or state.get("kind") != "kevin-proven-skill-invocation-run" or state.get("status") != "RUNNING":
        raise InvocationError("INVOCATION_STATE_INVALID")
    results: List[Dict[str, Any]] = []
    failed = None
    for expected in state.get("orders", []):
        final_state, record = locate_final(expected["id"], queue_done, queue_failed)
        if final_state == "PENDING":
            return state
        evidence = validate_final(expected, record, final_state)
        item = {"index": expected["index"], "order_id": expected["id"], "semantic_key": expected["semantic_key"], "operation": expected["operation"], "final_state": final_state, "order_record_sha256": sha256_obj(record), "completed_at": evidence.get("completed_at", ""), "output_name": evidence.get("output_name", ""), "sha256": evidence.get("sha256", ""), "bytes": evidence.get("bytes", 0)}
        results.append(item)
        if final_state == "FAILED" and failed is None:
            failed = item
    receipt = {"schema": 1, "kind": "kevin-proven-skill-invocation-receipt", "version": VERSION, "status": "FAILED" if failed else "PROVEN", "authority": "GREEN", "completed_at": now_iso(), "invocation_id": state["invocation_id"], "skill_key": state["skill_key"], "proven_identity": copy.deepcopy(state["proven_identity"]), "request_sha256": state["request_sha256"], "step_results": results, "failure": failed}
    receipt["receipt_sha256"] = sha256_obj(receipt)
    atomic_write_json(receipt_path, receipt)
    state.update(status=receipt["status"], completed_at=receipt["completed_at"], receipt_sha256=receipt["receipt_sha256"], step_results=results)
    atomic_write_json(state_path, state)
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__); sub = parser.add_subparsers(dest="command", required=True)
    ps = sub.add_parser("stage"); ps.add_argument("--registry", required=True); ps.add_argument("--proof-root", required=True); ps.add_argument("--request", required=True); ps.add_argument("--state", required=True); ps.add_argument("--queue-ready", required=True)
    pr = sub.add_parser("reconcile"); pr.add_argument("--state", required=True); pr.add_argument("--queue-done", required=True); pr.add_argument("--queue-failed", required=True); pr.add_argument("--receipt", required=True)
    args = parser.parse_args()
    try:
        out = stage(Path(args.registry), Path(args.proof_root), Path(args.request), Path(args.state), Path(args.queue_ready)) if args.command == "stage" else reconcile(Path(args.state), Path(args.queue_done), Path(args.queue_failed), Path(args.receipt))
        print(json.dumps(out, indent=2)); return 0
    except InvocationError as exc:
        print(json.dumps({"status": "REJECTED", "reason": str(exc)})); return 2


if __name__ == "__main__":
    raise SystemExit(main())
