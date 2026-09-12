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

VERSION = "1.0.13"
PARTS_CHASE_KEY = "west-motor-parts-chase-board-pack@1"
PARTS_CHASE_WORK_ID = "owner-west-motor-parts-chase-fresh-8-v1"
TRANSPORT_KEY = "vehicle-transport-mission-pack@1"
TRANSPORT_WORK_ID = "owner-west-motor-transport-dispatch-template-v1"
DEALERSHIP_SCAN_KEY = "dealership-operations-opportunity-scan-pack@1"
DEALERSHIP_SCAN_WORK_ID = "owner-dealership-operations-opportunity-scan-fresh-2026-09-11-v1"
RUNTIME_TRUTH_KEY = "runtime-truth-reconciliation-diagnosis-pack@1"
RUNTIME_TRUTH_WORK_ID = "autonomy-runtime-truth-reconciliation-fresh-2026-09-11-v1"
EXPIRED_MANIFEST_KEY = "expired-manifest-regression-design-pack@1"
EXPIRED_MANIFEST_WORK_ID = "autonomy-expired-manifest-regression-design-fresh-2026-09-11-v1"
REFLECTION_RUNTIME_KEY = "reflection-runtime-integration-design-pack@1"
REFLECTION_RUNTIME_WORK_ID = "autonomy-reflection-runtime-integration-fresh-2026-09-11-v1"
BROWSER_COMPUTER_KEY = "browser-computer-qualification-design-pack@1"
BROWSER_COMPUTER_WORK_ID = "autonomy-browser-computer-qualification-fresh-2026-09-11-v1"
LOT_WALK_KEY = "west-motor-lot-walk-checklist-pack@1"
LOT_WALK_WORK_ID = "owner-west-motor-lot-walk-checklist-fresh-2026-09-11-v1"
AGING_INV_KEY = "west-motor-aging-inventory-action-pack@1"
AGING_INV_WORK_ID = "owner-west-motor-aging-inventory-fresh-2026-09-11-v1"
DELIVERY_PREP_KEY = "west-motor-delivery-prep-pack@1"
DELIVERY_PREP_WORK_ID = "owner-west-motor-delivery-prep-fresh-2026-09-11-v1"
RECON_BOARD_KEY = "west-motor-recon-priority-board-pack@1"
RECON_BOARD_WORK_ID = "owner-west-motor-recon-priority-board-fresh-2026-09-11-v1"
TRANSPORT_FIELDS = (
    "priority",
    "request_id",
    "origin",
    "destination",
    "unit",
    "assignee",
    "target_datetime",
    "status",
    "coordination_notes",
    "exception",
)
TRANSPORT_HEADER = [
    "Priority",
    "Request / Mission ID",
    "Origin",
    "Destination",
    "Vehicle / Unit",
    "Driver / Assignee",
    "Target Date/Time",
    "Status",
    "Coordination Notes",
    "Exception / Completion",
]
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



def fictional_dispatch_rows() -> List[Dict[str, str]]:
    return [
        {"priority": "HIGH", "request_id": "XT-EX-9001", "origin": "Example Lot A - West Motor", "destination": "Example Body Shop North", "unit": "EX-SUV-221 (stock WM-EX-221)", "assignee": "Driver Example-1", "target_datetime": "2026-09-12 09:00", "status": "PLANNED", "coordination_notes": "Fictional keys+folder staged at desk", "exception": "None"},
        {"priority": "HIGH", "request_id": "XT-EX-9002", "origin": "Example Auction Yard", "destination": "Example Lot B - West Motor", "unit": "EX-TRUCK-118 (stock WM-EX-118)", "assignee": "Driver Example-2", "target_datetime": "2026-09-12 13:30", "status": "ASSIGNED", "coordination_notes": "Trailer example dual-axle", "exception": "None"},
        {"priority": "MED", "request_id": "XT-EX-9003", "origin": "Example Lot C", "destination": "Example Detail Bay 2", "unit": "EX-SEDAN-044", "assignee": "Driver Example-1", "target_datetime": "2026-09-13 08:00", "status": "PLANNED", "coordination_notes": "Inter-store move example", "exception": "None"},
        {"priority": "MED", "request_id": "XT-EX-9004", "origin": "Example Customer Hold (generic)", "destination": "Example Service Ramp", "unit": "EX-VAN-077", "assignee": "Unassigned", "target_datetime": "2026-09-13 15:00", "status": "BLOCKED", "coordination_notes": "Awaiting example paperwork check", "exception": "Missing example checklist"},
        {"priority": "LOW", "request_id": "XT-EX-9005", "origin": "Example Storage Compound", "destination": "Example Front Line", "unit": "EX-CUV-309", "assignee": "Driver Example-3", "target_datetime": "2026-09-14 10:00", "status": "PLANNED", "coordination_notes": "Generic labels only", "exception": "None"},
        {"priority": "LOW", "request_id": "XT-EX-9006", "origin": "Example Lot A", "destination": "Example Photo Pad", "unit": "EX-COUPE-015", "assignee": "Driver Example-2", "target_datetime": "2026-09-14 11:30", "status": "DONE", "coordination_notes": "Example complete - fictional", "exception": "None"},
    ]


