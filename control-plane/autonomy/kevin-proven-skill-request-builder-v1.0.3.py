#!/usr/bin/env python3
"""Build a GREEN proven-skill invocation request from bounded owner inputs.

Authority delta: NONE. This builder cannot add primitives, place purchases,
include customer PII, or invent live vendor/quote facts. It only shapes already
authorized fictional/example data into Invocation v1's allowlisted payloads.

v1.0.3: split WORK_ITEM_NOT_FOUND (0) vs WORK_ITEM_NOT_UNIQUE (2+), emit
match_count, and --repair-unique so Kevin can heal a diverged local
work-items.json without resetting history.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

VERSION = "1.0.3"
PARTS_CHASE_KEY = "west-motor-parts-chase-board-pack@1"
PARTS_CHASE_WORK_ID = "owner-west-motor-parts-chase-fresh-8-v1"
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
    def __init__(self, reason: str, extra: Dict[str, Any] | None = None) -> None:
        super().__init__(reason)
        self.reason = reason
        self.extra = extra or {}


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
        "- Generated for owner rehearsal: fictional eight-vehicle GREEN example.\n"
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


def read_json_doc(path: Path):
    """Read JSON, stripping a UTF-8 BOM. PowerShell ConvertTo-Json writes BOM."""
    try:
        raw = path.read_bytes()
    except OSError as exc:
        raise BuilderError("WORK_ITEMS_UNREADABLE") from exc
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    try:
        return json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        msg = str(exc)
        if "BOM" in msg or "utf-8 bom" in msg.lower():
            raise BuilderError("WORK_ITEMS_UTF8_BOM") from exc
        raise BuilderError("WORK_ITEMS_UNREADABLE") from exc
    except UnicodeDecodeError as exc:
        raise BuilderError("WORK_ITEMS_UNREADABLE") from exc


def write_json_doc(path: Path, doc: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes((json.dumps(doc, indent=2) + "\n").encode("utf-8"))


def match_work_items(items: List[Any], work_id: str) -> List[Dict[str, Any]]:
    return [item for item in items if isinstance(item, dict) and str(item.get("id")) == work_id]


def uniqueness_extra(work_id: str, items: List[Any], matches: List[Any]) -> Dict[str, Any]:
    return {
        "work_id": work_id,
        "match_count": len(matches),
        "items_count": len(items),
        "builder_version": VERSION,
    }


def load_work_item_vehicles(path: Path, work_id: str) -> List[Dict[str, str]] | None:
    doc = read_json_doc(path)
    items = doc.get("items") if isinstance(doc, dict) else None
    if not isinstance(items, list):
        raise BuilderError("WORK_ITEMS_INVALID")
    matches = match_work_items(items, work_id)
    extra = uniqueness_extra(work_id, items, matches)
    if len(matches) == 0:
        raise BuilderError("WORK_ITEM_NOT_FOUND", extra)
    if len(matches) != 1:
        raise BuilderError("WORK_ITEM_NOT_UNIQUE", extra)
    item = matches[0]
    raw = item.get("owner_inputs") or {}
    vehicles = raw.get("vehicles") if isinstance(raw, dict) else None
    if vehicles is None:
        return None
    if not isinstance(vehicles, list):
        raise BuilderError("OWNER_INPUTS_INVALID", extra)
    return vehicles


def _vehicle_count(item: Dict[str, Any]) -> int:
    raw = item.get("owner_inputs") or {}
    vehicles = raw.get("vehicles") if isinstance(raw, dict) else None
    return len(vehicles) if isinstance(vehicles, list) else 0


def score_parts_chase_item(item: Dict[str, Any]) -> int:
    score = 0
    if str(item.get("status", "")).upper() == "OPEN":
        score += 2
    if item.get("blocked") is False:
        score += 1
    if str(item.get("required_skill_key", "")) == PARTS_CHASE_KEY:
        score += 2
    if _vehicle_count(item) == 8:
        score += 4
    return score


def canonical_parts_chase_item() -> Dict[str, Any]:
    return {
        "id": PARTS_CHASE_WORK_ID,
        "program": "capability-reuse",
        "authority_class": "GREEN",
        "status": "OPEN",
        "lane": "production",
        "work_type": "execution",
        "priority": "high",
        "severity": "high",
        "owner_value": 5,
        "required_skill_key": PARTS_CHASE_KEY,
        "required_capabilities": ["kevin_proven_skill_invoke"],
        "worker": "proven-skill-invocation",
        "reuses_proven_capability": True,
        "produces_owner_deliverable": True,
        "closes_proof_gap": True,
        "reduces_bess_intervention": True,
        "near_acceptance": True,
        "dependencies_ready": True,
        "blocked": False,
        "failure_attempts": 0,
        "material_new_evidence": True,
        "estimated_minutes": 20,
        "owner_inputs": {
            "dataset": "fictional-eight-dealership-vehicles",
            "vehicles": fictional_eight_vehicles(),
        },
        "next_action": (
            "Select this OPEN GREEN WorkInstance and route "
            "west-motor-parts-chase-board-pack@1 through the invocation worker. "
            "Do not send to tool-less fixed:main. Keep the existing 1 burned 09:31 turn. "
            "PASS still requires real workbook + note + hashes + invocation receipt."
        ),
        "downstream_consumer": "FIRST_FRESH_OWNER_OUTCOME_AND_T3_INVOCATION_PROOF",
        "restored_by": "kevin-proven-skill-request-builder-v1.0.3",
    }


def repair_work_item_uniqueness(
    path: Path,
    work_id: str,
    archive_dir: Path | None = None,
) -> Dict[str, Any]:
    """Make work_id unique without wiping other items or resetting history.

    0 matches: append the canonical 8-vehicle GREEN item.
    2+ matches: keep the highest-scoring copy, archive the extras.
    1 match: no-op.
    """
    doc = read_json_doc(path)
    if not isinstance(doc, dict):
        raise BuilderError("WORK_ITEMS_INVALID")
    items = doc.get("items")
    if not isinstance(items, list):
        raise BuilderError("WORK_ITEMS_INVALID")
    matches = match_work_items(items, work_id)
    before = len(matches)
    archived = 0
    action = "ALREADY_UNIQUE"
    if before == 1:
        action = "ALREADY_UNIQUE"
    elif before == 0:
        items.append(canonical_parts_chase_item() if work_id == PARTS_CHASE_WORK_ID else {
            "id": work_id,
            "program": "capability-reuse",
            "authority_class": "GREEN",
            "status": "OPEN",
            "blocked": False,
            "required_skill_key": PARTS_CHASE_KEY,
            "owner_inputs": {"vehicles": fictional_eight_vehicles()},
            "restored_by": "kevin-proven-skill-request-builder-v1.0.3",
        })
        action = "INSERTED_CANONICAL"
        doc["items"] = items
        write_json_doc(path, doc)
    else:
        keeper = max(matches, key=lambda item: (score_parts_chase_item(item), -matches.index(item)))
        extras = [item for item in matches if item is not keeper]
        rewritten: List[Any] = []
        kept = False
        for item in items:
            if isinstance(item, dict) and str(item.get("id")) == work_id:
                if not kept:
                    rewritten.append(keeper)
                    kept = True
                continue
            rewritten.append(item)
        if not kept:
            rewritten.append(keeper)
        if archive_dir is None:
            archive_dir = path.parent / "archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        archive_path = archive_dir / f"work-items-duplicate-archive-{work_id}-{stamp}.json"
        write_json_doc(
            archive_path,
            {
                "schema": 1,
                "kind": "kevin-work-items-duplicate-archive",
                "safe_for_public_repo": True,
                "work_id": work_id,
                "archived_at": stamp,
                "items": extras,
            },
        )
        archived = len(extras)
        action = "DEDUPED_KEEP_BEST"
        doc["items"] = rewritten
        write_json_doc(path, doc)
    after_doc = read_json_doc(path)
    after_items = after_doc.get("items") if isinstance(after_doc, dict) else []
    after_matches = match_work_items(after_items if isinstance(after_items, list) else [], work_id)
    return {
        "status": "REPAIRED",
        "reason": action,
        "work_id": work_id,
        "match_count_before": before,
        "match_count_after": len(after_matches),
        "items_count_after": len(after_items) if isinstance(after_items, list) else 0,
        "archived": archived,
        "builder_version": VERSION,
        "outcome_proven": False,
    }


def emit_reject(reason: str, extra: Dict[str, Any] | None = None) -> None:
    payload: Dict[str, Any] = {"status": "REJECTED", "reason": reason}
    if extra:
        payload.update(extra)
    print(json.dumps(payload))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--invocation-id")
    parser.add_argument("--work-items", help="inbox/autonomy/work-items.json")
    parser.add_argument("--work-id")
    parser.add_argument("--output", help="request JSON path (required unless --repair-unique)")
    parser.add_argument("--repair-unique", action="store_true", help="make --work-id unique in --work-items")
    parser.add_argument("--archive", help="directory for duplicate archives")
    args = parser.parse_args()
    if args.repair_unique:
        if not args.work_items or not args.work_id:
            raise BuilderError("WORK_ID_REQUIRED_WITH_WORK_ITEMS")
        archive = Path(args.archive) if args.archive else None
        result = repair_work_item_uniqueness(Path(args.work_items), args.work_id, archive)
        print(json.dumps(result))
        return 0
    if not args.invocation_id or not args.output:
        raise BuilderError("INVOCATION_ID_AND_OUTPUT_REQUIRED")
    rows = None
    if args.work_items:
        if not args.work_id:
            raise BuilderError("WORK_ID_REQUIRED_WITH_WORK_ITEMS")
        rows = load_work_item_vehicles(Path(args.work_items), args.work_id)
    request = build_parts_chase_request(args.invocation_id, rows)
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "vehicles": 8, "builder_version": VERSION}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BuilderError as exc:
        emit_reject(exc.reason, exc.extra)
        raise SystemExit(2)
    except json.JSONDecodeError as exc:
        reason = "WORK_ITEMS_UTF8_BOM" if "BOM" in str(exc) else "WORK_ITEMS_UNREADABLE"
        emit_reject(reason)
        raise SystemExit(2)
    except Exception:
        emit_reject("BUILDER_UNCAUGHT")
        raise SystemExit(2)
