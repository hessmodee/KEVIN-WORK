"""Public dashboard-state.json. Sanitized. Preserves Kevin task + pulse history."""
import json, os, re
from datetime import datetime, timedelta

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
    return d, d.strftime("%Y-%m-%dT%H:%M:%S-06:00")


def read(name):
    p = os.path.join(REPORTS, name)
    if not os.path.isfile(p):
        return ""
    try:
        return open(p, encoding="utf-8", errors="replace").read()
    except Exception:
        return ""


def read_json(name, default):
    raw = read(name)
    if not raw.strip():
        return default
    try:
        return json.loads(raw)
    except Exception:
        return default


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
    return " | ".join(keep[:3]) if keep else ""


def load_events():
    path = os.path.join(REPORTS, "kevin-events.jsonl")
    if not os.path.isfile(path):
        return []
    out = []
    for ln in open(path, encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if not ln:
            continue
        try:
            out.append(json.loads(ln))
        except Exception:
            pass
    return out


def append_event(at, component, event, detail, result):
    path = os.path.join(REPORTS, "kevin-events.jsonl")
    rec = {"at": at, "component": component, "event": event, "detail": detail, "result": result}
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=True) + "\n")
    return rec


def meaningful(events):
    keep = []
    last_tick = None
    for e in events:
        if e.get("event") == "cycle" and e.get("component") == "tick":
            last_tick = e
            continue
        keep.append(e)
    if last_tick:
        keep.append(last_tick)
    return list(reversed(keep[-18:]))


def health_24h(events):
    ticks = [e for e in events if e.get("component") == "tick" and e.get("event") == "cycle"]
    if not ticks:
        return {"done": 1, "total": 1}
    done = sum(1 for e in ticks if str(e.get("result", "")).lower() in ("pass", "ok", ""))
    return {"done": done, "total": max(len(ticks), 1)}


def pulse_append(sample):
    hist = read_json("system-history.json", {"ram": [], "cpu": [], "gpu": []})
    for k in ("ram", "cpu", "gpu"):
        arr = list(hist.get(k) or [])
        val = sample.get(k)
        if val is None:
            continue
        arr.append(val)
        hist[k] = arr[-96:]
    open(os.path.join(REPORTS, "system-history.json"), "w", encoding="utf-8").write(json.dumps(hist) + "\n")
    return hist


def main():
    ts, iso = now()
    sysd = kv_lines(read("system-status.md"))
    check = read("self-check.md")
    wx = weather_summary(read("weather-83263.md"))
    fails = 0
    m = re.search(r"fails:\s*(\d+)", check)
    if m:
        fails = int(m.group(1))
    b = read_json("bridge-latest.json", {})
    bridge = "healthy" if str(b.get("bridge", "")).upper() in ("PASS", "OK") else "unknown"
    if str(b.get("pull", "")).upper() == "FAIL" or str(b.get("publish", "")).upper() == "FAIL":
        bridge = "degraded"
    ollama = healthy(sysd.get("Ollama"))
    gateway = healthy(next((sysd[k] for k in sysd if "gateway" in k.lower()), ""))
    mem = pct(sysd.get("RAM load"))
    cpu = pct(sysd.get("CPU load"))
    gpu_util = pct(sysd.get("GPU utilization"))
    gpu_name = re.sub(r"NVIDIA GeForce ", "", sysd.get("GPU", "RTX 3060"))
    overall = "healthy"
    if fails or ollama != "healthy" or gateway != "healthy" or bridge == "degraded":
        overall = "degraded"
    task = read_json("kevin-task.json", None)
    if task == {}:
        task = None
    status = "working" if task else "idle"
    if overall == "degraded":
        status = "degraded"
    ev = append_event(iso, "tick", "cycle", "Health cycle", "pass" if fails == 0 else "fail")
    events = load_events()
    h24 = health_24h(events)
    hist = pulse_append({"ram": mem, "cpu": cpu, "gpu": gpu_util})
    caps = [
        {"id": "chat", "label": "Local conversation", "state": "proven", "qa_pass": 18, "qa_total": 18, "version": "Chat v2", "last_verified": "2026-08-26"},
        {"id": "system_reader", "label": "System awareness", "state": "testing", "qa_pass": 0, "qa_total": 20, "version": "Reader v0", "last_verified": None},
        {"id": "weather_reader", "label": "Local weather", "state": "testing", "qa_pass": 0, "qa_total": 10, "version": None, "last_verified": None},
        {"id": "retrieval", "label": "Knowledge and memory", "state": "planned", "qa_pass": 0, "qa_total": 5, "version": None, "last_verified": None},
        {"id": "file_actions", "label": "Controlled actions", "state": "locked", "qa_pass": 0, "qa_total": 6, "version": None, "last_verified": None},
        {"id": "email", "label": "Communications", "state": "locked", "qa_pass": 0, "qa_total": 4, "version": None, "last_verified": None},
        {"id": "windows_ui", "label": "Windows interaction", "state": "locked", "qa_pass": 0, "qa_total": 4, "version": None, "last_verified": None},
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
    owl_state = "working" if status == "working" else ("warning" if status == "degraded" else "idle")
    progress = [
        {"id": "chat_qa", "label": "Chat reliability", "done": 18, "total": 18},
        {"id": "reader", "label": "System Reader", "done": 0, "total": 4},
        {"id": "knowledge", "label": "Knowledge", "done": 0, "total": 5},
        {"id": "operator", "label": "Operator", "done": 0, "total": 6},
        {"id": "health_24h", "label": "System health 24h", "done": h24["done"], "total": h24["total"]},
    ]
    state = {
        "schema": 2,
        "generated_at": iso,
        "status": status,
        "health": {"overall": overall, "failed_checks": fails},
        "brain": {"name": "Qwen 2.5 14B", "mode": "Chat Fast", "context": "8K", "tools": False},
        "current_task": task,
        "services": {"tick": "healthy", "bridge": bridge, "ollama": ollama, "gateway": gateway},
        "system": {"memory_pct": mem, "cpu_pct": cpu, "gpu": gpu_name, "gpu_pct": gpu_util},
        "pulse": {"ram": hist.get("ram") or [], "cpu": hist.get("cpu") or [], "gpu": hist.get("gpu") or []},
        "weather": {"summary": wx},
        "capabilities": caps,
        "progress": progress,
        "roadmap": {"done": sum(1 for c in caps if c["state"] == "proven"), "total": len(caps), "label": "Roadmap completion"},
        "build": [
            {"id": "senses", "label": "System Awareness", "state": "next", "detail": "Reader v1, 0 of 4 sensors"},
            {"id": "memory", "label": "Knowledge and Memory", "state": "queued", "detail": ""},
            {"id": "hands", "label": "Controlled Actions", "state": "queued", "detail": ""},
            {"id": "comms", "label": "Communications", "state": "queued", "detail": ""},
            {"id": "windows", "label": "Windows Interaction", "state": "queued", "detail": ""},
        ],
        "activity": meaningful(events) or [ev],
        "owl": {"level": owl_level, "state": owl_state},
        "sync": {"last": iso, "source": "HESS-PC"},
        "self_check": {"fails": fails, "summary": "All checks passed" if fails == 0 else ("%s check(s) failed" % fails)},
        "diagnostics": {"agent": "kevin-lab-qwen", "model": "qwen2.5:14b", "context": "8K", "tools": 0, "chat_qa": "18/18", "noreply": 0},
    }
    path = os.path.join(REPORTS, "dashboard-state.json")
    open(path, "w", encoding="utf-8").write(json.dumps(state, indent=2) + "\n")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
