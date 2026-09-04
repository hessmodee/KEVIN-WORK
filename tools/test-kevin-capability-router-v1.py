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


def test_relay_route():
    item = {"id": "stage-x", "worker": "engineering-relay", "lane": "staging", "required_capabilities": []}
    r = m.route_item(item, TOOLLESS)
    assert r["dispatch"] == "ROUTE_TO_ENGINEERING_RELAY"
    assert r["forbid_fixed_main"] is True


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
    print(f"KEVIN CAPABILITY ROUTER v1 SELFTEST PASS ({len(tests)} tests)")