def validate_dispatch_rows(rows: List[Dict[str, str]]) -> None:
    if not isinstance(rows, list) or not (4 <= len(rows) <= 12):
        raise BuilderError("DISPATCH_COUNT_INVALID")
    seen = []
    for row in rows:
        if not isinstance(row, dict):
            raise BuilderError("DISPATCH_ROW_INVALID")
        missing = [f for f in TRANSPORT_FIELDS if not str(row.get(f, "")).strip()]
        if missing:
            raise BuilderError("MISSING_FIELDS:" + ",".join(missing))
        rid = str(row["request_id"]).strip()
        if rid in seen:
            raise BuilderError("DUPLICATE_REQUEST_ID")
        seen.append(rid)
        blob = " ".join(str(row[f]) for f in TRANSPORT_FIELDS).lower()
        for banned in ("ssn", "password", "secret", "live customer", "@gmail", "paypal"):
            if banned in blob:
                raise BuilderError("FORBIDDEN_CONTENT")


def transport_operating_note(rows: List[Dict[str, str]]) -> str:
    openish = sum(1 for r in rows if str(r["status"]).upper() not in {"DONE", "COMPLETE", "DELIVERED"})
    return (
        "# West Motor Transport Dispatch - fictional operating note\n\n"
        "GREEN example board for daily vehicle-transport dispatch. Generic example data only.\n"
        "No customer PII, no live VIN, no purchases, sends, or DMS writes.\n\n"
        "## How Matt can use it\n"
        "1. Sort by Priority then Target Date/Time.\n"
        "2. Assign Driver/Assignee on PLANNED rows before departure.\n"
        "3. Move Status PLANNED -> ASSIGNED -> IN_TRANSIT -> DONE.\n"
        "4. Put blockers in Exception / Completion; do not invent live facts.\n\n"
        f"## This example\n- Rows: {len(rows)}\n- Still open: {openish}\n"
        "- Skill bind: vehicle-transport-mission-pack@1 (already PROVEN create_spreadsheet+create_text).\n"
        "- Authority: GREEN fictional rehearsal only.\n"
    )


def build_transport_request(invocation_id: str, rows: List[Dict[str, str]] | None = None) -> Dict[str, Any]:
    missions = rows if rows is not None else fictional_dispatch_rows()
    validate_dispatch_rows(missions)
    board_rows = [TRANSPORT_HEADER] + [[str(row[f]) for f in TRANSPORT_FIELDS] for row in missions]
    return {
        "schema": 1,
        "kind": "kevin-proven-skill-invocation",
        "authority": "GREEN",
        "skill_key": TRANSPORT_KEY,
        "invocation_id": invocation_id,
        "steps": [
            {
                "operation": "create_spreadsheet",
                "payload": {
                    "filename": "Kevin-West-Motor-Transport-Dispatch-Fictional.xlsx",
                    "workbook": {
                        "schema": 1,
                        "kind": "kevin-xlsx-spec",
                        "sheets": [
                            {"name": "Dispatch Board", "rows": board_rows},
                            {"name": "Board Legend", "rows": [
                                ["Field", "Meaning", "Rule"],
                                ["Priority", "HIGH / MED / LOW", "Do not invent urgency"],
                                ["Status", "PLANNED / ASSIGNED / IN_TRANSIT / DONE / BLOCKED", "No auto send"],
                                ["Vehicle / Unit", "Example stock/unit labels", "No live customer VIN"],
                            ]},
                        ],
                    },
                },
            },
            {
                "operation": "create_text",
                "payload": {
                    "filename": "Kevin-West-Motor-Transport-Dispatch-Fictional-Note.md",
                    "content": transport_operating_note(missions),
                },
            },
        ],
    }


def load_work_item_dispatch(path: Path, work_id: str) -> List[Dict[str, str]] | None:
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
    rows = raw.get("dispatch_rows") if isinstance(raw, dict) else None
    if rows is None:
        return None
    if not isinstance(rows, list):
        raise BuilderError("OWNER_INPUTS_INVALID", extra)
    return rows


def build_dealership_scan_request(invocation_id: str) -> Dict[str, Any]:
    """GREEN fictional opportunity scan — mirrors Lab-PROVEN pack (spreadsheet+text only)."""
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"dealership-operations-opportunity-scan.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Opportunities\", \"rows\": [[\"ID\", \"Problem\", \"Owner value\", \"Inputs needed\", \"Privacy boundary\", \"Success metric\", \"Deliverable\", \"Reusable skill candidate\", \"Status\"], [\"OPP-001\", \"Daily lot/ops status scattered across chats\", \"High \\u00e2\\u20ac\\u201d less Matt chase time\", \"Lot walk notes + open RO list (no PII)\", \"No customer PII/VIN/phone\", \"One board Matt opens each morning\", \"Spreadsheet board + 1-page brief\", \"dealership-ops-morning-board@1\", \"Candidate\"], [\"OPP-002\", \"Transport exceptions lack a single exception lane\", \"Medium\", \"Dispatch board exceptions column\", \"Generic examples only\", \"Exceptions cleared same day\", \"Exception filter view on dispatch board\", \"(reuse vehicle-transport-mission-pack)\", \"Candidate\"]]}, {\"name\": \"Next skill\", \"rows\": [[\"Field\", \"Value\"], [\"Recommended first skill\", \"dealership-ops-morning-board@1\"], [\"Primitives\", \"create_spreadsheet + create_text only\"], [\"Notepad\", \"BANNED for Lab proof\"], [\"Downstream\", \"OWNER morning ops visibility\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"dealership-operations-opportunity-brief.md\", \"content\": \"# Dealership operations opportunity brief\\n\\n**WorkInstance:** owner-dealership-operations-opportunity-scan-fresh-2026-09-11-v1  \\n**Actor staging:** GROKBOT_ACTED (Lab prove path; not Kevin-learned claim)  \\n**Notepad:** banned for Lab proof\\n\\n## Top opportunity\\nMorning ops visibility: one GREEN spreadsheet board Matt can open for lot/ops status without chasing chats. Uses already-proven create_spreadsheet + create_text only.\\n\\n## Privacy\\nNo customer PII, live VIN, phones, sends, purchases, or new authority.\\n\\n## Success metric\\nMatt opens one board in the morning and sees blockers/exceptions without a Slack scavenger hunt.\\n\\n## Bounded next skill candidate\\n`dealership-ops-morning-board@1` \\u00e2\\u20ac\\u201d after this scan pack is PROVEN in Skill Lab registry.\\n\\n## Predecessor\\n`owner-dealership-operations-opportunity-scan-v1` remains BOUNDED_TURNS evidence (not reset).\"}}]")
    return {
        "schema": 1,
        "kind": "kevin-proven-skill-invocation",
        "authority": "GREEN",
        "skill_key": DEALERSHIP_SCAN_KEY,
        "invocation_id": invocation_id,
        "steps": steps,
    }


