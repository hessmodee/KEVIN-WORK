"""Refuse-by-default unit gate for kevin-desktop-ui-v0 (no UIA required)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "calculator-catalog.v0.json"
ALLOWED_APPS = frozenset({"calculator"})
SECRET_RE = re.compile(
    r"(?i)(password|passwd|secret|api[_-]?key|token|bearer\s+[A-Za-z0-9._\-]{8,}|AKIA[0-9A-Z]{16})"
)
MAX_TYPE_LEN = 64


def catalog_ids() -> set[str]:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    return {c["id"] for c in data.get("controls", [])}


def check_app(app: str) -> dict | None:
    if app not in ALLOWED_APPS:
        return {"ok": False, "error": "invalid_app", "app": app}
    return None


def check_control(control_id: str) -> dict | None:
    if control_id not in catalog_ids():
        return {"ok": False, "error": "invalid_control", "control_id": control_id}
    return None


def check_text(text: str) -> dict | None:
    text = text or ""
    if SECRET_RE.search(text):
        return {"ok": False, "error": "secret_deny", "length": len(text)}
    if len(text) > MAX_TYPE_LEN:
        return {"ok": False, "error": "text_too_long", "length": len(text), "max": MAX_TYPE_LEN}
    return None


def run_refuse_unit() -> dict:
    cases = []
    r = check_app("notepad")
    cases.append({"test": "invalid_app", "pass": bool(r and r.get("error") == "invalid_app"), "result": r})
    r = check_control("not_a_real_control")
    cases.append({"test": "invalid_control", "pass": bool(r and r.get("error") == "invalid_control"), "result": r})
    r = check_text("password=hunter2")
    cases.append({"test": "secret_deny", "pass": bool(r and r.get("error") == "secret_deny"), "result": r})
    r = check_text("1" * 65)
    cases.append({"test": "text_too_long", "pass": bool(r and r.get("error") == "text_too_long"), "result": r})
    ok = all(c["pass"] for c in cases)
    return {"ok": ok, "action": "refuse_unit", "results": cases, "candidate_only": True}


if __name__ == "__main__":
    out = run_refuse_unit()
    print(json.dumps(out, indent=2))
    sys.exit(0 if out["ok"] else 2)
