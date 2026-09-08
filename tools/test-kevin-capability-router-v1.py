#!/usr/bin/env python3
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "control-plane" / "autonomy" / "kevin-capability-router-v1.py"
spec = importlib.util.spec_from_file_location("router", SRC)
m = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(m)

TOOLLESS = {"capabilities": [], "workers": [], "agents": {"fixed:main": {"tools": False, "tool_count": 0}}}
SKILL = {
    "capabilities": [{"id": "kevin_skill_lab_execute", "effective": True}],
    "workers": [{"id": "skill-lab", "effective": True, "capabilities": ["kevin_skill_lab_execute"]}],
    "agents": {"fixed:main": {"tools": False, "tool_count": 0}},
}
INVOKE = {
    "capabilities": [{"id": "kevin_proven_skill_invoke", "effective": True}],
    "workers": [{"id": "proven-skill-invocation", "effective": True, "capabilities": ["kevin_proven_skill_invoke"]}],
    "agents": {"fixed:main": {"tools": False, "tool_count": 0}},
}
DESKTOP_ON = {
    "capabilities": [
        {"id": "kevin_desktop_runtime_installed", "effective": True},
        {"id": "kevin_desktop_runtime_probe", "effective": True},
    ],
    "workers": [{"id": "fixed:main", "effective": True, "capabilities": [
        "kevin_system_status", "kevin_desktop_find_folder", "kevin_desktop_open_folder", "kevin_app_launch"
    ]}],
    "agents": {"fixed:main": {"tools": True, "tool_count": 4, "tool_ids": [
        "kevin_system_status", "kevin_desktop_find_folder", "kevin_desktop_open_folder", "kevin_app_launch"
    ]}},
}
REGISTRY = {
    "schema": 1,
    "kind": "kevin-composite-skill-registry",
    "updated_at": "2026-09-07T23:00:00-06:00",
    "skills": [{
        "id": "west-motor-parts-chase-board-pack",
        "version": "1",
        "key": "west-motor-parts-chase-board-pack@1",
        "authority": "GREEN",
        "status": "PROVEN",
        "name": "West Motor Parts Chase Board Pack",
        "manifest_sha256": "4F7744161CA858AC119164EDB136991A8D247C3F4A107A58C1FE52040DB65B37",
        "proof_sha256": "45367C928245E0177B754299FDF5F7391D60F6518D1B9923E284B0EC2B6FE1AE",
        "proven_at": "2026-09-04T23:29:21.7242283-06:00",
        "primitive_steps": ["create_spreadsheet", "create_text"],
        "result_file": "west-motor-parts-chase-board-pack--1.json",
    }],
}


def test_skill_lab_not_sent_to_main():
    item = {
        "id": "owner-composite-appliance-repair-pack-v2-prove",
        "program": "owner-value-skills",
        "lane": "skill-lab",
        "worker": "skill-lab",
        "status": "OPEN",
        "required_capabilities": ["kevin_skill_lab_execute"],
    }
    r = m.route_item(item, SKILL)
    assert r["dispatch"] == "ROUTE_TO_SKILL_LAB"
    assert r["forbid_fixed_main"] is True
    assert r["worker"] == "skill-lab"


def test_exact_proven_skill_routes_to_invocation_not_main_or_skill_lab():
    item = {
        "id": "parts-chase-slot-001",
        "program": "owner-value-skills",
        "lane": "production",
        "status": "OPEN",
        "required_skill_key": "west-motor-parts-chase-board-pack@1",
    }
    r = m.route_item(item, INVOKE, REGISTRY)
    assert r["dispatch"] == "ROUTE_TO_PROVEN_SKILL_INVOCATION", r
    assert r["worker"] == "proven-skill-invocation"
    assert r["forbid_fixed_main"] is True
    assert r["reason"] == "EXACT_PROVEN_SKILL_MATCH"
    assert r["proven_identity"]["manifest_sha256"] == REGISTRY["skills"][0]["manifest_sha256"]
    assert r["proven_identity"]["proof_sha256"] == REGISTRY["skills"][0]["proof_sha256"]
    assert r["proven_identity"]["primitive_steps"] == ["create_spreadsheet", "create_text"]


def test_proven_skill_source_exists_but_runtime_not_effective_blocks():
    item = {"id": "parts-chase-slot-002", "required_skill_key": "west-motor-parts-chase-board-pack@1"}
    r = m.route_item(item, TOOLLESS, REGISTRY)
    assert r["dispatch"] == "BLOCKED"
    assert r["reason"] == "PROVEN_SKILL_INVOCATION_NOT_EFFECTIVE"
    assert r["next_resolution"] == "QUALIFY_AND_ENABLE_INVOCATION_RUNTIME"
    assert "kevin_proven_skill_invoke" in r["missing_capabilities"]
    assert r["forbid_fixed_main"] is True


def test_unknown_proven_skill_routes_to_acquisition_not_fuzzy_guess():
    item = {"id": "unknown-skill-slot", "required_skill_key": "dealer-magic-pack@9"}
    r = m.route_item(item, INVOKE, REGISTRY)
    assert r["dispatch"] == "BLOCKED"
    assert r["reason"] == "PROVEN_SKILL_NOT_AVAILABLE"
    assert r["next_resolution"] == "ACQUIRE_OR_REPAIR_CAPABILITY_VIA_SKILL_LAB"
    assert r["forbid_fixed_main"] is True


