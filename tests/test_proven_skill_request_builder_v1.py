import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "builder",
    ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-request-builder-v1.0.3.py",
)
builder = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(builder)

inv_spec = importlib.util.spec_from_file_location(
    "invocation",
    ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.1.1.py",
)
invocation = importlib.util.module_from_spec(inv_spec)
assert inv_spec.loader
inv_spec.loader.exec_module(invocation)


class RequestBuilderTests(unittest.TestCase):
    def test_fictional_eight_validates_and_matches_invocation_contract(self):
        request = builder.build_parts_chase_request("parts-board-fictional-8-001")
        invocation.validate_request(request)
        self.assertEqual("west-motor-parts-chase-board-pack@1", request["skill_key"])
        self.assertEqual(["create_spreadsheet", "create_text"], [step["operation"] for step in request["steps"]])
        rows = request["steps"][0]["payload"]["workbook"]["sheets"][0]["rows"]
        self.assertEqual(9, len(rows))
        self.assertEqual(builder.HEADER, rows[0])
        self.assertEqual("WM-EX-1001", rows[1][1])
        self.assertIn("fictional", request["steps"][1]["payload"]["content"].lower())

    def test_wrong_vehicle_count_refuses(self):
        rows = builder.fictional_eight_vehicles()[:7]
        with self.assertRaisesRegex(builder.BuilderError, "VEHICLE_COUNT_MUST_BE_8"):
            builder.build_parts_chase_request("bad-count-001", rows)

    def test_work_item_owner_inputs_round_trip(self):
        request = builder.build_parts_chase_request("parts-board-fictional-8-002")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            path.write_text(json.dumps({
                "schema": 1,
                "kind": "kevin-work-items",
                "items": [{
                    "id": "owner-west-motor-parts-chase-fresh-8-v1",
                    "required_skill_key": "west-motor-parts-chase-board-pack@1",
                    "owner_inputs": {"vehicles": builder.fictional_eight_vehicles()},
                }],
            }), encoding="utf-8")
            loaded = builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual(8, len(loaded))
            rebuilt = builder.build_parts_chase_request("parts-board-fictional-8-002", loaded)
            self.assertEqual(request["skill_key"], rebuilt["skill_key"])

    def test_operating_note_is_deterministic(self):
        first = builder.build_parts_chase_request("parts-board-fictional-8-det")
        second = builder.build_parts_chase_request("parts-board-fictional-8-det")
        self.assertEqual(first["steps"][1]["payload"]["content"], second["steps"][1]["payload"]["content"])
        self.assertNotIn("rehearsal date:", first["steps"][1]["payload"]["content"])
        self.assertEqual(invocation.sha256_obj(first), invocation.sha256_obj(second))
        self.assertEqual(builder.VERSION, "1.0.3")

    def test_utf8_bom_work_items_loads(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            body = json.dumps({
                "schema": 1,
                "kind": "kevin-work-items",
                "items": [{
                    "id": "owner-west-motor-parts-chase-fresh-8-v1",
                    "required_skill_key": "west-motor-parts-chase-board-pack@1",
                    "owner_inputs": {"vehicles": builder.fictional_eight_vehicles()},
                }],
            }).encode("utf-8")
            path.write_bytes(b"\xef\xbb\xbf" + body)
            loaded = builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual(8, len(loaded))

    def test_unreadable_work_items_is_builder_error_not_traceback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            path.write_bytes(b"\xef\xbb\xbf{not-json")
            with self.assertRaisesRegex(builder.BuilderError, "WORK_ITEMS_UNREADABLE"):
                builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")

    def test_missing_work_item_is_not_found_not_unique(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            path.write_text(json.dumps({"schema": 1, "kind": "kevin-work-items", "items": []}), encoding="utf-8")
            with self.assertRaises(builder.BuilderError) as ctx:
                builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual("WORK_ITEM_NOT_FOUND", ctx.exception.reason)
            self.assertEqual(0, ctx.exception.extra["match_count"])
            self.assertEqual(0, ctx.exception.extra["items_count"])

    def test_duplicate_work_item_is_unique_error_with_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            item = {
                "id": "owner-west-motor-parts-chase-fresh-8-v1",
                "status": "OPEN",
                "blocked": False,
                "required_skill_key": "west-motor-parts-chase-board-pack@1",
                "owner_inputs": {"vehicles": builder.fictional_eight_vehicles()},
            }
            path.write_text(json.dumps({"schema": 1, "items": [item, dict(item), {"id": "other"}]}), encoding="utf-8")
            with self.assertRaises(builder.BuilderError) as ctx:
                builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual("WORK_ITEM_NOT_UNIQUE", ctx.exception.reason)
            self.assertEqual(2, ctx.exception.extra["match_count"])
            self.assertEqual(3, ctx.exception.extra["items_count"])

    def test_repair_inserts_canonical_when_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            path.write_text(json.dumps({
                "schema": 1,
                "kind": "kevin-work-items",
                "items": [{"id": "other", "status": "OPEN"}],
            }), encoding="utf-8")
            result = builder.repair_work_item_uniqueness(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual("INSERTED_CANONICAL", result["reason"])
            self.assertEqual(0, result["match_count_before"])
            self.assertEqual(1, result["match_count_after"])
            loaded = builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual(8, len(loaded))
            doc = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual("other", doc["items"][0]["id"])

    def test_repair_dedupes_keeping_eight_vehicle_open_copy(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            weak = {"id": "owner-west-motor-parts-chase-fresh-8-v1", "status": "COMPLETE", "owner_inputs": {}}
            strong = {
                "id": "owner-west-motor-parts-chase-fresh-8-v1",
                "status": "OPEN",
                "blocked": False,
                "required_skill_key": "west-motor-parts-chase-board-pack@1",
                "owner_inputs": {"vehicles": builder.fictional_eight_vehicles()},
            }
            other = {"id": "owner-west-motor-transport-dispatch-template-v1", "status": "OPEN"}
            path.write_text(json.dumps({"schema": 1, "items": [weak, other, strong]}), encoding="utf-8")
            archive = Path(tmp) / "archive"
            result = builder.repair_work_item_uniqueness(path, "owner-west-motor-parts-chase-fresh-8-v1", archive)
            self.assertEqual("DEDUPED_KEEP_BEST", result["reason"])
            self.assertEqual(2, result["match_count_before"])
            self.assertEqual(1, result["match_count_after"])
            self.assertEqual(1, result["archived"])
            loaded = builder.load_work_item_vehicles(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual(8, len(loaded))
            doc = json.loads(path.read_text(encoding="utf-8"))
            ids = [item["id"] for item in doc["items"]]
            self.assertEqual(["owner-west-motor-parts-chase-fresh-8-v1", "owner-west-motor-transport-dispatch-template-v1"], ids)
            self.assertTrue(list(archive.glob("work-items-duplicate-archive-*.json")))

    def test_repair_already_unique_is_noop(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "work-items.json"
            original = json.dumps({
                "schema": 1,
                "items": [{
                    "id": "owner-west-motor-parts-chase-fresh-8-v1",
                    "required_skill_key": "west-motor-parts-chase-board-pack@1",
                    "owner_inputs": {"vehicles": builder.fictional_eight_vehicles()},
                }],
            })
            path.write_text(original, encoding="utf-8")
            result = builder.repair_work_item_uniqueness(path, "owner-west-motor-parts-chase-fresh-8-v1")
            self.assertEqual("ALREADY_UNIQUE", result["reason"])
            self.assertEqual(original, path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
