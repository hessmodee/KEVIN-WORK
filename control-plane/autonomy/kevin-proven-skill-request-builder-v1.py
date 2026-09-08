#!/usr/bin/env python3
"""Build a GREEN proven-skill invocation request from bounded owner inputs.

Authority delta: NONE. This builder cannot add primitives, place purchases,
include customer PII, or invent live vendor/quote facts. It only shapes already
authorized fictional/example data into Invocation v1's allowlisted payloads.
"""
from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path
from typing import Any, Dict, List

VERSION = "1.0.0"
PARTS_CHASE_KEY = "west-motor-parts-chase-board-pack@1"
REQUIRED_FIELDS = (
    "priority",
    "stock_number",
    "part_need",
    "vendor_source",
    "ordered_date",
    "eta",
    "blocker",
    "owner",
    "next_action",
    "completion_state",
)
HEADER = [
    "Priority",
    "Stock Number",
    "Part / Need",
    "Vendor / Source",
    "Ordered Date",
    "ETA",
    "Blocker",
    "Owner",
    "Next Action",
    "Completion State",
]


class BuilderError(RuntimeError):
    pass


def fictional_eight_vehicles() -> List[Dict[str, str]]:
    return [
        {"priority": "HIGH", "stock_number": "WM-EX-1001", "part_need": "Driver-side mirror glass", "vendor_source": "Example Auto Glass Co", "ordered_date": "2026-09-03", "eta": "2026-09-09", "blocker": "Backorder", "owner": "Recon", "next_action": "Confirm ETA with example vendor", "completion_state": "OPEN"},
        {"priority": "HIGH", "stock_number": "WM-EX-1002", "part_need": "Rear brake pad set", "vendor_source": "Example OEM Parts Desk", "ordered_date": "2026-09-04", "eta": "2026-09-08", "blocker": "Awaiting delivery", "owner": "Service", "next_action": "Check dock in the morning", "completion_state": "ORDERED"},
        {"priority": "MED", "stock_number": "WM-EX-1003", "part_need": "Tailgate handle assembly", "vendor_source": "Example Body Supply", "ordered_date": "2026-09-02", "eta": "2026-09-11", "blocker": "Paint match pending", "owner": "Body", "next_action": "Hold install until color is confirmed", "completion_state": "OPEN"},
        {"priority": "MED", "stock_number": "WM-EX-1004", "part_need": "Cabin air filter", "vendor_source": "Example Local Jobber", "ordered_date": "2026-09-05", "eta": "2026-09-06", "blocker": "None", "owner": "Detail", "next_action": "Install on arrival", "completion_state": "ORDERED"},
        {"priority": "LOW", "stock_number": "WM-EX-1005", "part_need": "Wheel-lock key", "vendor_source": "Example Dealer Stock", "ordered_date": "2026-09-01", "eta": "2026-09-07", "blocker": "Internal transfer", "owner": "Parts", "next_action": "Pull from example shelf bin", "completion_state": "OPEN"},
        {"priority": "HIGH", "stock_number": "WM-EX-1006", "part_need": "Radiator upper hose", "vendor_source": "Example Cooling Supply", "ordered_date": "2026-09-04", "eta": "2026-09-10", "blocker": "Freight", "owner": "Service", "next_action": "Track example freight number", "completion_state": "ORDERED"},
        {"priority": "MED", "stock_number": "WM-EX-1007", "part_need": "Backup-camera pigtail", "vendor_source": "Example Electrical", "ordered_date": "2026-09-05", "eta": "2026-09-12", "blocker": "Special order", "owner": "Electrical", "next_action": "Call if not scanned by Friday", "completion_state": "OPEN"},
        {"priority": "LOW", "stock_number": "WM-EX-1008", "part_need": "Spare key fob battery", "vendor_source": "Example Counter Stock", "ordered_date": "2026-09-06", "eta": "2026-09-06", "blocker": "None", "owner": "Delivery", "next_action": "Install before example delivery rehearsal", "completion_state": "RECEIVED"},
    ]


def validate_vehicles(rows: List[Dict[str, str]]) -> None:
    if not isinstance(rows, list) or len(rows) != 8:
        raise BuilderError("VEHICLE_COUNT_MUST_BE_8")
    stocks = []
    for row in rows:
        if not isinstance(row, dict):
            raise BuilderError("VEHICLE_ROW_INVALID")
        missing = [field for field in REQUIRED_FIELDS if not str(row.get(field, "")).strip()]
        if missing:
            raise BuilderError("MISSING_FIELDS:" + ",".join(missing))
        stock = str(row["stock_number"]).strip()
        if stock in stocks:
            raise BuilderError("DUPLICATE_STOCK")
        stocks.append(stock)
        blob = " ".join(str(row[field]) for field in REQUIRED_FIELDS).lower()
        for banned in ("ssn", "password", "secret", "live customer", "vin "):
            if banned in blob:
                raise BuilderError("FORBIDDEN_CONTENT")