def build_runtime_truth_request(invocation_id: str) -> Dict[str, Any]:
    """GREEN diagnosis pack — mirrors Lab-PROVEN spreadsheet+text steps."""
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"runtime-truth-reconciliation-diagnosis.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Source Freshness\", \"rows\": [[\"Source\", \"Path\", \"Freshest At (fill)\", \"Status\", \"Notes\"], [\"Continuation\", \"reports/autonomy-continuation-latest.json\", \"\", \"OPEN\", \"Supervisor truth plane\"], [\"HQ Live Floor\", \"reports/hq-live-floor.json\", \"\", \"OPEN\", \"ONE CLOCK authority\"], [\"Support Latest\", \"reports/support-latest.json\", \"\", \"OPEN\", \"Must sync UP to floor only\"], [\"Public Reject\", \"reports/invocations/latest-public-reject.json\", \"\", \"OPEN\", \"Hashes + reason-code\"], [\"Benchmark\", \"reports (benchmark latest)\", \"\", \"OPEN\", \"If present\"], [\"Maintenance\", \"reports/maintenance\", \"\", \"OPEN\", \"Do not alter protected state\"]]}, {\"name\": \"Stale Displays\", \"rows\": [[\"Display / Report\", \"Suspected Stale?\", \"Contradicts Source\", \"Evidence Pointer\", \"Owner Impact\"], [\"HQ Pages cycle paint\", \"MAYBE\", \"support.cycle 449 vs floor>=450\", \"LESSON-one-clock-floor-cycle-authority\", \"Matt sees frozen 449\"], [\"Public reject lag\", \"MAYBE\", \"outcome_proven stripe vs live invoke\", \"latest-public-reject.json\", \"False PASS/lag risk\"], [\"Skill lab GAP paint\", \"MAYBE\", \"failed leftovers vs new PROVEN packs\", \"hq-live-floor.skill_lab\", \"Misleads Lab-first\"]]}, {\"name\": \"Repair Target\", \"rows\": [[\"Field\", \"Value\"], [\"Smallest typed repair\", \"Tick-owned publisher/support sync UP + Pages read floor.cycle only\"], [\"Forbidden\", \"history reset; fixed:main workaround; Notepad Lab proof; Supervisor recopy\"], [\"Consumer\", \"SUPPORT_HQ_TRUTH_PUBLISHER_REPAIR\"], [\"WorkInstance\", \"autonomy-runtime-truth-reconciliation-fresh-2026-09-11-v1\"], [\"Predecessor\", \"autonomy-runtime-truth-reconciliation-v1\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"runtime-truth-reconciliation-diagnosis-brief.md\", \"content\": \"# Runtime truth reconciliation diagnosis brief\\n\\n**WorkInstance:** autonomy-runtime-truth-reconciliation-fresh-2026-09-11-v1\\n**Predecessor:** autonomy-runtime-truth-reconciliation-v1 (BOUNDED evidence; no history reset)\\n**Actor staging:** GROKBOT_ACTED (Lab prove path; not Kevin-learned claim)\\n**Notepad:** banned for Lab proof\\n**Primitives:** create_spreadsheet + create_text only\\n\\n## Intent\\nCompare freshest local Engineering / Support / Benchmark / Supervisor / Maintenance evidence against stale HQ/publisher displays. Leave a durable bounded repair target for the engineering/maintenance lane. Do not alter protected production state. A model reply alone is not repair proof.\\n\\n## ONE CLOCK\\n`reports/hq-live-floor.json` cycle is authoritative. `support-latest.supervisor.cycle` syncs UP only and is never a painter freeze sentinel.\\n\\n## Success\\nDurable diagnosis pointer naming freshest source, stale display, and smallest typed reconciliation mechanism.\"}}]")
    return {
        "schema": 1,
        "kind": "kevin-proven-skill-invocation",
        "authority": "GREEN",
        "skill_key": RUNTIME_TRUTH_KEY,
        "invocation_id": invocation_id,
        "steps": steps,
    }


