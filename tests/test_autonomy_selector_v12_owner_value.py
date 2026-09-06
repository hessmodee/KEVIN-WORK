"""v1.2 admission: OPEN GREEN production owner-value missions must be eligible."""
from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "kevin_selector_v12", ROOT / "control-plane/autonomy/kevin-work-selector-v1.2.py"
)
selector = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = selector
SPEC.loader.exec_module(selector)
NOW = dt.datetime(2026, 9, 6, 22, 0, tzinfo=dt.timezone.utc)


def load(path):
    raw = (ROOT / path).read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    return json.loads(raw.decode("utf-8"))


WEST = {
    "id": "owner-west-motor-transport-dispatch-template-v1",
    "program": "owner-value-skills",
    "authority_class": "GREEN",
    "status": "OPEN",
    "lane": "production",
    "work_type": "execution",
    "priority": "high",
    "owner_value": 5,
    "reuses_proven_capability": True,
    "produces_owner_deliverable": True,
    "closes_proof_gap": True,
    "reduces_bess_intervention": True,
    "dependencies_ready": True,
    "blocked": False,
    "failure_attempts": 0,
    "material_new_evidence": True,
    "acceptance_criteria": [
        "Kevin independently selects this OPEN GREEN owner-value item on a scheduled work-selection cycle.",
        "Produce a useful reusable vehicle-transport dispatch workbook using proven spreadsheet/text capability.",
    ],
}


class OwnerValueAdmission(unittest.TestCase):
    def test_open_green_production_owner_value_is_selected(self):
        programs = load("control-plane/autonomy/standing-programs-v1.json")
        families = load("control-plane/autonomy/failure-families-v1.json")
        state = {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}
        inventory = {"schema": 1, "kind": "kevin-work-items", "items": [copy.deepcopy(WEST)]}
        before = copy.deepcopy((programs, inventory, state, families))
        result = selector.select(programs, inventory, state, families, NOW)
        self.assertEqual((programs, inventory, state, families), before)
        self.assertEqual(result["authority_effect"], "NONE_SELECTION_ONLY")
        self.assertEqual(result["status"], "SELECTED")
        self.assertEqual(result["eligible_count"], 1)
        self.assertEqual(result["selection"]["id"], WEST["id"])
        self.assertEqual(result["selection"]["program"], "owner-value-skills")

    def test_live_inventory_includes_west_motor_when_open(self):
        programs = load("control-plane/autonomy/standing-programs-v1.json")
        families = load("control-plane/autonomy/failure-families-v1.json")
        inventory = load("inbox/autonomy/work-items.json")
        state = load("inbox/autonomy/state.json")
        now = dt.datetime.now(dt.timezone.utc)
        result = selector.select(programs, inventory, state, families, now)
        live = [row for row in inventory.get("items", []) if row.get("id") == WEST["id"]]
        self.assertTrue(live, "seeded west-motor item missing from work-items.json")
        item = live[0]
        if str(item.get("status", "")).upper() in {"OPEN", "READY"} and item.get("blocked") is not True:
            ids = [entry["id"] for entry in result["eligible"]]
            self.assertIn(WEST["id"], ids, result)
            self.assertNotEqual(result["status"], "NO_ELIGIBLE_WORK")


if __name__ == "__main__":
    unittest.main(verbosity=2)
