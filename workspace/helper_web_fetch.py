import os, sys, urllib.request
from datetime import datetime
MAX = 80_000
UA = "KevinHESS-PC/1.0"
url = sys.argv[1] if len(sys.argv) > 1 else "https://api.weather.gov/alerts/active?point=42.0963,-111.8766"
if not url.startswith("http://") and not url.startswith("https://"):
    raise SystemExit("only http/https")
root = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
reports = os.path.join(root, "reports")
os.makedirs(reports, exist_ok=True)
req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "text/html,application/json,application/geo+json,text/plain"})
with urllib.request.urlopen(req, timeout=20) as r:
    raw = r.read(MAX + 1)
    ctype = r.headers.get("Content-Type", "")
clipped = len(raw) > MAX
text = raw[:MAX].decode("utf-8", errors="replace")
now = datetime.now().strftime("%Y-%m-%d %H:%M")
md = "# Fetch %s\n\nURL: %s\nType: %s\nClipped: %s\n\n```\n%s\n```\n" % (now, url, ctype, clipped, text[:8000])
path = os.path.join(reports, "fetch-latest.md")
open(path, "w", encoding="utf-8").write(md)
print(path)
print("bytes", min(len(raw), MAX), "clipped", clipped)
