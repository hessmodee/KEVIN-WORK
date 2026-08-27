import os
import json
import re
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


def read(name):
    p = os.path.join(reports, name)
    if not os.path.exists(p):
        return ""
    return open(p, encoding="utf-8", errors="replace").read()


def kv_lines(text):
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


self_check = read("self-check.md")
system = read("system-status.md")
weather = read("weather-83263.md")
context = read("context-latest.md")
brief_name = "morning-brief-%s.md" % now.strftime("%Y-%m-%d")
brief = read(brief_name)
bridge_raw = read("bridge-latest.json")
bridge = {}
try:
    bridge = json.loads(bridge_raw) if bridge_raw else {}
except Exception:
    bridge = {"raw": bridge_raw[:400]}

sys_map = kv_lines(system)
fails = 0
m = re.search(r"fails:\s*(\d+)", self_check)
if m:
    fails = int(m.group(1))

weather_line = ""
for line in weather.splitlines():
    if line.strip() and not line.startswith("#"):
        weather_line = (weather_line + " " + line.strip()).strip()
        if len(weather_line) > 80:
            break

board = {
    "at": now.strftime("%Y-%m-%d %H:%M"),
    "tz": "America/Boise",
    "host": sys_map.get("Host", "HESS-PC"),
    "place": "Preston, Idaho 83263",
    "chat": {
        "agent": "kevin-lab-qwen",
        "model": "qwen2.5:14b",
        "tools": 0,
        "lane": "Chat v2 frozen",
    },
    "tick": "KevinTick",
    "fails": fails,
    "system": sys_map,
    "weather": weather.strip()[:800],
    "weather_line": weather_line[:160],
    "self_check": self_check.strip()[:1200],
    "bridge": bridge,
    "context": context.strip()[:800],
}

json_path = os.path.join(reports, "board.json")
open(json_path, "w", encoding="utf-8").write(json.dumps(board, indent=2) + "\n")

parts = ["# Kevin board %s\n" % now.strftime("%Y-%m-%d %H:%M")]
for name in (
    "self-check.md",
    "system-status.md",
    "weather-83263.md",
    "context-latest.md",
    brief_name,
):
    parts.append("## %s" % name)
    p = os.path.join(reports, name)
    if os.path.exists(p):
        parts.append(open(p, encoding="utf-8", errors="replace").read()[:2500])
    else:
        parts.append("(missing)")
    parts.append("")
md_path = os.path.join(reports, "BOARD.md")
open(md_path, "w", encoding="utf-8").write("\n".join(parts))
print(json_path)
print(md_path)