def build_expired_manifest_request(invocation_id: str) -> Dict[str, Any]:
    """GREEN design pack — Lab-PROVEN spreadsheet+text."""
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"expired-manifest-regression-design.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Current Semantics\", \"rows\": [[\"Question\", \"Finding (fill from runner)\", \"Evidence Pointer\", \"Risk if wrong\"], [\"Expired canonical refused before exec?\", \"OPEN\", \"Maintenance runner\", \"Cron health poison\"], [\"Terminal/duplicate path?\", \"OPEN\", \"Maintenance runner\", \"Replay/exec\"], [\"Malformed fail-closed?\", \"OPEN\", \"Maintenance runner\", \"Silent skip\"], [\"Valid path still executes?\", \"OPEN\", \"Maintenance runner\", \"False idle\"]]}, {\"name\": \"Design Delta\", \"rows\": [[\"Change\", \"Smallest fail-closed behavior\", \"Auditable result kind\", \"Forbidden\"], [\"Expired input\", \"Refuse before execution\", \"IDLE_EXPIRED or TERMINAL_EXPIRED receipt\", \"Execute stale work\"], [\"Duplicate/terminal\", \"Refuse; keep prior receipt\", \"TERMINAL_DUPLICATE\", \"Reset history\"], [\"Malformed\", \"Fail closed with reason-code\", \"REJECT_MALFORMED\", \"Best-effort run\"], [\"Valid\", \"Unchanged execute path\", \"SUCCESS/receipt as today\", \"Widen authority\"]]}, {\"name\": \"Regression Matrix\", \"rows\": [[\"Case\", \"Input fixture\", \"Expect exec?\", \"Expect result kind\", \"Proof\"], [\"EXPIRED\", \"expired canonical manifest\", \"NO\", \"IDLE/TERMINAL expired\", \"unit/harness\"], [\"DUPLICATE_TERMINAL\", \"already terminal id\", \"NO\", \"terminal duplicate\", \"unit/harness\"], [\"MALFORMED\", \"broken JSON/schema\", \"NO\", \"reject malformed\", \"unit/harness\"], [\"VALID\", \"current good manifest\", \"YES\", \"normal success path\", \"unit/harness\"], [\"ROLLBACK\", \"exact-current/exact-after\", \"N/A\", \"identity gates preserved\", \"Benchmark gate\"]]}, {\"name\": \"Acceptance Contract\", \"rows\": [[\"Field\", \"Value\"], [\"WorkInstance\", \"autonomy-expired-manifest-regression-design-fresh-2026-09-11-v1\"], [\"Predecessor\", \"autonomy-expired-manifest-regression-design-v1\"], [\"Consumer\", \"MAINTENANCE_V1_3_51_PATCH_AND_REGRESSION\"], [\"Production write this item\", \"NONE\"], [\"Primitives\", \"create_spreadsheet + create_text\"], [\"Notepad\", \"BANNED\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"expired-manifest-regression-design-brief.md\", \"content\": \"# Expired manifest regression design brief\\n\\n**WorkInstance:** autonomy-expired-manifest-regression-design-fresh-2026-09-11-v1\\n**Predecessor:** autonomy-expired-manifest-regression-design-v1 (BOUNDED evidence; no history reset)\\n**Actor staging:** GROKBOT_ACTED (Lab prove path; not Kevin-learned)\\n**Notepad:** banned\\n**Primitives:** create_spreadsheet + create_text only\\n**Production write:** NONE in this research item\\n\\n## Goal\\nConfirm Maintenance refuses expired canonical manifests before execution, then design the smallest fail-closed change so expired/terminal input stays non-executable but records a truthful auditable idle/terminal result instead of poisoning scheduled cron health.\\n\\n## Tests (deterministic)\\n1. EXPIRED \\u00e2\\u20ac\\u201d no exec; idle/terminal expired receipt\\n2. DUPLICATE/TERMINAL \\u00e2\\u20ac\\u201d no exec; terminal duplicate\\n3. MALFORMED \\u00e2\\u20ac\\u201d fail closed with reason-code\\n4. VALID \\u00e2\\u20ac\\u201d still executes\\n5. Preserve rollback + exact-current/exact-after identity + Benchmark gates for later promotion\\n\\n## Out of scope\\nNo production Maintenance patch apply in this WI. Downstream consumer applies after design acceptance.\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":EXPIRED_MANIFEST_KEY,"invocation_id":invocation_id,"steps":steps}


def build_reflection_runtime_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"reflection-runtime-integration-design.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Surface Map\", \"rows\": [[\"Surface\", \"Artifact / path\", \"Reflection hook today\", \"Gap\"], [\"Supervisor\", \"reports/autonomy-continuation-latest.json\", \"partial\", \"failure\\u00e2\\u2020\\u2019reflection missing\"], [\"Maintenance\", \"reports/maintenance\", \"partial\", \"expired/terminal idle vs poison\"], [\"Skill Lab\", \"reports/action-era/skills\", \"partial\", \"PROVEN\\u00e2\\u2030\\u00a0owner resume\"], [\"Engineering\", \"reports/engineering\", \"partial\", \"lesson not auto-wired\"]]}, {\"name\": \"Trigger Contract\", \"rows\": [[\"Field\", \"Rule\"], [\"Trigger\", \"Real failure with durable evidence (not model-only)\"], [\"Record\", \"fingerprint, hypotheses, tests, independent verify, lesson, dependency-retirement if external eng, resume pointer\"], [\"Authority\", \"Recommend/stage only; typed crossing for protected effects\"], [\"Resume\", \"Original owner task continues after successful repair\"]]}, {\"name\": \"Replay Test\", \"rows\": [[\"Step\", \"Expect\"], [\"1 Induce bounded failure\", \"reflection artifact written\"], [\"2 Repair succeeds\", \"lesson + resume pointer\"], [\"3 Replay\", \"owner task resumes; does not end at repair\"], [\"4 Authority check\", \"no new primitives\"]]}, {\"name\": \"Acceptance\", \"rows\": [[\"Field\", \"Value\"], [\"WorkInstance\", \"autonomy-reflection-runtime-integration-fresh-2026-09-11-v1\"], [\"Predecessor\", \"autonomy-reflection-runtime-integration-v1\"], [\"Consumer\", \"INCIDENT_REFLECTION_RUNTIME_WIRE\"], [\"Notepad\", \"BANNED\"], [\"Primitives\", \"create_spreadsheet + create_text\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"reflection-runtime-integration-design-brief.md\", \"content\": \"# Reflection runtime integration design brief\\n\\n**WorkInstance:** autonomy-reflection-runtime-integration-fresh-2026-09-11-v1\\n**Predecessor:** autonomy-reflection-runtime-integration-v1 (BOUNDED; no history reset)\\n**Actor:** GROKBOT_ACTED staging (not Kevin-learned)\\n**Notepad:** banned | **Primitives:** spreadsheet + text only\\n\\n## Contract\\nBounded runtime trigger on real failures records fingerprint, competing hypotheses, tests, independent verification, lesson, dependency-retirement when external engineering was used, and a resume pointer. Reflection may recommend/stage; protected effects still use existing typed crossings. Replay must prove the original owner task resumes after successful repair rather than ending at the repair.\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":REFLECTION_RUNTIME_KEY,"invocation_id":invocation_id,"steps":steps}


