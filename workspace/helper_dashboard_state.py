"""Public dashboard-state.json. Sanitized, ordered, and timestamped for Kevin HQ."""
import json, os, re
from datetime import datetime, timedelta, timezone

try:
    from zoneinfo import ZoneInfo
    TZ = ZoneInfo("America/Boise")
except Exception:
    TZ = None

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
REPORTS = os.path.join(ROOT, "reports")
READER_ROOT = os.path.join(os.path.expanduser("~"), ".openclaw-reader")
DESIGN_ROOT = os.path.join(ROOT, "forge-designs")
LEGACY_FORGE_ROOT = os.path.join(ROOT, "forge-candidates")
os.makedirs(REPORTS, exist_ok=True)

FORBIDDEN = [
    (re.compile(r"C:\\Users", re.I), "[path]"),
    (re.compile(r"hessm", re.I), "[user]"),
    (re.compile(r":18789\b"), ""),
    (re.compile(r"127\.0\.0\.1"), "[local]"),
    (re.compile(r"xai-[A-Za-z0-9]{8,}"), "[redacted]"),
    (re.compile(r"ghp_[A-Za-z0-9]{8,}"), "[redacted]"),
]


def now():
    d = datetime.now(TZ) if TZ else datetime.now().astimezone()
    return d, d.isoformat(timespec="seconds")


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


def read_json_path(path, default):
    if not os.path.isfile(path):
        return default
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return json.load(f)
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


def parse_time(value):
    """Return an aware UTC datetime for safe ordering/comparison."""
    if not value:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)
    try:
        d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        if d.tzinfo is None or d.utcoffset() is None:
            local_tz = TZ or datetime.now().astimezone().tzinfo or timezone.utc
            d = d.replace(tzinfo=local_tz)
        return d.astimezone(timezone.utc)
    except Exception:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)


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
    """Newest first; collapse repetitive tick cycles to the latest one."""
    keep = []
    latest_tick = None
    for e in events:
        if e.get("event") == "cycle" and e.get("component") == "tick":
            if latest_tick is None or parse_time(e.get("at")) > parse_time(latest_tick.get("at")):
                latest_tick = e
            continue
        keep.append(e)
    if latest_tick:
        keep.append(latest_tick)
    keep.sort(key=lambda e: parse_time(e.get("at")), reverse=True)
    return keep[:24]


def health_24h(events):
    current = datetime.now(TZ) if TZ else datetime.now().astimezone()
    cutoff = (current - timedelta(hours=24)).astimezone(timezone.utc)
    ticks = [
        e for e in events
        if e.get("component") == "tick"
        and e.get("event") == "cycle"
        and parse_time(e.get("at")) >= cutoff
    ]
    if not ticks:
        return {"done": 1, "total": 1}
    done = sum(1 for e in ticks if str(e.get("result", "")).lower() in ("pass", "ok", ""))
    return {"done": done, "total": max(len(ticks), 1)}


def _legacy_samples(hist, current_dt):
    arrays = {k: list(hist.get(k) or []) for k in ("ram", "cpu", "gpu")}
    n = max((len(v) for v in arrays.values()), default=0)
    if not n:
        return []
    start = current_dt - timedelta(minutes=15 * (n - 1))
    samples = []
    for i in range(n):
        rec = {
            "at": (start + timedelta(minutes=15 * i)).isoformat(timespec="seconds"),
            "estimated": True,
        }
        for k in ("ram", "cpu", "gpu"):
            arr = arrays[k]
            offset = n - len(arr)
            if i >= offset:
                rec[k] = arr[i - offset]
        samples.append(rec)
    return samples


