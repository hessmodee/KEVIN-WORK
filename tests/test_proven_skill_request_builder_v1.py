import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "builder",
    ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-request-builder-v1.0.1.py",
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
        self.assertEqual(builder.VERSION, "1.0.1")


if __name__ == "__main__":
    unittest.main()