def build_browser_computer_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"browser-computer-qualification-design.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Inventory\", \"rows\": [[\"Capability\", \"Installed evidence (fill)\", \"Version/path\", \"Protected?\", \"Notes\"], [\"OpenClaw runtime\", \"OPEN\", \"\", \"YES\", \"no credential read\"], [\"Managed browser\", \"OPEN\", \"\", \"YES\", \"isolated only\"], [\"Windows Computer Use\", \"OPEN\", \"\", \"YES\", \"no personal browser\"], [\"Model/tool prereqs\", \"OPEN\", \"\", \"YES\", \"list only\"]]}, {\"name\": \"Contract Gap\", \"rows\": [[\"Required contract\", \"Current\", \"Gap\", \"Risk\"], [\"Isolated managed browser\", \"OPEN\", \"OPEN\", \"credential leak\"], [\"Windows Computer Use bound\", \"OPEN\", \"OPEN\", \"unbounded desktop\"], [\"No personal browser\", \"OPEN\", \"OPEN\", \"PII/session\"], [\"No credential handling\", \"OPEN\", \"OPEN\", \"secret exposure\"]]}, {\"name\": \"Qualification Plan\", \"rows\": [[\"Phase\", \"Action\", \"Rollback\", \"Negative test\", \"Promote?\"], [\"1 Inventory\", \"Read-only evidence\", \"N/A\", \"fail if secrets touched\", \"NO\"], [\"2 Isolated browser stage\", \"Stage managed profile only\", \"revert profile\", \"fail if personal profile\", \"NO\"], [\"3 Computer Use stage\", \"Bounded harness\", \"disable harness\", \"fail if unbounded\", \"NO\"], [\"4 Independent prove\", \"Receipt+VERIFY\", \"keep prior\", \"fail if no receipt\", \"later\"]]}, {\"name\": \"Acceptance\", \"rows\": [[\"Field\", \"Value\"], [\"WorkInstance\", \"autonomy-browser-computer-qualification-fresh-2026-09-11-v1\"], [\"Predecessor\", \"autonomy-browser-computer-qualification-v1\"], [\"Notepad\", \"BANNED\"], [\"Chat/tool widen\", \"FORBIDDEN this pack\"], [\"Primitives\", \"create_spreadsheet + create_text\"], [\"Production upgrade\", \"NONE\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"browser-computer-qualification-design-brief.md\", \"content\": \"# Browser / Computer Use qualification design brief\\n\\n**WorkInstance:** autonomy-browser-computer-qualification-fresh-2026-09-11-v1\\n**Predecessor:** autonomy-browser-computer-qualification-v1 (BOUNDED; no history reset)\\n**Actor:** GROKBOT_ACTED staging (not Kevin-learned)\\n**Notepad:** banned | **Chat/tool widen:** forbidden in this pack\\n**Primitives:** create_spreadsheet + create_text only\\n**Production upgrade:** NONE\\n\\n## Plan\\n1. Inventory installed OpenClaw/browser/computer-use evidence without credentials or protected config changes.\\n2. Compare to isolated managed-browser and Windows Computer Use contracts.\\n3. Reversible qualification with explicit rollback, model/tool prerequisites, negative tests, and no-personal-browser / no-credential-handling boundary.\\n4. Do not blindly upgrade production; stage and independently prove before any later promotion.\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":BROWSER_COMPUTER_KEY,"invocation_id":invocation_id,"steps":steps}


