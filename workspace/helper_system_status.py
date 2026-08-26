import os, shutil, socket, subprocess, urllib.request
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
lines = ["# System status %s" % now.strftime("%Y-%m-%d %H:%M")]

def ping(url):
    try:
        urllib.request.urlopen(url, timeout=3).read(64)
        return "running"
    except Exception:
        return "down"

def port_open(host, port):
    s = socket.socket()
    s.settimeout(2)
    try:
        s.connect((host, port))
        s.close()
        return "open"
    except Exception:
        return "closed"

lines.append("Host: %s" % os.environ.get("COMPUTERNAME", "?"))
lines.append("User: %s" % os.environ.get("USERNAME", "?"))
lines.append("Ollama: %s" % ping("http://127.0.0.1:11434/api/tags"))
lines.append("Gateway 18789: %s" % port_open("127.0.0.1", 18789))
try:
    usage = shutil.disk_usage("C:\\")
    free_gb = usage.free / (1024 ** 3)
    total_gb = usage.total / (1024 ** 3)
    lines.append("C: free %.1f / %.1f GB" % (free_gb, total_gb))
except Exception as e:
    lines.append("C: skip %s" % e)
try:
    out = subprocess.check_output(
        ["nvidia-smi", "--query-gpu=name,memory.used,memory.total,utilization.gpu", "--format=csv,noheader,nounits"],
        timeout=8, stderr=subprocess.DEVNULL, text=True)
    lines.append("GPU: %s" % out.strip())
except Exception:
    lines.append("GPU: nvidia-smi unavailable")
path = os.path.join(reports, "system-status.md")
body = "\n".join(lines) + "\n"
open(path, "w", encoding="utf-8").write(body)
print(body)
