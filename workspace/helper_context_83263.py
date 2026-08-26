import json, os, urllib.request
from datetime import datetime
try:
    from zoneinfo import ZoneInfo
    tz = ZoneInfo("America/Boise")
except Exception:
    tz = None
now = datetime.now(tz) if tz else datetime.now()
UA = "KevinHESS-PC/1.0"
LAT, LON = 42.0963, -111.8766
root = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
reports = os.path.join(root, "reports")
os.makedirs(reports, exist_ok=True)

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode("utf-8"))

lines = ["# Context %s America/Boise" % now.strftime("%Y-%m-%d %H:%M"), "Place: Preston, Idaho 83263", ""]

lines.append("## Alerts")
try:
    data = get("https://api.weather.gov/alerts/active?point=%.4f,%.4f" % (LAT, LON))
    features = data.get("features") or []
    if not features:
        lines.append("None active.")
    else:
        for f in features[:5]:
            p = f.get("properties") or {}
            lines.append("- %s: %s" % (p.get("event") or "alert", (p.get("headline") or "")[:180]))
except Exception as e:
    lines.append("alerts skip: %s" % e)

lines.append("")
lines.append("## On this day")
try:
    md = now.strftime("%m/%d")
    data = get("https://en.wikipedia.org/api/rest_v1/feed/onthisday/selected/%s" % md)
    selected = (data.get("selected") or [])[:3]
    if not selected:
        lines.append("(none)")
    for item in selected:
        text = (item.get("text") or "").strip()
        year = item.get("year")
        if text:
            lines.append("- %s: %s" % (year if year is not None else "?", text[:220]))
except Exception as e:
    lines.append("onthisday skip: %s" % e)

path = os.path.join(reports, "context-latest.md")
body = "\n".join(lines) + "\n"
open(path, "w", encoding="utf-8").write(body)
print(path)
print(body)