def build_lot_walk_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"Kevin West Motor Lot Walk Checklist.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Lot Walk\", \"rows\": [[\"Priority\", \"Stock / Unit\", \"Year\", \"Make\", \"Model\", \"Location Zone\", \"Cleanliness\", \"Tire / Battery\", \"Keys Present\", \"Ready For Sale?\", \"Issue Found\", \"Next Action\", \"Owner\"], [\"P1\", \"\", \"\", \"\", \"\", \"\", \"\", \"\", \"\", \"NO\", \"\", \"\", \"\"]]}, {\"name\": \"Issue Queue\", \"rows\": [[\"Priority\", \"Unit\", \"Issue\", \"Category\", \"Blocked Sale?\", \"Parts / Detail Needed\", \"Assigned\", \"Due\", \"Status\", \"Evidence\"], [\"P1\", \"\", \"\", \"Detail / Mech / Paper / Photo\", \"YES\", \"\", \"\", \"\", \"OPEN\", \"\"]]}, {\"name\": \"Follow-ups\", \"rows\": [[\"Date\", \"Unit\", \"Ask / Message Draft\", \"Audience\", \"Sent?\", \"Response\", \"Outcome\", \"Notes\"], [\"\", \"\", \"\", \"Sales / Detail / Parts / GM\", \"NO\", \"\", \"\", \"\"]]}, {\"name\": \"Daily Summary\", \"rows\": [[\"Date\", \"Units Walked\", \"Ready Count\", \"Blocked Count\", \"Top Blockers\", \"Wins\", \"Owner Notes\"], [\"\", \"\", \"\", \"\", \"\", \"\", \"\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"Kevin West Motor Lot Walk Checklist - SOP.md\", \"content\": \"# West Motor Lot Walk Checklist\\n\\n## Purpose\\nGive Kevin a repeatable morning lot-walk pack so inventory readiness issues are visible before customers arrive.\\n\\n## Sequence\\n1. Walk zones systematically (front line, side lot, back row, detail hold).\\n2. Capture unit identity and obvious readiness flags (clean, tires/battery, keys, paperwork/photos).\\n3. Log blockers in Issue Queue with whether they block a sale.\\n4. Draft follow-ups for humans; do not send messages or purchase parts without authority.\\n5. Close with Daily Summary counts.\\n\\n## Protective behavior\\nFlag missing keys, unsafe units, unknown stock numbers, and contradictory ready-for-sale claims. Never invent VINs. Never discard or move vehicles. Never spend money.\\n\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":LOT_WALK_KEY,"invocation_id":invocation_id,"steps":steps}


def build_aging_inv_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\": \"create_spreadsheet\", \"payload\": {\"filename\": \"Kevin West Motor Aging Inventory Action Board.xlsx\", \"workbook\": {\"schema\": 1, \"kind\": \"kevin-xlsx-spec\", \"sheets\": [{\"name\": \"Aging Board\", \"rows\": [[\"Stock\", \"Year Make Model\", \"Days In Stock\", \"Age Band\", \"Stage\", \"Owner\", \"List Status\", \"Next Action\", \"Due\", \"Notes\"], [\"\", \"\", \"\", \"0-30 / 31-60 / 61-90 / 90+\", \"HOLD / RETAIL PUSH / WHOLESALE REVIEW / SPECIAL\", \"\", \"LISTED / UNLISTED / UNK\", \"\", \"\", \"Do not invent prices\"]]}, {\"name\": \"Action Ladder\", \"rows\": [[\"Stock\", \"Current Ladder Step\", \"Photo Ready\", \"Price Review Due\", \"Wholesale Option\", \"Retail Push Idea\", \"Trade Special?\", \"Who Decides\", \"Status\", \"Notes\"], [\"\", \"PHOTO / PRICE / CHANNEL / DISPOSITION\", \"NO\", \"\", \"REVIEW ONLY\", \"\", \"NO\", \"MATT\", \"OPEN\", \"No auto purchase or post\"]]}, {\"name\": \"Price Notes\", \"rows\": [[\"Stock\", \"Current Ask\", \"Ask Source\", \"Market Notes\", \"Recon Left Band\", \"Honest Margin Guess\", \"Verified?\", \"Blocks Sale?\", \"Updated At\", \"Notes\"], [\"\", \"\", \"DMS / SHEET / UNK\", \"\", \"\", \"\", \"NO\", \"MAYBE\", \"\", \"Never invent ACV wholesale or retail\"]]}, {\"name\": \"Blockers Chase\", \"rows\": [[\"Stock\", \"Blocker\", \"Blocks Sale?\", \"Who Owns\", \"Asked At\", \"ETA\", \"Status\", \"Needs Purchase?\", \"Needs Live Post?\", \"Notes\"], [\"\", \"\", \"YES\", \"\", \"\", \"\", \"OPEN\", \"NO\", \"NO\", \"No auto purchase no DMS write no live post\"]]}, {\"name\": \"Weekly Focus\", \"rows\": [[\"Week Of\", \"Top Aged Unit\", \"Why This Week\", \"One Move\", \"Owner\", \"Done?\", \"Carry Forward?\", \"Risk If Idle\", \"Review With\", \"Notes\"], [\"\", \"\", \"\", \"\", \"\", \"NO\", \"MAYBE\", \"\", \"MATT\", \"Pick the smallest honest move\"]]}]}}}, {\"operation\": \"create_text\", \"payload\": {\"filename\": \"Kevin West Motor Aging Inventory Action - SOP.md\", \"content\": \"# Kevin West Motor Aging Inventory Action\\n\\nUse this pack to chase aged inventory with honest next actions. Do not invent prices or market values.\\n\\n## Operating rule\\nAging action is false until the unit is on Aging Board with an age band, owner, and a real next action. Prefer the smallest ladder step that clears the next blocker. Never invent ACV, wholesale, or retail figures.\\n\\n## Required sequence\\n1. Log aged units on Aging Board with days, age band, stage, and known facts only.\\n2. Place each unit on Action Ladder (photo, price review, channel, disposition) without auto-posting.\\n3. Fill Price Notes only from asks already in hand; mark UNK and Verified=NO when unknown.\\n4. Chase Blockers without purchases, live DMS writes, or live public posts.\\n5. Pick one Weekly Focus unit and one honest move; review with Matt before paid or live side effects.\\n\\n## Protective behavior\\nKevin must not invent prices, purchase reports, write live DMS, post listings, widen Chat tools beyond Desktop exact-5, or claim READY while blockers remain. Sheet count stays at or below five. Payloads stay ASCII-safe. Sheet names use spaces only (no slash).\\n\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":AGING_INV_KEY,"invocation_id":invocation_id,"steps":steps}



