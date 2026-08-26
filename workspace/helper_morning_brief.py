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
wx_path = os.path.join(reports, "weather-83263.md")
wx = open(wx_path, encoding="utf-8").read() if os.path.exists(wx_path) else "weather pending\n"
day = now.strftime("%Y-%m-%d")
out = os.path.join(reports, "morning-brief-%s.md" % day)
body = "# Morning brief %s America/Boise\n\nPlace: Preston, Idaho 83263\n\n## Weather\n\n%s\n## Note\nKevinTick is the 15-minute loop. One new skill after this file exists.\n" % (now.strftime("%Y-%m-%d %H:%M"), wx)
open(out, "w", encoding="utf-8").write(body)
print(out)
