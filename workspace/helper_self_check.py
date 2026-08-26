import json, os, urllib.request
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

def check(name, ok, detail):
    global fails
    if not ok:
        fails += 1
    lines.append("- %s: %s — %s" % ("PASS" if ok else "FAIL", name, detail))

# Ollama
try:
    urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=3).read()
    check("ollama", True, "11434 answering")
except Exception as e:
    check("ollama", False, str(e))

# Gateway port
import socket
s = socket.socket()
s.settimeout(2)
try:
    s.connect(("127.0.0.1", 18789))
    s.close()
    check("gateway", True, "18789 open")
except Exception as e:
    check("gateway", False, str(e))

def age_min(path):
    if not os.path.exists(path):
        return None
    return (datetime.now() - datetime.fromtimestamp(os.path.getmtime(path))).total_seconds() / 60.0

wx = os.path.join(reports, "weather-83263.md")
a = age_min(wx)
check("weather-file", a is not None and a < 25, "age_min=%s" % ("missing" if a is None else round(a, 1)))

note = os.path.join(root, "memory", now.strftime("%Y-%m-%d") + ".md")
check("daily-note", os.path.exists(note), note)

write = os.path.join(reports, "tool-write-test.txt")
okw = False
if os.path.exists(write):
    okw = open(write, encoding="utf-8").read().strip() == "OK-WRITE"
check("write-proof", okw, write)

brief = os.path.join(reports, "morning-brief-%s.md" % now.strftime("%Y-%m-%d"))
check("morning-brief", os.path.exists(brief), brief)

lines.append("")
lines.append("fails: %d" % fails)
body = "\n".join(lines) + "\n"
path = os.path.join(reports, "self-check.md")
open(path, "w", encoding="utf-8").write(body)
print(body)
