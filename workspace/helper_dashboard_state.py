"""Build reports/dashboard-state.json for public Kevin HQ. Sanitized. No paths, users, ports."""
import json, os, re
from datetime import datetime

try:
    from zoneinfo import ZoneInfo
    TZ = ZoneInfo("America/Boise")
except Exception:
    TZ = None

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
REPORTS = os.path.join(ROOT, "reports")
os.makedirs(REPORTS, exist_ok=True)


def now():
    d = datetime.now(TZ) if TZ else datetime.now()
    return d, d.strftime("%Y-%m-%dT%H:%M:%S") + ("-06:00" if TZ else "")


def read(name):
    p = os.path.join(REPORTS, name)
    if not os.path.isfile(p):
        return ""
    try:
        return open(p, encoding="utf-8", errors="replace").read()
    except Exception:
        return ""


def kv_lines(text):
    out = {}
    for line in text.splitlines():
        if ":" in line and not line.startswith("#"):
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


def pct(s):
    m = re.search(r"(\d+)", str(s) or "")
    return int(m.group(1)) if m else None


def healthy(val):
    v = (val or "").lower()
    if any(x in v for x in ("running", "open", "pass", "healthy", "ok")):
        return "healthy"
    if any(x in v for x in ("down", "closed", "fail")):
        return "unhealthy"
    return "unknown"


def weather_summary(text):
    lines = [ln.strip() for ln in text.splitlines() if ln.strip() and not ln.startswith("#")]
    skip = ("preston", "idaho", "83263", "place:")
    keep = [ln for ln in lines if not any(s in ln.lower() for s in skip)]
    return " · ".join(keep[:3]) if keep else ""


def append_event(at, component, event, detail, result):
    path = os.path.join(REPORTS, "kevin-events.jsonl")
    rec = {"at": at, "component": component, "event": event, "detail": detail, "result": result}
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=True) + "\n")
    return rec


def last_events(n=12):
    path = os.path.join(REPORTS, "kevin-events.jsonl")
    if not os.path.isfile(path):
        return []
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    out = []
    for ln in lines[-n:]:
        try:
            out.append(json.loads(ln))
        except Exception:
            pass
    return list(reversed(out))


def main():
    ts, iso = now()
    sysd = kv_lines(read("system-status.md"))
    check = read("self-check.md")
    wx = weather_summary(read("weather-83263.md"))
    fails = 0
    m = re.search(r"fails:\s*(\d+)", check)
    if m:
        fails = int(m.group(1))
    bridge = "unknown"
    try:
        b = json.loads(read("bridge-latest.json") or "{}")
        bridge = "healthy" if str(b.get("bridge", "")).upper() in ("PASS", "OK") else "degraded"
        if str(b.get("pull", "")).upper() == "FAIL" or str(b.get("publish", "")).upper() == "FAIL":
            bridge = "degraded"
    except Exception:
        pass

    ollama = healthy(sysd.get("Ollama"))
    gateway = healthy(next((sysd[k] for k in sysd if "gateway" in k.lower()), ""))
    mem = pct(sysd.get("RAM load"))
    cpu = pct(sysd.get("CPU load"))
    gpu_util = pct(sysd.get("GPU utilization"))
    gpu_name = sysd.get("GPU", "RTX 3060")
    gpu_name = re.sub(r"NVIDIA GeForce ", "", gpu_name)

    overall = "healthy"
    if fails or ollama != "healthy" or gateway != "healthy" or bridge == "degraded":
        overall = "degraded"

    status = "idle"
    if overall == "degraded":
        status = "degraded"

    caps = [
        {"id": "chat", "label": "Local conversation", "state": "proven", "note": "Qwen 14B Chat, no tools"},
        {"id": "system_reader", "label": "System awareness", "state": "testing", "note": "Helpers exist; Chat cannot call them"},
        {"id": "weather_reader", "label": "Local weather", "state": "testing", "note": "Tick writes forecast"},
        {"id": "retrieval", "label": "Knowledge retrieval", "state": "planned", "note": ""},
        {"id": "file_actions", "label": "Controlled file actions", "state": "locked", "note": ""},
        {"id": "email", "label": "Email", "state": "locked", "note": ""},
        {"id": "windows_ui", "label": "Windows control", "state": "locked", "note": ""},
    ]
    owl_level = 1
    if caps[1]["state"] == "proven":
        owl_level = 2
    if caps[3]["state"] == "proven":
        owl_level = 3
    if caps[4]["state"] == "proven":
        owl_level = 4
    if caps[5]["state"] == "proven" and owl_level >= 4:
        owl_level = 5

    owl_state = "warning" if status == "degraded" else "idle"
    ev = append_event(iso, "tick", "cycle", "Scheduled health cycle", "pass" if fails == 0 else "fail")

    state = {
        "schema": 1,
        "generated_at": iso,
        "status": status,
        "health": {"overall": overall, "failed_checks": fails},
        "brain": {"name": "Qwen 2.5 14B", "mode": "Chat", "context": "8K", "tools": False},
        "current_task": None,
        "services": {"tick": "healthy", "bridge": bridge, "ollama": ollama, "gateway": gateway},
        "system": {"memory_pct": mem, "cpu_pct": cpu, "gpu": gpu_name, "gpu_pct": gpu_util},
        "weather": {"summary": wx},
        "capabilities": caps,
        "build": [
            {"id": "reader", "label": "Reader - one typed status tool", "state": "next"},
            {"id": "memory", "label": "Memory / retrieval", "state": "queued"},
            {"id": "operator", "label": "Operator - allowlisted hands", "state": "queued"},
            {"id": "integrations", "label": "Email / Office", "state": "queued"},
        ],
        "activity": last_events(12) or [ev],
        "owl": {"level": owl_level, "state": owl_state},
        "sync": {"last": iso, "source": "KevinTick"},
        "self_check": {"fails": fails, "summary": "All checks passed" if fails == 0 else ("%s check(s) failed" % fails)},
    }
    path = os.path.join(REPORTS, "dashboard-state.json")
    open(path, "w", encoding="utf-8").write(json.dumps(state, indent=2) + "\n")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
