#!/usr/bin/env python3
"""Make one evidence-backed material transition: West Motor owner work OPEN -> READY.

This is deliberately narrow. It does not reset Supervisor history, alter attempts,
mark work complete, change authority, or touch any other work item field.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path

PATH = Path("inbox/autonomy/work-items.json")
TARGET = "owner-west-motor-transport-dispatch-template-v1"


def main() -> int:
    data = json.loads(PATH.read_text(encoding="utf-8-sig"))
    if data.get("schema") != 1 or data.get("kind") != "kevin-work-items" or data.get("safe_for_public_repo") is not True:
        raise SystemExit("work catalog contract mismatch")
    items = data.get("items")
    if not isinstance(items, list):
        raise SystemExit("work catalog items missing")
    hits = [item for item in items if item.get("id") == TARGET]
    if len(hits) != 1:
        raise SystemExit(f"expected exactly one target item, found {len(hits)}")
    item = hits[0]

    exact_preconditions = {
        "program": "owner-value-skills",
        "authority_class": "GREEN",
        "status": "OPEN",
        "lane": "production",
        "work_type": "execution",
        "priority": "high",
        "owner_value": 5,
        "dependencies_ready": True,
        "blocked": False,
        "failure_attempts": 0,
        "material_new_evidence": True,
    }
    for key, expected in exact_preconditions.items():
        if item.get(key) != expected:
            raise SystemExit(f"target precondition mismatch {key}: {item.get(key)!r} != {expected!r}")
    if item.get("produces_owner_deliverable") is not True or item.get("reuses_proven_capability") is not True:
        raise SystemExit("target is not a qualified owner deliverable using proven capability")
    criteria = item.get("acceptance_criteria") or []
    if not any("vehicle-transport dispatch workbook" in str(x) for x in criteria):
        raise SystemExit("target acceptance contract changed")

    before = copy.deepcopy(data)
    item["status"] = "READY"

    # Semantic one-leaf proof: construct the only permitted after-state from the
    # untouched before object and require exact equality.
    expected_after = copy.deepcopy(before)
    expected_hits = [x for x in expected_after["items"] if x.get("id") == TARGET]
    expected_hits[0]["status"] = "READY"
    if data != expected_after:
        raise SystemExit("mutation escaped the one-leaf OPEN->READY boundary")

    PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print("OWNER_WORK_READY_TRANSITION_PROVEN target=%s from=OPEN to=READY history_reset=false completion=false authority_delta=NONE" % TARGET)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
