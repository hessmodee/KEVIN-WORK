import os
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
parts = ["# Kevin board %s\n" % now.strftime("%Y-%m-%d %H:%M")]
for name in ("self-check.md", "system-status.md", "weather-83263.md", "context-latest.md", "morning-brief-%s.md" % now.strftime("%Y-%m-%d")):
    p = os.path.join(reports, name)
    parts.append("## %s" % name)
    if os.path.exists(p):
        parts.append(open(p, encoding="utf-8", errors="replace").read()[:2500])
    else:
        parts.append("(missing)")
    parts.append("")
path = os.path.join(reports, "BOARD.md")
open(path, "w", encoding="utf-8").write("\n".join(parts))
print(path)