def build_delivery_prep_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\":\"create_spreadsheet\",\"payload\":{\"filename\":\"Kevin West Motor Delivery Prep Board.xlsx\",\"workbook\":{\"schema\":1,\"kind\":\"kevin-xlsx-spec\",\"sheets\":[{\"name\":\"Delivery Board\",\"rows\":[[\"Stock / Unit\",\"Customer / Deal\",\"Target Delivery\",\"Stage\",\"Open Blockers\",\"Owner\",\"Keys Ready\",\"Docs Ready\",\"Detail Done\",\"Front Line OK\",\"Next Action\"],[\"\",\"\",\"\",\"RECON / DETAIL / PAPERWORK / READY\",\"\",\"\",\"NO\",\"NO\",\"NO\",\"NO\",\"\"]]},{\"name\":\"Paperwork Checklist\",\"rows\":[[\"Stock / Unit\",\"Bill of Sale\",\"Title / Lien\",\"Warranty Forms\",\"Trade Docs\",\"Temp Tag\",\"Disclosure\",\"Signed?\",\"Missing Item\",\"Owner\"],[\"\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"\",\"\"]]},{\"name\":\"Unit Condition\",\"rows\":[[\"Stock / Unit\",\"Fuel\",\"Charge / Battery\",\"Clean Inside\",\"Clean Outside\",\"Tire / Spare\",\"Accessories\",\"Known Issues\",\"Photos Taken\",\"OK to Deliver\"],[\"\",\"\",\"\",\"NO\",\"NO\",\"NO\",\"NO\",\"\",\"NO\",\"NO\"]]},{\"name\":\"Handoff Log\",\"rows\":[[\"Date\",\"Stock / Unit\",\"Customer Contacted\",\"Pickup Window\",\"Who Briefed Customer\",\"Walkaround Done\",\"Issues Raised\",\"Resolved?\",\"Delivered?\"],[\"\",\"\",\"NO\",\"\",\"\",\"NO\",\"\",\"NO\",\"NO\"]]},{\"name\":\"Blockers Chase\",\"rows\":[[\"Stock / Unit\",\"Blocker\",\"Blocks Delivery?\",\"Vendor / Desk\",\"Asked At\",\"ETA\",\"Chase Owner\",\"Status\",\"Notes\"],[\"\",\"\",\"YES\",\"\",\"\",\"\",\"\",\"OPEN\",\"No auto purchase\"]]}]}}},{\"operation\":\"create_text\",\"payload\":{\"filename\":\"Kevin West Motor Delivery Prep - SOP.md\",\"content\":\"# Kevin West Motor Delivery Prep\\n\\nUse this pack so a sold or promised unit is honestly ready for customer pickup or delivery.\\n\\n## Operating rule\\nDelivery readiness is false until paperwork, unit condition, and handoff walkaround are true. Prefer the smallest chase that clears the next blocker.\\n\\n## Required sequence\\n1. Rank units on Delivery Board with stage, blockers, and owners.\\n2. Complete Paperwork Checklist without inventing signed status.\\n3. Verify Unit Condition (fuel/charge, clean, tires, accessories, photos).\\n4. Log customer handoff contact and walkaround outcomes.\\n5. Chase Blockers without placing paid orders unless Matt names the purchase.\\n\\n## Protective behavior\\nKevin must not purchase parts, write live DMS, post listings, widen Chat tools beyond Desktop exact-5, or claim READY while blockers remain. Sheet count stays at or below five. Payloads stay ASCII-safe.\\n\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":DELIVERY_PREP_KEY,"invocation_id":invocation_id,"steps":steps}


def build_recon_board_request(invocation_id: str) -> Dict[str, Any]:
    steps = json.loads("[{\"operation\":\"create_spreadsheet\",\"payload\":{\"filename\":\"Kevin West Motor Recon Priority Board.xlsx\",\"workbook\":{\"schema\":1,\"kind\":\"kevin-xlsx-spec\",\"sheets\":[{\"name\":\"Priority Board\",\"rows\":[[\"Priority\",\"Stock / Unit\",\"Year\",\"Make\",\"Model\",\"Stage\",\"Aging Days\",\"Blocker\",\"Owner\",\"Ready Front Line?\",\"Next Action\",\"Due\"],[\"P1\",\"\",\"\",\"\",\"\",\"INTAKE / CLEAN / REPAIR / PARTS / DETAIL / READY\",\"\",\"\",\"\",\"NO\",\"\",\"\"]]},{\"name\":\"Parts Holds\",\"rows\":[[\"Stock / Unit\",\"Part Needed\",\"Vendor\",\"Ordered?\",\"ETA\",\"Cost Cap Note\",\"Blocks Stage\",\"Chase Owner\",\"Status\",\"Notes\"],[\"\",\"\",\"\",\"NO\",\"\",\"Ask Matt before paid order\",\"REPAIR\",\"\",\"OPEN\",\"No auto purchase\"]]},{\"name\":\"Daily Moves\",\"rows\":[[\"Date\",\"Stock / Unit\",\"From Stage\",\"To Stage\",\"By\",\"Minutes\",\"Still Blocked?\",\"Evidence / Photo Note\",\"Follow-up\"],[\"\",\"\",\"\",\"\",\"\",\"\",\"NO\",\"\",\"\"]]},{\"name\":\"Aging Alerts\",\"rows\":[[\"Stock / Unit\",\"Days In Recon\",\"Stage Stuck\",\"Why Stuck\",\"Customer / Sales Impact\",\"Escalate To\",\"Escalated?\",\"Resolution\"],[\"\",\"\",\"\",\"\",\"\",\"Matt / Manager\",\"NO\",\"\"]]},{\"name\":\"Ready Checklist\",\"rows\":[[\"Stock / Unit\",\"Clean\",\"Mechanical\",\"Parts Complete\",\"Keys / Books\",\"Photos Ready\",\"Price / Board\",\"Front Line OK\",\"Signed By\",\"Date\"],[\"\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"NO\",\"\",\"\"]]}]}}},{\"operation\":\"create_text\",\"payload\":{\"filename\":\"Kevin West Motor Recon Priority Board - SOP.md\",\"content\":\"# Kevin West Motor Recon Priority Board\\n\\nUse this pack to keep West Motor recon honest: one board, clear stages, aging, and parts holds without fake busywork.\\n\\n## Operating rule\\nA unit is real work when it is not front-line ready. Prefer the smallest stage move that unblocks sales.\\n\\n## Required sequence\\n1. Rank units on Priority Board with stage, aging, blocker, and owner.\\n2. Log Parts Holds without placing paid orders unless Matt names the purchase.\\n3. Record Daily Moves with from/to stage and whether the block remains.\\n4. Escalate Aging Alerts when a unit sits without a next action.\\n5. Mark Ready Checklist only when clean, mechanical, parts, keys, photos, and board price are truly done.\\n\\n## Protective behavior\\nKevin must not purchase parts, write live DMS, post listings, widen Chat tools, or treat Supervisor IDLE as global idle while recon backlog remains. Sheet count stays at or below five. Payloads stay ASCII-safe.\\n\"}}]")
    return {"schema":1,"kind":"kevin-proven-skill-invocation","authority":"GREEN","skill_key":RECON_BOARD_KEY,"invocation_id":invocation_id,"steps":steps}

