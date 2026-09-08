#!/usr/bin/env python3
"""Kevin Capability-Aware Router v1.1 — authority-neutral dispatch planner.

Selects the worker/lane that owns a typed capability. Never grants authority,
never invents work, and never routes Desktop-required work to tool-less fixed:main.

v1.1 adds a deterministic production bridge for WorkInstances that explicitly
name a required PROVEN composite skill. The router resolves the exact immutable
skill identity and routes only to the Proven Skill Invocation lane when that
runtime capability is independently effective. It never fuzzy-matches a skill,
re-qualifies it, widens primitive authority, or silently falls back to Main.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

VERSION = "1.1.0"
AUTHORITY = "NONE_ROUTING_ONLY"
INVOCATION_CAP = "kevin_proven_skill_invoke"
INVOCATION_PRIMITIVES = {"create_text", "create_spreadsheet"}
SKILL_KEY_RE = re.compile(r"^[A-Za-z0-9._-]{4,80}@[A-Za-z0-9._-]{1,32}$")
HASH_RE = re.compile(r"^[A-Fa-f0-9]{64}$")

DESKTOP_CAPS = {
    "kevin_desktop_runtime_installed",
    "kevin_desktop_runtime_probe",
    "kevin_system_status",
    "kevin_desktop_find_folder",
    "kevin_desktop_open_folder",
    "kevin_app_launch",
}
SKILL_LAB_CAPS = {"kevin_skill_lab_execute", "kevin_skill_lab_stage"}
RELAY_CAPS = {"kevin_engineering_relay", "stage_composite_skill"}
GUARDIAN_CAPS = {"kevin_full_autonomy_audit"}

WORKER_ALIASES = {
    "main": "fixed:main",
    "fixed:main": "fixed:main",
    "operator": "fixed:main",
    "skill-lab": "skill-lab",
    "skill_lab": "skill-lab",
    "proven-skill-invocation": "proven-skill-invocation",
    "proven_skill_invocation": "proven-skill-invocation",
    "engineering-relay": "engineering-relay",
    "relay": "engineering-relay",
    "guardian": "guardian",
    "reviewer": "reviewer",
    "sensor": "sensor",
}


def load_json(path: Optional[str], default: Any) -> Any:
    if not path or not Path(path).exists():
        return copy.deepcopy(default)
    raw = Path(path).read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    return json.loads(raw.decode("utf-8"))


def effective_capabilities(inventory: Dict[str, Any]) -> Set[str]:
    out: Set[str] = set()
    if not isinstance(inventory, dict):
        return out
    for v in inventory.get("capabilities", []) or []:
        if isinstance(v, str):
            out.add(v)
        elif isinstance(v, dict) and v.get("effective") is True and v.get("id"):
            out.add(str(v["id"]))
    for w in inventory.get("workers", []) or []:
        if not isinstance(w, dict):
            continue
        if w.get("effective") is True:
            if w.get("id"):
                out.add("worker:" + str(w["id"]))
            for c in w.get("capabilities", []) or []:
                out.add(str(c))
    agents = inventory.get("agents") or {}
    main = agents.get("fixed:main") or agents.get("main") or {}
    if isinstance(main, dict):
        if main.get("tools") is False or int(main.get("tool_count") or 0) == 0:
            out.discard("worker:fixed:main")
            out.add("signal:fixed_main_tools_false")
        elif main.get("tools") is True or int(main.get("tool_count") or 0) > 0:
            out.add("worker:fixed:main")
            for t in main.get("tool_ids") or []:
                out.add(str(t))
    return out


def normalize_worker(raw: Any) -> Optional[str]:
    if raw is None or str(raw).strip() == "":
        return None
    key = str(raw).strip().lower()
    return WORKER_ALIASES.get(key, key)


def explicit_skill_key(item: Dict[str, Any]) -> str:
    raw = item.get("required_skill_key")
    if raw is None or str(raw).strip() == "":
        raw = item.get("proven_skill_key")
    return str(raw or "").strip()


def resolve_proven_skill(skill_key: str, registry: Optional[Dict[str, Any]]) -> Tuple[Optional[Dict[str, Any]], str]:
    """Resolve one exact production-invocable PROVEN skill or return a fail-closed reason."""
    if not SKILL_KEY_RE.fullmatch(skill_key):
        return None, "REQUIRED_SKILL_KEY_INVALID"
    if not isinstance(registry, dict):
        return None, "PROVEN_SKILL_REGISTRY_UNAVAILABLE"
    if registry.get("schema") != 1 or registry.get("kind") != "kevin-composite-skill-registry":
        return None, "PROVEN_SKILL_REGISTRY_INVALID"
    skills = registry.get("skills")
    if not isinstance(skills, list):
        return None, "PROVEN_SKILL_REGISTRY_INVALID"
    matches = [x for x in skills if isinstance(x, dict) and str(x.get("key", "")) == skill_key]
    if len(matches) != 1:
        return None, "PROVEN_SKILL_NOT_AVAILABLE"
    entry = matches[0]
    if entry.get("status") != "PROVEN" or entry.get("authority") != "GREEN":
        return None, "PROVEN_SKILL_NOT_AVAILABLE"
    if not HASH_RE.fullmatch(str(entry.get("manifest_sha256", ""))) or not HASH_RE.fullmatch(str(entry.get("proof_sha256", ""))):
        return None, "PROVEN_SKILL_IDENTITY_INVALID"
    primitives = entry.get("primitive_steps")
    if not isinstance(primitives, list) or not primitives or any(str(p) not in INVOCATION_PRIMITIVES for p in primitives):
        return None, "PROVEN_SKILL_NOT_INVOCATION_V1_COMPATIBLE"
    return copy.deepcopy(entry), "EXACT_PROVEN_SKILL_MATCH"


def infer_worker(item: Dict[str, Any]) -> str:
    if explicit_skill_key(item):
        return "proven-skill-invocation"
    explicit = normalize_worker(item.get("worker"))
    if explicit:
        return explicit
    lane = str(item.get("lane", "")).lower()
    program = str(item.get("program", "")).lower()
    caps = {str(c) for c in (item.get("required_capabilities") or [])}
    if lane in {"skill-lab", "skill_lab"} or program in {"owner-value-skills", "skill-learning", "capability-growth"}:
        if caps & DESKTOP_CAPS and not (caps & SKILL_LAB_CAPS):
            return "fixed:main"
        return "skill-lab"
    if caps & SKILL_LAB_CAPS:
        return "skill-lab"
    if caps & RELAY_CAPS or lane == "engineering-relay":
        return "engineering-relay"
    if caps & GUARDIAN_CAPS or lane == "guardian" or program in {"self-heal", "self-maintenance", "platform-reliability"}:
        if caps & GUARDIAN_CAPS or lane == "guardian":
            return "guardian"
    if caps & DESKTOP_CAPS or program == "computer-fluency":
        return "fixed:main"
    return "fixed:main"


def missing_caps(required: List[str], have: Set[str]) -> List[str]:
    return sorted(c for c in required if c not in have)


def route_item(item: Dict[str, Any], inventory: Dict[str, Any], skill_registry: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    caps = effective_capabilities(inventory)
    skill_key = explicit_skill_key(item)
    worker = infer_worker(item)
    required = [str(c) for c in (item.get("required_capabilities") or [])]

    if skill_key:
        decision = {
            "schema": 1,
            "kind": "kevin-capability-route",
            "version": VERSION,
            "authority_effect": AUTHORITY,
            "work_id": item.get("id"),
            "worker": "proven-skill-invocation",
            "required_capabilities": required + ([] if INVOCATION_CAP in required else [INVOCATION_CAP]),
            "required_skill_key": skill_key,
            "missing_capabilities": [],
            "dispatch": "BLOCKED",
            "reason": "",
            "forbid_fixed_main": True,
            "proven_identity": None,
            "next_resolution": None,
        }
        entry, reason = resolve_proven_skill(skill_key, skill_registry)
        if entry is None:
            decision.update(
                reason=reason,
                next_resolution="ACQUIRE_OR_REPAIR_CAPABILITY_VIA_SKILL_LAB" if reason == "PROVEN_SKILL_NOT_AVAILABLE" else "REPAIR_PROOF_OR_REGISTRY",
            )
            return decision
        if INVOCATION_CAP not in caps and "worker:proven-skill-invocation" not in caps:
            decision.update(
                reason="PROVEN_SKILL_INVOCATION_NOT_EFFECTIVE",
                missing_capabilities=[INVOCATION_CAP],
                next_resolution="QUALIFY_AND_ENABLE_INVOCATION_RUNTIME",
            )
            return decision
        decision.update(
            dispatch="ROUTE_TO_PROVEN_SKILL_INVOCATION",
            reason="EXACT_PROVEN_SKILL_MATCH",
            proven_identity={
                "key": entry.get("key"),
                "manifest_sha256": entry.get("manifest_sha256"),
                "proof_sha256": entry.get("proof_sha256"),
                "primitive_steps": list(entry.get("primitive_steps") or []),
                "result_file": entry.get("result_file"),
            },
            next_resolution="INVOKE_WITH_FRESH_BOUNDED_OWNER_INPUTS",
        )
        return decision

    if worker == "fixed:main" and str(item.get("program", "")).lower() == "computer-fluency" and not required:
        required = ["kevin_desktop_runtime_installed", "kevin_desktop_runtime_probe"]
    if worker == "skill-lab" and not required:
        required = ["kevin_skill_lab_execute"]

    decision = {
        "schema": 1,
        "kind": "kevin-capability-route",
        "version": VERSION,
        "authority_effect": AUTHORITY,
        "work_id": item.get("id"),
        "worker": worker,
        "required_capabilities": required,
        "missing_capabilities": [],
        "dispatch": "BLOCKED",
        "reason": "",
        "forbid_fixed_main": False,
    }

    needs_desktop = bool(set(required) & DESKTOP_CAPS) or (
        worker == "fixed:main" and str(item.get("program", "")).lower() == "computer-fluency"
    )
    main_tooless = "signal:fixed_main_tools_false" in caps or "worker:fixed:main" not in caps
    if needs_desktop and worker == "fixed:main" and main_tooless:
        decision.update(
            dispatch="BLOCKED",
            reason="DESKTOP_REQUIRED_BUT_FIXED_MAIN_TOOLLESS",
            forbid_fixed_main=True,
            missing_capabilities=missing_caps(required or sorted(DESKTOP_CAPS), caps) or ["kevin_desktop_runtime_installed"],
        )
        return decision

    if worker == "skill-lab":
        miss = missing_caps(required, caps)
        if miss and "worker:skill-lab" not in caps and "kevin_skill_lab_execute" not in caps:
            decision.update(
                dispatch="BLOCKED",
                reason="MISSING_EFFECTIVE_CAPABILITY:" + ",".join(miss),
                missing_capabilities=miss,
                forbid_fixed_main=True,
            )
            return decision
        decision.update(
            dispatch="ROUTE_TO_SKILL_LAB",
            reason="OWNER_COMPOSITE_OWNED_BY_SKILL_LAB",
            forbid_fixed_main=True,
            missing_capabilities=[],
        )
        return decision

    if worker == "engineering-relay":
        decision.update(dispatch="ROUTE_TO_ENGINEERING_RELAY", reason="TYPED_RELAY_OPERATION", forbid_fixed_main=True)
        return decision

    if worker in {"guardian", "reviewer", "sensor"}:
        miss = missing_caps(required, caps)
        if miss:
            decision.update(
                dispatch="BLOCKED",
                reason="MISSING_EFFECTIVE_CAPABILITY:" + ",".join(miss),
                missing_capabilities=miss,
                forbid_fixed_main=True,
            )
            return decision
        decision.update(dispatch="ROUTE_TO_" + worker.upper().replace("-", "_"), reason="TYPED_WORKER_LANE", forbid_fixed_main=True)
        return decision

    miss = missing_caps(required, caps)
    if miss:
        decision.update(dispatch="BLOCKED", reason="MISSING_EFFECTIVE_CAPABILITY:" + ",".join(miss), missing_capabilities=miss, forbid_fixed_main=needs_desktop)
        return decision
    if main_tooless and required:
        decision.update(dispatch="BLOCKED", reason="FIXED_MAIN_TOOLLESS_CANNOT_SATISFY_REQUIRED_CAPS", forbid_fixed_main=True, missing_capabilities=required)
        return decision
    decision.update(dispatch="ROUTE_TO_FIXED_MAIN", reason="MAIN_OWNS_CAPABILITY")
    return decision


def route_selection(selection: Dict[str, Any], items: Dict[str, Any], inventory: Dict[str, Any], skill_registry: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    chosen = selection.get("selection") if isinstance(selection, dict) else None
    item_map = {str(x.get("id")): x for x in (items.get("items") or []) if isinstance(x, dict)}
    if not chosen:
        skill_ready = []
        skill_blocked = []
        proven_ready = []
        proven_blocked = []
        for it in items.get("items") or []:
            if not isinstance(it, dict):
                continue
            st = str(it.get("status", "")).upper()
            skill_key = explicit_skill_key(it)
            if skill_key and st in {"OPEN", "READY"} and it.get("blocked") is not True:
                route = route_item(it, inventory, skill_registry)
                (proven_ready if route.get("dispatch") == "ROUTE_TO_PROVEN_SKILL_INVOCATION" else proven_blocked).append(it.get("id"))
                continue
            worker = infer_worker(it)
            if worker != "skill-lab":
                continue
            if st in {"OPEN", "READY"} and it.get("blocked") is not True:
                skill_ready.append(it.get("id"))
            elif st not in {"COMPLETE", "COMPLETED", "CLOSED", "PROVEN", "OMEN_PROVEN", "REPEATEDLY_PROVEN", "RETIRED", "SUPERSEDED"}:
                skill_blocked.append(it.get("id"))
        truth = "ELIGIBLE_WORK" if skill_ready or proven_ready else ("BLOCKED_WORK_PRESENT" if skill_blocked or proven_blocked or (selection or {}).get("blocked_count", 0) else "TRUE_IDLE")
        state = {
            "schema": 1,
            "kind": "kevin-capability-routing-state",
            "version": VERSION,
            "authority_effect": AUTHORITY,
            "truth_state": truth,
            "supervisor_status_interpretation": "NO_ELIGIBLE_MISSION_IS_SUPERVISOR_LANE_ONLY",
            "skill_lab_ready_ids": skill_ready,
            "skill_lab_blocked_ids": skill_blocked,
            "proven_invocation_ready_ids": proven_ready,
            "proven_invocation_blocked_ids": proven_blocked,
            "route": None,
            "dispatch": "NONE",
            "forbid_fixed_main_for_desktop": True,
        }
    else:
        wid = str(chosen.get("id"))
        item = item_map.get(wid) or dict(chosen)
        merged = copy.deepcopy(item)
        for k in ("lane", "program", "worker", "required_capabilities", "required_skill_key", "proven_skill_key"):
            if k in chosen and chosen[k] is not None:
                merged[k] = chosen[k]
        route = route_item(merged, inventory, skill_registry)
        truth = "ELIGIBLE_WORK" if route["dispatch"].startswith("ROUTE_") else "BLOCKED_WORK_PRESENT"
        state = {
            "schema": 1,
            "kind": "kevin-capability-routing-state",
            "version": VERSION,
            "authority_effect": AUTHORITY,
            "truth_state": truth,
            "supervisor_status_interpretation": "NO_ELIGIBLE_MISSION_IS_SUPERVISOR_LANE_ONLY",
            "route": route,
            "dispatch": route["dispatch"],
            "forbid_fixed_main_for_desktop": True,
        }
    material = {k: v for k, v in state.items() if k != "fingerprint"}
    state["fingerprint"] = hashlib.sha256(json.dumps(material, sort_keys=True, separators=(",", ":")).encode()).hexdigest().upper()
    return state


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--item-json", help="Single work item JSON object/file")
    p.add_argument("--items", help="Work items document")
    p.add_argument("--selection", help="Selector output JSON")
    p.add_argument("--inventory", help="Effective capability inventory JSON")
    p.add_argument("--skill-registry", help="Composite skill registry JSON")
    p.add_argument("--output", help="Write routing state JSON")
    args = p.parse_args()
    inventory = load_json(args.inventory, {"capabilities": [], "workers": [], "agents": {}})
    registry = load_json(args.skill_registry, {}) if args.skill_registry else {}
    if args.item_json:
        item = load_json(args.item_json, {})
        out = route_item(item, inventory, registry)
    else:
        items = load_json(args.items, {"schema": 1, "kind": "kevin-work-items", "items": []})
        selection = load_json(args.selection, {"selection": None, "blocked_count": 0})
        out = route_selection(selection, items, inventory, registry)
    text = json.dumps(out, indent=2) + "\n"
    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
