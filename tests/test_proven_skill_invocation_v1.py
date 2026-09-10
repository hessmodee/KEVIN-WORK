import copy
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Catalog-contract repair lives on the versioned file so historical
# Maintenance pins on kevin-proven-skill-invocation-v1.py stay 63FA334B.
MOD_PATH = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.1.1.py"
spec = importlib.util.spec_from_file_location("kevin_proven_skill_invocation_v1", MOD_PATH)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class ProvenSkillInvocationV1Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.registry_path = self.root / "reports" / "capabilities" / "composite-skills.json"
        self.proof_root = self.root / "reports" / "action-era" / "skills" / "done"
        self.request_path = self.root / "request.json"
        self.state_path = self.root / "reports" / "invocations" / "runs" / "run-001.json"
        self.receipt_path = self.root / "reports" / "invocations" / "done" / "run-001.json"
        self.ready = self.root / "reports" / "action-era" / "queue" / "ready"
        self.done = self.root / "reports" / "action-era" / "queue" / "done"
        self.failed = self.root / "reports" / "action-era" / "queue" / "failed"
        self.artifacts = self.root / "reports" / "invocations" / "artifacts"
        for p in (self.registry_path.parent, self.proof_root, self.ready, self.done, self.failed, self.artifacts):
            p.mkdir(parents=True, exist_ok=True)

        self.manifest = {
            "schema": 1,
            "kind": "kevin-composite-skill",
            "id": "west-motor-parts-chase-board-pack",
            "version": "1",
            "authority": "GREEN",
            "name": "West Motor Parts Chase Board Pack",
            "steps": [
                {"operation": "create_spreadsheet", "payload": {"filename": "qualification.xlsx", "workbook": {"schema": 1, "kind": "kevin-xlsx-spec", "sheets": [{"name": "Board", "rows": [["Stock", "Need"], ["EXAMPLE", "Part"]]}]}}},
                {"operation": "create_text", "payload": {"filename": "qualification.md", "content": "Qualification note"}},
            ],
        }
        manifest_hash = mod.sha256_obj(self.manifest)
        proof_hash = "A" * 64
        self.proof_file = "west-motor-parts-chase-board-pack--1.json"
        self.proof = {
            "schema": 1,
            "kind": "kevin-composite-skill-run",
            "status": "PROVEN",
            "completed_at": "2026-09-04T23:29:21-06:00",
            "manifest": self.manifest,
            "manifest_sha256": manifest_hash,
            "proof_sha256": proof_hash,
            "step_results": [{"step_index": 0}, {"step_index": 1}],
        }
        self.registry = {
            "schema": 1,
            "kind": "kevin-composite-skill-registry",
            "updated_at": "2026-09-07T21:00:00-06:00",
            "skills": [{
                "id": self.manifest["id"],
                "version": "1",
                "key": self.manifest["id"] + "@1",
                "authority": "GREEN",
                "status": "PROVEN",
                "name": self.manifest["name"],
                "manifest_sha256": manifest_hash,
                "proof_sha256": proof_hash,
                "proven_at": self.proof["completed_at"],
                "primitive_steps": ["create_spreadsheet", "create_text"],
                "result_file": self.proof_file,
            }],
        }
        self.request = {
            "schema": 1,
            "kind": "kevin-proven-skill-invocation",
            "authority": "GREEN",
            "skill_key": self.manifest["id"] + "@1",
            "invocation_id": "parts-board-fictional-8-001",
            "steps": [
                {"operation": "create_spreadsheet", "payload": {"filename": "fresh-parts-board.xlsx", "workbook": {"schema": 1, "kind": "kevin-xlsx-spec", "sheets": [{"name": "Parts Chase", "rows": [["Priority", "Stock", "Need", "Vendor", "ETA"], ["High", "F100", "Mirror", "Example Vendor", "Tomorrow"]]}]}}},
                {"operation": "create_text", "payload": {"filename": "fresh-parts-board-note.md", "content": "Fresh fictional operating note."}},
            ],
        }
        self.write(self.registry_path, self.registry)
        self.write(self.proof_root / self.proof_file, self.proof)
        self.write(self.request_path, self.request)

    def tearDown(self):
        self.tmp.cleanup()

    @staticmethod
    def write(path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

    def stage(self):
        return mod.stage(self.registry_path, self.proof_root, self.request_path, self.state_path, self.ready)

    def make_done(self, order_meta):
        ready_path = self.ready / f'{order_meta["id"]}.json'
        order = json.loads(ready_path.read_text(encoding="utf-8"))
        name = order["payload"]["filename"]
        data = b"fictional-verified-artifact:" + name.encode("utf-8")
        artifact = self.artifacts / name
        artifact.write_bytes(data)
        digest = mod.sha256_file(artifact)
        order["status"] = "DONE"
        order["result"] = {
            "status": "DONE",
            "completed_at": "2026-09-08T03:00:00Z",
            "output_name": name,
            "sha256": digest,
            "bytes": len(data),
        }
        self.write(self.done / ready_path.name, order)

    def test_stage_and_reconcile_fresh_run(self):
        state = self.stage()
        self.assertEqual("RUNNING", state["status"])
        self.assertEqual(2, len(state["orders"]))
        self.assertTrue(all(x["id"].startswith("invoke-parts-board-fictional-8-001-") for x in state["orders"]))
        for order in state["orders"]:
            self.make_done(order)
        receipt = mod.reconcile(self.state_path, self.done, self.failed, self.receipt_path, self.artifacts)
        self.assertEqual("PROVEN", receipt["status"])
        self.assertEqual(self.registry["skills"][0]["manifest_sha256"], receipt["proven_identity"]["manifest_sha256"])
        self.assertEqual(self.registry["skills"][0]["proof_sha256"], receipt["proven_identity"]["proof_sha256"])
        self.assertRegex(receipt["receipt_sha256"], r"^[A-F0-9]{64}$")
        self.assertTrue(all(r["verified_sha256"] == r["sha256"] for r in receipt["step_results"]))

    def test_same_invocation_is_idempotent(self):
        first = self.stage()
        second = self.stage()
        self.assertEqual(first["request_sha256"], second["request_sha256"])
        self.assertEqual(2, len(list(self.ready.glob("*.json"))))

    def test_reused_invocation_id_with_different_request_refuses(self):
        self.stage()
        changed = copy.deepcopy(self.request)
        changed["steps"][1]["payload"]["content"] = "Different content"
        self.write(self.request_path, changed)
        with self.assertRaisesRegex(mod.InvocationError, "INVOCATION_ID_REUSED_WITH_DIFFERENT_REQUEST"):
            self.stage()

    def test_catalog_sibling_notepad_does_not_block_parts_chase(self):
        sibling = {
            "id": "kevin-ui-recovery-functional-proof",
            "version": "1",
            "key": "kevin-ui-recovery-functional-proof@1",
            "authority": "GREEN",
            "status": "PROVEN",
            "name": "UI recovery functional proof",
            "manifest_sha256": "B" * 64,
            "proof_sha256": "C" * 64,
            "proven_at": "2026-09-04T08:00:00-06:00",
            "primitive_steps": "ui_notepad_write",
            "result_file": "kevin-ui-recovery-functional-proof--1.json",
        }
        one_step = dict(self.registry["skills"][0])
        one_step["id"] = "watchtower-create-text-proof"
        one_step["key"] = "watchtower-create-text-proof@1"
        one_step["primitive_steps"] = "create_text"
        one_step["result_file"] = "watchtower-create-text-proof--1.json"
        one_step["manifest_sha256"] = "D" * 64
        one_step["proof_sha256"] = "E" * 64
        self.registry["skills"] = [sibling, one_step, self.registry["skills"][0]]
        self.write(self.registry_path, self.registry)
        state = self.stage()
        self.assertEqual("RUNNING", state["status"])
        self.assertEqual("west-motor-parts-chase-board-pack@1", state["skill_key"])

    def test_target_notepad_skill_is_not_invocation_v1(self):
        self.registry["skills"][0]["primitive_steps"] = ["create_spreadsheet", "ui_notepad_write"]
        self.write(self.registry_path, self.registry)
        with self.assertRaisesRegex(mod.InvocationError, "SKILL_NOT_INVOCATION_V1_COMPATIBLE"):
            self.stage()

    def test_unknown_or_unproven_skill_refuses(self):

        changed = copy.deepcopy(self.request)
        changed["skill_key"] = "unknown-skill@1"
        self.write(self.request_path, changed)
        with self.assertRaisesRegex(mod.InvocationError, "PROVEN_SKILL_NOT_FOUND"):
            self.stage()

    def test_proof_identity_mismatch_refuses(self):
        bad = copy.deepcopy(self.proof)
        bad["proof_sha256"] = "C" * 64
        self.write(self.proof_root / self.proof_file, bad)
        with self.assertRaisesRegex(mod.InvocationError, "PRESERVED_PROOF_IDENTITY_MISMATCH"):
            self.stage()

    def test_primitive_sequence_change_refuses(self):
        changed = copy.deepcopy(self.request)
        changed["steps"].reverse()
        self.write(self.request_path, changed)
        with self.assertRaisesRegex(mod.InvocationError, "INVOCATION_PRIMITIVE_SEQUENCE_MISMATCH"):
            self.stage()

    def test_path_escape_and_unreviewed_primitive_refuse(self):
        changed = copy.deepcopy(self.request)
        changed["steps"][1]["payload"]["filename"] = "../escape.md"
        self.write(self.request_path, changed)
        with self.assertRaisesRegex(mod.InvocationError, "FILENAME_INVALID"):
            self.stage()
        changed = copy.deepcopy(self.request)
        changed["steps"][1] = {"operation": "shell", "payload": {"filename": "x.txt", "content": "whoami"}}
        self.write(self.request_path, changed)
        with self.assertRaisesRegex(mod.InvocationError, "STEP_PRIMITIVE_NOT_INVOCATION_ALLOWLISTED"):
            self.stage()

    def test_tampered_done_record_refuses_receipt(self):
        state = self.stage()
        for order in state["orders"]:
            self.make_done(order)
        target = self.done / f'{state["orders"][0]["id"]}.json'
        tampered = json.loads(target.read_text(encoding="utf-8"))
        tampered["payload"]["filename"] = "tampered.xlsx"
        self.write(target, tampered)
        with self.assertRaisesRegex(mod.InvocationError, "FINAL_ORDER_CORRELATION_MISMATCH"):
            mod.reconcile(self.state_path, self.done, self.failed, self.receipt_path, self.artifacts)

    def test_versioned_repair_identity(self):
        self.assertEqual(mod.VERSION, "1.1.1")
        self.assertIn("ui_notepad_write", mod.CATALOG_PRIMITIVES)
        self.assertNotIn("ui_notepad_write", mod.ALLOWED_PRIMITIVES)


if __name__ == "__main__":
    unittest.main()