def resolve_skill_for_work_id(work_id: str, item: Dict[str, Any] | None = None) -> str:
    if item and str(item.get("required_skill_key") or "").strip():
        key = str(item.get("required_skill_key")).strip()
        if key in {PARTS_CHASE_KEY, TRANSPORT_KEY, DEALERSHIP_SCAN_KEY, RUNTIME_TRUTH_KEY, EXPIRED_MANIFEST_KEY, REFLECTION_RUNTIME_KEY, BROWSER_COMPUTER_KEY, LOT_WALK_KEY, AGING_INV_KEY, DELIVERY_PREP_KEY, RECON_BOARD_KEY}:
            return key
        raise BuilderError("UNSUPPORTED_SKILL_KEY")
    if work_id == TRANSPORT_WORK_ID:
        return TRANSPORT_KEY
    if work_id == PARTS_CHASE_WORK_ID:
        return PARTS_CHASE_KEY
    if work_id == DEALERSHIP_SCAN_WORK_ID:
        return DEALERSHIP_SCAN_KEY
    if work_id == RUNTIME_TRUTH_WORK_ID:
        return RUNTIME_TRUTH_KEY
    if work_id == EXPIRED_MANIFEST_WORK_ID:
        return EXPIRED_MANIFEST_KEY
    if work_id == REFLECTION_RUNTIME_WORK_ID:
        return REFLECTION_RUNTIME_KEY
    if work_id == BROWSER_COMPUTER_WORK_ID:
        return BROWSER_COMPUTER_KEY
    if work_id == LOT_WALK_WORK_ID:
        return LOT_WALK_KEY
    if work_id == AGING_INV_WORK_ID:
        return AGING_INV_KEY
    if work_id == DELIVERY_PREP_WORK_ID:
        return DELIVERY_PREP_KEY
    if work_id == RECON_BOARD_WORK_ID:
        return RECON_BOARD_KEY
    raise BuilderError("UNSUPPORTED_WORK_ID")



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
        doc = read_json_doc(Path(args.work_items))
        items = doc.get("items") if isinstance(doc, dict) else []
        if not isinstance(items, list):
            raise BuilderError("WORK_ITEMS_INVALID")
        matches = match_work_items(items, args.work_id)
        extra = uniqueness_extra(args.work_id, items, matches)
        if len(matches) == 0:
            raise BuilderError("WORK_ITEM_NOT_FOUND", extra)
        if len(matches) != 1:
            raise BuilderError("WORK_ITEM_NOT_UNIQUE", extra)
        item = matches[0]
        skill = resolve_skill_for_work_id(args.work_id, item)
        if skill == TRANSPORT_KEY:
            drows = load_work_item_dispatch(Path(args.work_items), args.work_id)
            request = build_transport_request(args.invocation_id, drows)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            n = len(request["steps"][0]["payload"]["workbook"]["sheets"][0]["rows"]) - 1
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "dispatch_rows": n, "builder_version": VERSION}))
            return 0
        if skill == DEALERSHIP_SCAN_KEY:
            request = build_dealership_scan_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == RUNTIME_TRUTH_KEY:
            request = build_runtime_truth_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == EXPIRED_MANIFEST_KEY:
            request = build_expired_manifest_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == REFLECTION_RUNTIME_KEY:
            request = build_reflection_runtime_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == BROWSER_COMPUTER_KEY:
            request = build_browser_computer_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == LOT_WALK_KEY:
            request = build_lot_walk_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == AGING_INV_KEY:
            request = build_aging_inv_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == DELIVERY_PREP_KEY:
            request = build_delivery_prep_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
        if skill == RECON_BOARD_KEY:
            request = build_recon_board_request(args.invocation_id)
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)
            Path(args.output).write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"status": "BUILT", "skill_key": request["skill_key"], "invocation_id": args.invocation_id, "steps": len(request["steps"]), "builder_version": VERSION}))
            return 0
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
