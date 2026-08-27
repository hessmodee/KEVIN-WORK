"""Kevin-owned dashboard writers. Updates task + events only. No HTML."""
import json, os, sys
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
os.makedirs(REPORTS, exist_ok=True)


def iso():
    d = datetime.now(TZ) if TZ else datetime.now()
    return d.strftime("%Y-%m-%dT%H:%M:%S-06:00")


def write_json(path, obj):
    open(path, "w", encoding="utf-8").write(json.dumps(obj, indent=2) + "\n")


def event(component, event, detail, result=""):
    rec = {
        "at": iso(),
        "component": component,
        "event": event,
        "detail": detail,
        "result": result,
    }
    with open(EVENTS, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=True) + "\n")
    return rec


def cmd_start(tid, title, category="reader"):
    obj = {
        "id": tid,
        "title": title,
        "category": category,
        "phase": "started",
        "completed": 0,
        "total": None,
        "started_at": iso(),
    }
    write_json(TASK, obj)
    event("kevin", "task_start", title, "")
    print("started", tid)
    return 0


def cmd_progress(tid, phase, completed, total):
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
    event("kevin", "task_progress", "%s %s/%s" % (obj.get("title", tid), completed, total), "")
    print("progress", completed, "/", total)
    return 0


def cmd_finish(tid, result, summary=""):
    title = tid
    if os.path.isfile(TASK):
        try:
            title = json.loads(open(TASK, encoding="utf-8").read()).get("title", tid)
        except Exception:
            pass
    if os.path.isfile(TASK):
        os.remove(TASK)
    event("kevin", "task_finish", summary or title, result.lower())
    print("finished", result)
    return 0


def cmd_event(kind, message):
    event("kevin", kind, message, "")
    print("event", kind)
    return 0


def cmd_capability(cap, test, result):
    event("qa", "capability", "%s / %s" % (cap, test), result.lower())
    print("capability", cap, result)
    return 0


def main(argv):
    if len(argv) < 2:
        print("usage: start|progress|finish|event|capability ...")
        return 1
    op = argv[1]
    a = argv[2:]
    if op == "start":
        return cmd_start(a[0], a[1] if len(a) > 1 else a[0], a[2] if len(a) > 2 else "reader")
    if op == "progress":
        return cmd_progress(a[0], a[1], a[2], a[3])
    if op == "finish":
        return cmd_finish(a[0], a[1], a[2] if len(a) > 2 else "")
    if op == "event":
        return cmd_event(a[0], " ".join(a[1:]) if len(a) > 1 else a[0])
    if op == "capability":
        return cmd_capability(a[0], a[1], a[2])
    print("unknown", op)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