def pulse_append(sample, at, current_dt):
    path = os.path.join(REPORTS, "system-history.json")
    hist = read_json("system-history.json", {})
    samples = list(hist.get("samples") or []) if isinstance(hist, dict) else []
    if not samples and isinstance(hist, dict):
        samples = _legacy_samples(hist, current_dt)

    rec = {"at": at, "estimated": False}
    for k in ("ram", "cpu", "gpu"):
        val = sample.get(k)
        if val is not None:
            rec[k] = val
    samples.append(rec)
    samples = samples[-96:]

    new_hist = {"schema": 2, "interval_minutes": 15, "samples": samples}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(new_hist, f, ensure_ascii=True)
        f.write("\n")
    return new_hist


def reader_green():
    g = read_json_path(os.path.join(READER_ROOT, "READER-GREEN.json"), {})
    if str(g.get("status", "")).upper() != "GREEN":
        return None
    return g


def candidate_status():
    """Prefer the proven Design Forge v3 state; retain legacy Candidate Forge fallback."""
    s = read_json_path(os.path.join(DESIGN_ROOT, "design-forge-state.json"), {})
    if s:
        result = str(s.get("status") or s.get("last_result") or "unknown").lower()
        return {
            "result": result,
            "mode": "design-forge-v3",
            "last_mission": s.get("last_mission"),
            "iteration": s.get("last_iteration") or s.get("iteration"),
            "updated_at": s.get("updated_at"),
            "next_index": s.get("next_index"),
            "scheduled": True,
            "promotion": "blocked",
        }

    legacy = read_json_path(os.path.join(LEGACY_FORGE_ROOT, "candidate-forge-state.json"), {})
    if legacy:
        return {
            "result": str(legacy.get("last_result") or "unknown").lower(),
            "mode": "legacy-candidate-forge",
            "last_mission": legacy.get("last_mission"),
            "iteration": legacy.get("last_iteration"),
            "updated_at": legacy.get("updated_at"),
            "scheduled": False,
            "promotion": "blocked",
        }

    err = os.path.join(LEGACY_FORGE_ROOT, "candidate-forge-last-error.txt")
    if os.path.isfile(err):
        return {
            "result": "legacy_fail",
            "mode": "legacy-candidate-forge",
            "last_mission": None,
            "iteration": None,
            "updated_at": None,
            "scheduled": False,
            "promotion": "blocked",
        }

    return {
        "result": "not_started",
        "mode": "design-forge-v3",
        "last_mission": None,
        "iteration": None,
        "updated_at": None,
        "scheduled": True,
        "promotion": "blocked",
    }