def test_proven_skill_with_uninvocable_primitive_fails_closed():
    registry = {**REGISTRY, "skills": [dict(REGISTRY["skills"][0])]}
    registry["skills"][0]["primitive_steps"] = ["create_spreadsheet", "ui_notepad_write"]
    item = {"id": "parts-chase-slot-003", "required_skill_key": "west-motor-parts-chase-board-pack@1"}
    r = m.route_item(item, INVOKE, registry)
    assert r["dispatch"] == "BLOCKED"
    assert r["reason"] == "PROVEN_SKILL_NOT_INVOCATION_V1_COMPATIBLE"
    assert r["forbid_fixed_main"] is True


def test_desktop_blocked_on_toolless_main():
    item = {
        "id": "desktop-typed-crossing-runtime-proof-v1",
        "program": "computer-fluency",
        "lane": "production",
        "worker": "fixed:main",
        "required_capabilities": ["kevin_desktop_runtime_installed", "kevin_desktop_runtime_probe"],
    }
    r = m.route_item(item, TOOLLESS)
    assert r["dispatch"] == "BLOCKED"
    assert r["reason"] == "DESKTOP_REQUIRED_BUT_FIXED_MAIN_TOOLLESS"
    assert r["forbid_fixed_main"] is True


def test_desktop_routes_when_tools_effective():
    item = {
        "id": "desktop-typed-crossing-runtime-proof-v1",
        "program": "computer-fluency",
        "lane": "production",
        "worker": "fixed:main",
        "required_capabilities": ["kevin_desktop_runtime_installed", "kevin_desktop_runtime_probe"],
    }
    r = m.route_item(item, DESKTOP_ON)
    assert r["dispatch"] == "ROUTE_TO_FIXED_MAIN"


def test_owner_value_production_lane_without_worker_goes_to_skill_lab():
    item = {
        "id": "owner-west-motor-transport-dispatch-template-v1",
        "program": "owner-value-skills",
        "lane": "production",
        "status": "OPEN",
        "authority_class": "GREEN",
        "owner_value": 5,
        "dependencies_ready": True,
        "blocked": False,
    }
    r = m.route_item(item, SKILL)
    assert r["dispatch"] == "ROUTE_TO_SKILL_LAB", r
    assert r["forbid_fixed_main"] is True
    assert r["worker"] == "skill-lab"
    r_toolless = m.route_item(item, TOOLLESS)
    assert r_toolless["worker"] == "skill-lab"
    assert r_toolless["forbid_fixed_main"] is True
    assert r_toolless["dispatch"] != "ROUTE_TO_FIXED_MAIN"
    assert r_toolless["dispatch"] in {"ROUTE_TO_SKILL_LAB", "BLOCKED"}


def test_supervisor_idle_does_not_erase_skill_lab_ready():
    items = {
        "schema": 1,
        "kind": "kevin-work-items",
        "items": [{
            "id": "owner-composite-appliance-repair-pack-v2-prove",
            "program": "owner-value-skills",
            "lane": "skill-lab",
            "worker": "skill-lab",
            "status": "OPEN",
            "blocked": False,
            "required_capabilities": ["kevin_skill_lab_execute"],
        }],
    }
    selection = {"selection": None, "blocked_count": 9, "eligible_count": 0, "status": "NO_ELIGIBLE_WORK"}
    state = m.route_selection(selection, items, SKILL)
    assert state["truth_state"] == "ELIGIBLE_WORK"
    assert "owner-composite-appliance-repair-pack-v2-prove" in state["skill_lab_ready_ids"]
    assert state["supervisor_status_interpretation"] == "NO_ELIGIBLE_MISSION_IS_SUPERVISOR_LANE_ONLY"


def test_supervisor_idle_does_not_erase_invocable_proven_work():
    items = {
        "schema": 1,
        "kind": "kevin-work-items",
        "items": [{
            "id": "parts-chase-slot-004",
            "program": "owner-value-skills",
            "lane": "production",
            "status": "OPEN",
            "blocked": False,
            "required_skill_key": "west-motor-parts-chase-board-pack@1",
        }],
    }
    selection = {"selection": None, "blocked_count": 0, "eligible_count": 0, "status": "NO_ELIGIBLE_WORK"}
    state = m.route_selection(selection, items, INVOKE, REGISTRY)
    assert state["truth_state"] == "ELIGIBLE_WORK"
    assert "parts-chase-slot-004" in state["proven_invocation_ready_ids"]
    assert not state["proven_invocation_blocked_ids"]


def test_relay_route():
    item = {"id": "stage-x", "worker": "engineering-relay", "lane": "staging", "required_capabilities": []}
    r = m.route_item(item, TOOLLESS)
    assert r["dispatch"] == "ROUTE_TO_ENGINEERING_RELAY"
    assert r["forbid_fixed_main"] is True


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
    print(f"KEVIN CAPABILITY ROUTER v1.1 SELFTEST PASS ({len(tests)} tests) exact_proven_skill=true fuzzy_match=false runtime_effective_required=true")
