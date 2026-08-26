import json, os, urllib.request
from datetime import datetime

UA = "KevinHESS-PC/1.0"
LAT, LON = 42.0963, -111.8766
ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
OUT_DIR = os.path.join(ROOT, "reports")
os.makedirs(OUT_DIR, exist_ok=True)

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/geo+json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode("utf-8"))

point = get("https://api.weather.gov/points/%.4f,%.4f" % (LAT, LON))
forecast_url = point["properties"]["forecast"]
rel = point["properties"].get("relativeLocation", {}).get("properties", {})
data = get(forecast_url)
period = data["properties"]["periods"][0]
now = datetime.now().strftime("%Y-%m-%d %H:%M")
place = "%s, %s" % (rel.get("city") or "Preston", rel.get("state") or "ID")
md = "# Weather 83263 — %s\n\n%s\n%s, %s\nWind %s\n%s\n" % (
    now, place, period.get("name"), period.get("temperature"),
    period.get("windSpeed"), period.get("shortForecast"),
)
path = os.path.join(OUT_DIR, "weather-83263.md")
with open(path, "w", encoding="utf-8") as f:
    f.write(md)
print(path)
print(md)
