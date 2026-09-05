"""Fail-closed Calculator UI control scratch — Phase 1 prove.
PLAN: docs/engineering/PLAN-kevin-desktop-ui-control-2026-09-04.md
Not installed. Not wired to openclaw.json. Not on Chat.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PS1 = ROOT / "calc_uia_prove.ps1"
CATALOG = ROOT / "calculator-catalog.v0.json"
ALLOWED_APPS = frozenset({"calculator"})
SECRET_RE = re.compile(
    r"(?i)(password|passwd|secret|api[_-]?key|token|bearer\s+[A-Za-z0-9._\-]{8,}|AKIA[0-9A-Z]{16})"
)
MAX_TYPE_LEN = 64


def _catalog_ids() -> set[str]:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    return {c["id"] for c in data.get("controls", [])}


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
    # Last JSON line wins
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
    if app not in ALLOWED_APPS:
        return {"ok": False, "error": "invalid_app", "app": app}
    return _ps("focus", app=app)


def click_control(app: str, control_id: str) -> dict:
    if app not in ALLOWED_APPS:
        return {"ok": False, "error": "invalid_app", "app": app}
    if control_id not in _catalog_ids():
        return {"ok": False, "error": "invalid_control", "app": app, "control_id": control_id}
    return _ps("click", app=app, control_id=control_id)


def type_text(app: str, text: str) -> dict:
    if app not in ALLOWED_APPS:
        return {"ok": False, "error": "invalid_app", "app": app}
    text = text or ""
    if SECRET_RE.search(text):
        return {"ok": False, "error": "secret_deny", "length": len(text)}
    if len(text) > MAX_TYPE_LEN:
        return {"ok": False, "error": "text_too_long", "length": len(text), "max": MAX_TYPE_LEN}
    return _ps("type", app=app, text=text)


def run_prove() -> dict:
    return _ps("prove", app="calculator")


def run_refuse_unit() -> dict:
    """Local unit denies without needing UIA (except optional PS refuse-tests)."""
    cases = []
    r = focus_app("notepad")
    cases.append({"test": "invalid_app", "pass": r.get("error") == "invalid_app", "result": r})
    r = click_control("calculator", "not_a_real_control")
    cases.append({"test": "invalid_control", "pass": r.get("error") == "invalid_control", "result": r})
    r = type_text("calculator", "password=hunter2")
    cases.append({"test": "secret_deny", "pass": r.get("error") == "secret_deny", "result": r})
    r = type_text("calculator", "1" * 65)
    cases.append({"test": "text_too_long", "pass": r.get("error") == "text_too_long", "result": r})
    ok = all(c["pass"] for c in cases)
    return {"ok": ok, "action": "refuse_unit", "results": cases}


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "prove"
    if mode == "refuse-unit":
        print(json.dumps(run_refuse_unit(), indent=2))
        sys.exit(0 if run_refuse_unit()["ok"] else 2)
    if mode == "prove":
        refuse = run_refuse_unit()
        prove = run_prove()
        out = {
            "refuse_unit": refuse,
            "prove": prove,
            "openclaw_untouched": True,
            "scratch_only": True,
        }
        print(json.dumps(out, indent=2))
        marker = (prove or {}).get("marker") or (prove or {}).get("token")
        if refuse.get("ok") and prove.get("ok") and marker:
            print(marker)
            sys.exit(0)
        print("KEVIN_DESKTOP_UI_CALC_V0_FAIL")
        sys.exit(1)
    if mode == "stub":
        print("KEVIN_DESKTOP_UI_V0_STUB refuse_by_default=false prove_impl=ps1 openclaw_untouched=true")
        sys.exit(0)
    print(json.dumps({"ok": False, "error": "unknown_mode", "mode": mode}))
    sys.exit(2)
