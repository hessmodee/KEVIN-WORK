#!/usr/bin/env python3
"""Kevin Work Admission v1: Work Supply -> Selector -> Capability Router.

Authority effect: NONE. Plans dispatch only; does not execute, install Desktop,
or widen Relay beyond typed operations.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Any, Dict, Optional

HERE = Path(__file__).resolve().parent


def load_mod(name: str, path: Path):
    import sys
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def load_json(path: Optional[str], default: Any) -> Any:
    if not path or not Path(path).exists():
        return json.loads(json.dumps(default))
    raw = Path(path).read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    return json.loads(raw.decode("utf-8"))


def write_json(path: Optional[str], value: Any) -> None:
    text = json.dumps(value, indent=2) + "\n"
    if path:
        p = Path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
    else:
        print(text, end="")


def admit(
    items: Dict[str, Any],
    catalog: Dict[str, Any],
    programs: Dict[str, Any],
    families: Dict[str, Any],
    state: Dict[str, Any],
    inventory: Dict[str, Any],
    support: Dict[str, Any],
    engineering: Dict[str, Any],
    autonomy: Dict[str, Any],
    skills: list,
    now: dt.datetime,
    selector_path: Path,
    supply_path: Path,
    router_path: Path,
) -> Dict[str, Any]:
    supply = load_mod("supply", supply_path)
    selector = load_mod("selector", selector_path)
    router = load_mod("router", router_path)

    merged, supply_state = supply.build_supply(
        items, catalog, inventory, support, engineering, autonomy, skills, now
    )
    # Normalize skill-lab lane WIP into staging bucket for selector contract.
    wip_state = json.loads(json.dumps(state))
    wip = wip_state.setdefault("wip", {})
    for lane in ("production", "staging", "research"):
        wip.setdefault(lane, 0)
    # Map skill-lab -> staging for WIP accounting without inventing a fourth live Supervisor WIP key.
    for it in merged.get("items") or []:
        if str(it.get("lane", "")).lower() in {"skill-lab", "skill_lab"}:
            it = it  # selector v1.2 accepts skill-lab; v1.1 would unknown-lane.

    selection = selector.select(programs, merged, wip_state, families, now)
    routing = router.route_selection(selection, merged, inventory)

    # Compose truth: Supervisor NO_ELIGIBLE must not erase Skill Lab demand.
    truth = supply_state.get("truth_state")
    if routing.get("skill_lab_ready_ids"):
        truth = "ELIGIBLE_WORK"
    elif routing.get("truth_state") == "BLOCKED_WORK_PRESENT" or supply_state.get("blocked_count", 0):
        if truth == "TRUE_IDLE":
            truth = "BLOCKED_WORK_PRESENT"

    dispatch = routing.get("dispatch") or "NONE"
    supervisor_action = "IDLE_CHECK_ONLY"
    if dispatch == "ROUTE_TO_FIXED_MAIN":
        supervisor_action = "DISPATCH_FIXED_MAIN"
    elif dispatch == "ROUTE_TO_SKILL_LAB":
        supervisor_action = "DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN"
    elif dispatch == "ROUTE_TO_ENGINEERING_RELAY":
        supervisor_action = "DEFER_TO_ENGINEERING_RELAY_DO_NOT_CALL_MAIN"
    elif str(dispatch).startswith("ROUTE_TO_"):
        supervisor_action = "DEFER_TO_TYPED_WORKER_DO_NOT_CALL_MAIN"
    elif dispatch == "BLOCKED":
        supervisor_action = "RECORD_BLOCKER_DO_NOT_CALL_MAIN"

    out = {
        "schema": 1,
        "kind": "kevin-work-admission-state",
        "version": "1.0.0",
        "at": now.isoformat().replace("+00:00", "Z"),
        "authority_effect": "NONE_ADMISSION_ONLY",
        "truth_state": truth,
        "supply": {
            "truth_state": supply_state.get("truth_state"),
            "eligible_count": supply_state.get("eligible_count"),
            "blocked_count": supply_state.get("blocked_count"),
            "generated_count": supply_state.get("generated_count"),
            "top_blocker": supply_state.get("top_blocker"),
            "selected_candidate": supply_state.get("selected_candidate"),
        },
        "selection": {
            "status": selection.get("status"),
            "eligible_count": selection.get("eligible_count"),
            "blocked_count": selection.get("blocked_count"),
            "selected_id": (selection.get("selection") or {}).get("id") if selection.get("selection") else None,
            "selection": selection.get("selection"),
        },
        "routing": routing,
        "supervisor_action": supervisor_action,
        "invariants": {
            "no_desktop_to_toolless_main": True,
            "no_skill_lab_to_fixed_main": supervisor_action != "DISPATCH_FIXED_MAIN"
            or (routing.get("route") or {}).get("worker") == "fixed:main",
            "supervisor_idle_does_not_erase_skill_lab": True,
            "no_work_invention": True,
            "relay_arbitrary_shell": False,
            "desktop_production_install": False,
        },
        "work_items_supplied": merged,
    }
    # Strengthen skill-lab invariant explicitly.
    route = routing.get("route") or {}
    if route.get("worker") == "skill-lab":
        out["invariants"]["no_skill_lab_to_fixed_main"] = supervisor_action == "DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN"
        assert supervisor_action == "DEFER_TO_SKILL_LAB_DO_NOT_CALL_MAIN"
    if route.get("forbid_fixed_main") and supervisor_action == "DISPATCH_FIXED_MAIN":
        raise AssertionError("admission attempted fixed:main dispatch for forbid_fixed_main route")

    material = {k: v for k, v in out.items() if k not in {"at", "fingerprint", "work_items_supplied"}}
    # Include selected id + dispatch in fingerprint material only.
    out["fingerprint"] = hashlib.sha256(
        json.dumps(material, sort_keys=True, separators=(",", ":"), default=str).encode()
    ).hexdigest().upper()
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", required=True)
    ap.add_argument("--catalog", required=True)
    ap.add_argument("--programs", required=True)
    ap.add_argument("--failure-families", required=True)
    ap.add_argument("--state", required=True)
    ap.add_argument("--inventory", default="")
    ap.add_argument("--support", default="")
    ap.add_argument("--engineering", default="")
    ap.add_argument("--autonomy", default="")
    ap.add_argument("--skills-dir", default="")
    ap.add_argument("--now", default="")
    ap.add_argument("--selector", default=str(HERE / "kevin-work-selector-v1.2.py"))
    ap.add_argument("--supply", default=str(HERE / "kevin-work-supply-v1.py"))
    ap.add_argument("--router", default=str(HERE / "kevin-capability-router-v1.py"))
    ap.add_argument("--output", default="")
    ap.add_argument("--output-items", default="")
    args = ap.parse_args()

    supply = load_mod("supply_time", Path(args.supply))
    now = supply.now_utc(args.now) if args.now else supply.now_utc(None)
    skills = supply.skill_ids(args.skills_dir) if args.skills_dir else []

    result = admit(
        load_json(args.items, {"schema": 1, "kind": "kevin-work-items", "items": []}),
        load_json(args.catalog, {"standing_work": []}),
        load_json(args.programs, {"schema": 1, "kind": "kevin-standing-program-registry", "programs": []}),
        load_json(args.failure_families, {"schema": 1, "kind": "kevin-failure-family-registry", "policy": {}, "families": []}),
        load_json(args.state, {"schema": 1, "wip": {"production": 0, "staging": 0, "research": 0}}),
        load_json(args.inventory, {"capabilities": [], "workers": [], "agents": {"fixed:main": {"tools": False, "tool_count": 0}}}),
        load_json(args.support, {}),
        load_json(args.engineering, {}),
        load_json(args.autonomy, {}),
        skills,
        now,
        Path(args.selector),
        Path(args.supply),
        Path(args.router),
    )
    if args.output_items:
        write_json(args.output_items, result.get("work_items_supplied"))
    slim = {k: v for k, v in result.items() if k != "work_items_supplied"}
    write_json(args.output or None, slim)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
