"""Plugin-shaped Calculator UI control module — refuse-by-default.

PLAN: docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md
Crossing: docs/engineering/KEVIN-DESKTOP-UI-CALC-CROSSING-CONTRACT-2026-09-04.md

NOT installed. NOT wired to openclaw.json. NOT on Chat tools.allow.
Enable only for isolated prove: set env KEVIN_DESKTOP_UI_V0_ENABLE=1.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

from . import refuse as refuse_mod

ROOT = Path(__file__).resolve().parents[1]
PS1 = ROOT / "calc_uia_prove.ps1"
ENABLE_ENV = "KEVIN_DESKTOP_UI_V0_ENABLE"


def is_enabled() -> bool:
    return os.environ.get(ENABLE_ENV, "").strip() in {"1", "true", "TRUE", "yes", "YES"}


def _disabled(action: str) -> dict:
    return {
        "ok": False,
        "error": "disabled_by_default",
        "action": action,
        "hint": f"set {ENABLE_ENV}=1 for isolated prove only; never live Chat",
        "openclaw_untouched": True,
        "candidate_only": True,
        "live": False,
    }


def _ps(action: str, app: str = "calculator", control_id: str = "", text: str = "") -> dict:
    if not PS1.exists():
        return {"ok": False, "error": "missing_prove_script", "path": str(PS1)}
    cmd = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(PS1),
        "-Action",
        action,
        "-App",
        app,
    ]
    if control_id:
        cmd += ["-ControlId", control_id]
    if text:
        cmd += ["-Text", text]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout"}
    out = (proc.stdout or "").strip()
    for line in reversed(out.splitlines()):
        line = line.strip()
        if line.startswith("{") and line.endswith("}"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                continue
    return {
        "ok": False,
        "error": "non_json_output",
        "exit": proc.returncode,
        "stdout": out[-500:],
        "stderr": (proc.stderr or "")[-500:],
    }


def focus_app(app: str) -> dict:
    if not is_enabled():
        return _disabled("focus")
    bad = refuse_mod.check_app(app)
    if bad:
        return bad
    return _ps("focus", app=app)


def click_control(app: str, control_id: str) -> dict:
    if not is_enabled():
        return _disabled("click")
    bad = refuse_mod.check_app(app)
    if bad:
        return bad
    bad = refuse_mod.check_control(control_id)
    if bad:
        return bad
    return _ps("click", app=app, control_id=control_id)


def type_text(app: str, text: str) -> dict:
    if not is_enabled():
        return _disabled("type")
    bad = refuse_mod.check_app(app)
    if bad:
        return bad
    bad = refuse_mod.check_text(text)
    if bad:
        return bad
    return _ps("type", app=app, text=text)


def run_prove() -> dict:
    if not is_enabled():
        return _disabled("prove")
    return _ps("prove", app="calculator")


def tool_dispatch(tool: str, params: dict | None = None) -> dict:
    """Plugin-shaped dispatcher. Always refuse when disabled."""
    params = params or {}
    if tool == "kevin_ui_focus_app":
        return focus_app(str(params.get("app", "")))
    if tool == "kevin_ui_click":
        return click_control(str(params.get("app", "")), str(params.get("control_id", "")))
    if tool == "kevin_ui_type":
        return type_text(str(params.get("app", "")), str(params.get("text", "")))
    return {"ok": False, "error": "unknown_tool", "tool": tool, "candidate_only": True}


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "status"
    if mode == "status":
        print(
            json.dumps(
                {
                    "ok": True,
                    "enabled": is_enabled(),
                    "refuse_by_default": True,
                    "live": False,
                    "openclaw_registration": False,
                    "chat_tools_allow": False,
                    "catalog": str(refuse_mod.CATALOG),
                },
                indent=2,
            )
        )
        sys.exit(0)
    if mode == "refuse-unit":
        out = refuse_mod.run_refuse_unit()
        print(json.dumps(out, indent=2))
        sys.exit(0 if out["ok"] else 2)
    if mode == "prove":
        refuse = refuse_mod.run_refuse_unit()
        prove = run_prove()
        out = {
            "refuse_unit": refuse,
            "prove": prove,
            "openclaw_untouched": True,
            "candidate_only": True,
            "enabled": is_enabled(),
        }
        print(json.dumps(out, indent=2))
        marker = (prove or {}).get("marker") or (prove or {}).get("token")
        if refuse.get("ok") and prove.get("ok") and marker:
            print(marker)
            sys.exit(0)
        print("KEVIN_DESKTOP_UI_CALC_V0_FAIL")
        sys.exit(1)
    if mode in {"focus", "click", "type"}:
        # CLI smoke for disabled gate
        if mode == "focus":
            print(json.dumps(focus_app(sys.argv[2] if len(sys.argv) > 2 else "calculator")))
        elif mode == "click":
            print(
                json.dumps(
                    click_control(
                        sys.argv[2] if len(sys.argv) > 2 else "calculator",
                        sys.argv[3] if len(sys.argv) > 3 else "digit_1",
                    )
                )
            )
        else:
            print(
                json.dumps(
                    type_text(
                        sys.argv[2] if len(sys.argv) > 2 else "calculator",
                        sys.argv[3] if len(sys.argv) > 3 else "1",
                    )
                )
            )
        sys.exit(0)
    print(json.dumps({"ok": False, "error": "unknown_mode", "mode": mode}))
    sys.exit(2)