def operating_note(rows: List[Dict[str, str]]) -> str:
    open_count = sum(1 for row in rows if str(row["completion_state"]).upper() in {"OPEN", "ORDERED"})
    return (
        "# West Motor Parts Chase — fictional operating note\n\n"
        "This board is a GREEN example run using eight fictional dealership vehicles.\n"
        "Do not treat stock numbers, vendors, dates, or ETAs as live customer, DMS, or purchase data.\n\n"
        "## How to use it\n"
        "1. Sort by Priority, then ETA.\n"
        "2. Work OPEN/ORDERED rows before RECEIVED.\n"
        "3. Update Next Action with the smallest honest chase, not a purchase.\n"
        "4. Never invent part numbers, quotes, or live vendor commitments.\n\n"
        f"## This example\n"
        f"- Vehicles: {len(rows)}\n"
        f"- Still chasing: {open_count}\n"
        f"- Generated for owner rehearsal date: {date.today().isoformat()}\n"
        "- Authority: GREEN example data only; no checkout, send, or DMS write.\n"
    )


def build_parts_chase_request(invocation_id: str, rows: List[Dict[str, str]] | None = None) -> Dict[str, Any]:
    vehicles = rows if rows is not None else fictional_eight_vehicles()
    validate_vehicles(vehicles)
    board_rows = [HEADER] + [[str(row[field]) for field in REQUIRED_FIELDS] for row in vehicles]
    return {
        "schema": 1,
        "kind": "kevin-proven-skill-invocation",
        "authority": "GREEN",
        "skill_key": PARTS_CHASE_KEY,
        "invocation_id": invocation_id,
        "steps": [
            {
                "operation": "create_spreadsheet",
                "payload": {
                    "filename": "Kevin-West-Motor-Parts-Chase-Fictional-8.xlsx",
                    "workbook": {
                        "schema": 1,
                        "kind": "kevin-xlsx-spec",
                        "sheets": [
                            {"name": "Parts Chase", "rows": board_rows},
                            {"name": "Board Legend", "rows": [
                                ["Field", "Meaning", "Rule"],
                                ["Priority", "HIGH / MED / LOW", "Do not invent urgency"],
                                ["Completion State", "OPEN / ORDERED / RECEIVED", "No auto purchase"],
                                ["Vendor / Source", "Example sources only", "Fictional in this run"],
                            ]},
                        ],
                    },
                },
            },
            {
                "operation": "create_text",
                "payload": {
                    "filename": "Kevin-West-Motor-Parts-Chase-Fictional-8-Note.md",
                    "content": operating_note(vehicles),
                },
            },
        ],
    }


def load_work_item_vehicles(path: Path, work_id: str) -> List[Dict[str, str]] | None:
    doc = json.loads(path.read_text(encoding="utf-8"))
    items = doc.get("items") if isinstance(doc, dict) else None
    if not isinstance(items, list):
        raise BuilderError("WORK_ITEMS_INVALID")
    matches = [item for item in items if isinstance(item, dict) and str(item.get("id")) == work_id]
    if len(matches) != 1:
        raise BuilderError("WORK_ITEM_NOT_UNIQUE")
    item = matches[0]
    raw = item.get("owner_inputs") or {}
    vehicles = raw.get("vehicles") if isinstance(raw, dict) else None
    if vehicles is None:
        return None
    if not isinstance(vehicles, list):
        raise BuilderError("OWNER_INPUTS_INVALID")
    return vehicles


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--invocation-id", required=True)
    parser.add_argument("--work-items", help="inbox/autonomy/work-items.json")
    parser.add_argument("--work-id")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    rows = None
    if args.work_items:
        if not args.work_id:
            raise BuilderError("WORK_ID_REQUIRED_WITH_WORK_ITEMS")
        rows = load_work_item_vehicles(Path(args.work_items), args.work_id)
    request = build_parts_chase_request(args.invocation_id, rows)
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "vehicles": 8}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BuilderError as exc:
        print(json.dumps({"status": "REJECTED", "reason": str(exc)}))
        raise SystemExit(2)
