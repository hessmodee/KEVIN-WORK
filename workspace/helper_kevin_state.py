"""Kevin-owned dashboard writers. Only approved mutation path. No HTML."""
import json, os, sys, time, subprocess
from datetime import datetime

try:
    from zoneinfo import ZoneInfo
    TZ = ZoneInfo("America/Boise")
except Exception:
    TZ = None

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
REPORTS = os.path.join(ROOT, "reports")
TASK = os.path.join(REPORTS, "kevin-task.json")
EVENTS = os.path.join(REPORTS, "kevin-events.jsonl")
STAMP = os.path.join(REPORTS, "dash-publish-last.txt")
os.makedirs(REPORTS, exist_ok=True)

SOURCES = (
    "kevin-reader", "kevin-operator", "kevin-chat", "kevin-tick",
    "qa", "bridge", "manual", "grok-build",
)


def iso():
    d = datetime.now(TZ) if TZ else datetime.now()
    return d.strftime("%Y-%m-%dT%H:%M:%S-06:00")


def write_json(path, obj):
    open(path, "w", encoding="utf-8").write(json.dumps(obj, indent=2) + "\n")


def src(explicit=None):
    s = explicit or os.environ.get("KEVIN_SOURCE") or "manual"
    if s not in SOURCES:
        s = "manual"
    return s


def event(source, component, event, detail, result="", task_id="", duration_ms=None):
    rec = {
        "at": iso(),
        "source": src(source),
        "component": component,
        "event": event,
        "detail": detail,
        "result": result,
        "task_id": task_id or "",
    }
    if duration_ms is not None:
        rec["duration_ms"] = int(duration_ms)
    with open(EVENTS, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=True) + "\n")
    return rec


def rebuild_and_publish(force=False):
    dash = os.path.join(ROOT, "helper_dashboard_state.py")
    if os.path.isfile(dash):
        subprocess.run([sys.executable, dash], cwd=ROOT, check=False)
    now = time.time()
    last = 0.0
    if os.path.isfile(STAMP):
        try:
            last = float(open(STAMP, encoding="utf-8").read().strip() or "0")
        except Exception:
            last = 0.0
    if (not force) and (now - last < 45):
        print("publish skipped (rate limit)")
        return
    pub = os.path.join(ROOT, "kevin-publish-dash.ps1")
    if os.path.isfile(pub):
        subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", pub],
            check=False,
        )
        open(STAMP, "w", encoding="utf-8").write(str(now))
        print("dashboard publish queued")


def cmd_start(tid, title, category="reader", source=None):
    obj = {
        "id": tid,
        "title": title,
        "category": category,
        "phase": "started",
        "completed": 0,
        "total": None,
        "started_at": iso(),
        "source": src(source),
    }
    write_json(TASK, obj)
    event(source, category, "task_start", title, "", tid)
    rebuild_and_publish(True)
    print("started", tid)
    return 0


def cmd_progress(tid, phase, completed, total, source=None):
    obj = {}
    if os.path.isfile(TASK):
        try:
            obj = json.loads(open(TASK, encoding="utf-8").read())
        except Exception:
            obj = {}
    obj.update({
        "id": tid,
        "phase": phase,
        "completed": int(completed),
        "total": int(total),
        "updated_at": iso(),
    })
    if "title" not in obj:
        obj["title"] = tid
    write_json(TASK, obj)
    event(source, obj.get("category", "reader"), "task_progress",
          "%s %s/%s" % (obj.get("title", tid), completed, total), "", tid)
    rebuild_and_publish(False)
    print("progress", completed, "/", total)
    return 0


def cmd_finish(tid, result, summary="", source=None, duration_ms=None):
    title, category = tid, "reader"
    started = None
    if os.path.isfile(TASK):
        try:
            t = json.loads(open(TASK, encoding="utf-8").read())
            title = t.get("title", tid)
            category = t.get("category", category)
            started = t.get("started_at")
        except Exception:
            pass
        os.remove(TASK)
    ms = duration_ms
    if ms is None and started:
        try:
            a = datetime.fromisoformat(started[:19])
            b = datetime.fromisoformat(iso()[:19])
            ms = int((b - a).total_seconds() * 1000)
        except Exception:
            ms = None
    event(source, category, "task_finish", summary or title, result.lower(), tid, ms)
    rebuild_and_publish(True)
    print("finished", result)
    return 0


def cmd_event(kind, message, source=None, component="kevin"):
    event(source, component, kind, message, "")
    rebuild_and_publish(False)
    print("event", kind)
    return 0


def cmd_capability(cap, test, result, source="qa"):
    event(source, cap, "capability", "%s / %s" % (cap, test), result.lower())
    rebuild_and_publish(True)
    print("capability", cap, result)
    return 0


def main(argv):
    if len(argv) < 2:
        print("usage: start|progress|finish|event|capability ... [--source NAME]")
        return 1
    args = list(argv[1:])
    source = os.environ.get("KEVIN_SOURCE")
    if "--source" in args:
        i = args.index("--source")
        source = args[i + 1] if i + 1 < len(args) else source
        del args[i:i + 2]
    op = args[0]
    a = args[1:]
    if op == "start":
        return cmd_start(a[0], a[1] if len(a) > 1 else a[0], a[2] if len(a) > 2 else "reader", source)
    if op == "progress":
        return cmd_progress(a[0], a[1], a[2], a[3], source)
    if op == "finish":
        return cmd_finish(a[0], a[1], a[2] if len(a) > 2 else "", source)
    if op == "event":
        return cmd_event(a[0], " ".join(a[1:]) if len(a) > 1 else a[0], source)
    if op == "capability":
        return cmd_capability(a[0], a[1], a[2], source or "qa")
    print("unknown", op)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