def scrub(obj):
    if isinstance(obj, dict):
        return {k: scrub(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [scrub(v) for v in obj]
    if isinstance(obj, str):
        s = obj
        for pat, repl in FORBIDDEN:
            s = pat.sub(repl, s)
        return s
    return obj


def main():
    ts, iso = now()
    js = read_json("system-status.json", {})
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

    if js:
        ollama = healthy(js.get("ollama_status"))
        gateway = healthy(js.get("gateway_status"))
        mem = js.get("ram_load_percent")
        cpu = js.get("cpu_percent")
        gpu_util = js.get("gpu_percent")
        gpu_name = re.sub(r"NVIDIA GeForce ", "", str(js.get("gpu_name") or "RTX 3060"))
    else:
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

    ev = None
    if os.environ.get("KEVIN_SKIP_TICK") != "1":
        ev = append_event(iso, "tick", "cycle", "Health cycle", "pass" if fails == 0 else "fail")

    events = load_events()
    h24 = health_24h(events)
    hist = pulse_append({"ram": mem, "cpu": cpu, "gpu": gpu_util}, iso, ts)
    samples = hist.get("samples") or []

    rg = reader_green()
    reader_version = "Reader v0.1 · boundary GREEN" if rg else "Reader v0"
    reader_verified = (rg or {}).get("frozen_at") if rg else None
    auto = candidate_status()

    caps = [
        {"id": "chat", "label": "Local conversation", "state": "proven", "qa_pass": 18, "qa_total": 18, "version": "Chat v2", "last_verified": "2026-08-26"},
        {"id": "system_reader", "label": "System awareness", "state": "testing", "qa_pass": 0, "qa_total": 20, "version": reader_version, "last_verified": reader_verified},
        {"id": "weather_reader", "label": "Local weather", "state": "planned", "qa_pass": 0, "qa_total": 10, "version": None, "last_verified": None},
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
        {"id": "reader", "label": "Reader senses", "done": 0, "total": 4},
        {"id": "knowledge", "label": "Knowledge", "done": 0, "total": 5},
        {"id": "operator", "label": "Operator", "done": 0, "total": 6},
        {"id": "health_24h", "label": "System health 24h", "done": h24["done"], "total": h24["total"]},
    ]

    build = [
        {"order": 1, "id": "reader_e2e", "label": "Prove System Reader E2E", "state": "next", "detail": "Real status question → exactly one typed tool → correct interpretation"},
        {"order": 2, "id": "reader_expand", "label": "Expand Reader senses", "state": "queued", "detail": "Weather → board → self-check, one proven tool at a time"},
        {"order": 3, "id": "knowledge", "label": "Knowledge retrieval", "state": "queued", "detail": "Curated local retrieval with evidence; read-only first"},
        {"order": 4, "id": "operator", "label": "Controlled Operator", "state": "queued", "detail": "Typed allowlisted actions with validation, evidence, and rollback"},
        {"order": 5, "id": "skills", "label": "High-value workflows", "state": "queued", "detail": "Skills built only on proven Reader, Knowledge, and Operator faculties"},
        {"order": 6, "id": "autonomy", "label": "Autonomous promotion science", "state": "queued", "detail": "Candidate vs control benchmarks; self-improving, never self-authorizing"},
    ]

    legacy = {
        "ram": [s.get("ram") for s in samples if s.get("ram") is not None],
        "cpu": [s.get("cpu") for s in samples if s.get("cpu") is not None],
        "gpu": [s.get("gpu") for s in samples if s.get("gpu") is not None],
    }

    state = {
        "schema": 3,
        "generated_at": iso,
        "status": status,
        "health": {"overall": overall, "failed_checks": fails},
        "brain": {"name": "Qwen 2.5 14B", "mode": "Chat Fast", "context": "8K", "tools": False},
        "current_task": task,
        "services": {"tick": "healthy", "bridge": bridge, "ollama": ollama, "gateway": gateway},
        "system": {"memory_pct": mem, "cpu_pct": cpu, "gpu": gpu_name, "gpu_pct": gpu_util},
        "pulse": {
            "window": "24h",
            "sample_interval_minutes": 15,
            "samples": samples,
            **legacy,
        },
        "weather": {"summary": wx},
        "capabilities": caps,
        "progress": progress,
        "roadmap": {"done": sum(1 for c in caps if c["state"] == "proven"), "total": len(caps), "label": "Roadmap completion"},
        "build": sorted(build, key=lambda x: x.get("order", 999)),
        "activity": meaningful(events) or ([ev] if ev else []),
        "owl": {"level": owl_level, "state": owl_state},
        "sync": {"last": iso, "source": "local runtime"},
        "self_check": {"fails": fails, "summary": "All checks passed" if fails == 0 else ("%s check(s) failed" % fails)},
        "autonomy": {
            "mode": "hourly_design" if auto.get("scheduled") else "manual",
            "state": auto.get("result"),
            "last_mission": auto.get("last_mission"),
            "iteration": auto.get("iteration"),
            "updated_at": auto.get("updated_at"),
            "promotion": auto.get("promotion", "blocked"),
        },
        "diagnostics": {
            "agent": "kevin-lab-qwen",
            "model": "qwen2.5:14b",
            "context": "8K",
            "tools": 0,
            "chat_qa": "18/18",
            "noreply": 0,
            "reader_boundary": "green" if rg else "not_proven",
            "reader_visible_tools": 1 if rg else None,
            "candidate_forge": auto,
        },
    }

    state = scrub(state)
    path = os.path.join(REPORTS, "dashboard-state.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
