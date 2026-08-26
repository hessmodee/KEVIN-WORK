import os, socket, urllib.request
from datetime import datetime
try:
    from zoneinfo import ZoneInfo
    tz = ZoneInfo("America/Boise")
except Exception:
    tz = None
now = datetime.now(tz) if tz else datetime.now()
root = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
reports = os.path.join(root, "reports")
os.makedirs(reports, exist_ok=True)
lines = ["# Self-check %s" % now.strftime("%Y-%m-%d %H:%M")]
fails = 0

def read_text(path):
    raw = open(path, "rb").read()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig")
    return raw.decode("utf-8", errors="replace")

def check(name, ok, detail):
    global fails
    if not ok:
        fails += 1
    lines.append("- %s: %s - %s" % ("PASS" if ok else "FAIL", name, detail))

def age_min(path):
    if not os.path.exists(path):
        return None
    return (datetime.now() - datetime.fromtimestamp(os.path.getmtime(path))).total_seconds() / 60.0

try:
    urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=3).read()
    check("ollama", True, "11434 answering")
except Exception as e:
    check("ollama", False, str(e))

sock = socket.socket()
sock.settimeout(2)
try:
    sock.connect(("127.0.0.1", 18789))
    sock.close()
    check("gateway", True, "18789 open")
except Exception as e:
    check("gateway", False, str(e))

wx = os.path.join(reports, "weather-83263.md")
a = age_min(wx)
check("weather-file", a is not None and a < 25, "age_min=%s" % ("missing" if a is None else round(a, 1)))

note = os.path.join(root, "memory", now.strftime("%Y-%m-%d") + ".md")
check("daily-note", os.path.exists(note), note)

write = os.path.join(reports, "tool-write-test.txt")
okw = False
detail = write
try:
    if os.path.exists(write):
        text = read_text(write).strip()
        okw = "OK-WRITE" in text
        detail = repr(text[:40])
except Exception as e:
    detail = str(e)
check("write-proof", okw, detail)

brief = os.path.join(reports, "morning-brief-%s.md" % now.strftime("%Y-%m-%d"))
check("morning-brief", os.path.exists(brief), brief)

lines.append("")
lines.append("fails: %d" % fails)
body = "\n".join(lines) + "\n"
path = os.path.join(reports, "self-check.md")
open(path, "w", encoding="utf-8").write(body)
print(body)
