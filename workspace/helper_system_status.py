"""Collect machine health. Markdown stays local. JSON is sanitized for Kevin."""
from __future__ import annotations

import argparse
import ctypes
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
from datetime import datetime

try:
    from zoneinfo import ZoneInfo

    TZ = ZoneInfo("America/Boise")
except Exception:
    TZ = None

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
REPORTS = os.path.join(ROOT, "reports")
os.makedirs(REPORTS, exist_ok=True)


def iso_now() -> str:
    d = datetime.now(TZ) if TZ else datetime.now()
    return d.strftime("%Y-%m-%dT%H:%M:%S-06:00")


def ping(url: str) -> str:
    try:
        urllib.request.urlopen(url, timeout=3).read(64)
        return "running"
    except Exception:
        return "down"


def port_open(host: str, port: int) -> str:
    s = socket.socket()
    s.settimeout(2)
    try:
        s.connect((host, port))
        s.close()
        return "open"
    except Exception:
        return "closed"


class MEMORYSTATUSEX(ctypes.Structure):
    _fields_ = [
        ("dwLength", ctypes.c_ulong),
        ("dwMemoryLoad", ctypes.c_ulong),
        ("ullTotalPhys", ctypes.c_ulonglong),
        ("ullAvailPhys", ctypes.c_ulonglong),
        ("ullTotalPageFile", ctypes.c_ulonglong),
        ("ullAvailPageFile", ctypes.c_ulonglong),
        ("ullTotalVirtual", ctypes.c_ulonglong),
        ("ullAvailVirtual", ctypes.c_ulonglong),
        ("ullAvailExtendedVirtual", ctypes.c_ulonglong),
    ]


def ram_info():
    try:
        stat = MEMORYSTATUSEX()
        stat.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
        ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))
        total = stat.ullTotalPhys / (1024**3)
        avail = stat.ullAvailPhys / (1024**3)
        used = total - avail
        return round(used, 1), round(total, 1), int(stat.dwMemoryLoad)
    except Exception:
        return 0.0, 0.0, 0


class FILETIME(ctypes.Structure):
    _fields_ = [("dwLowDateTime", ctypes.c_ulong), ("dwHighDateTime", ctypes.c_ulong)]


def _idle_kernel_user():
    idle = FILETIME()
    kernel = FILETIME()
    user = FILETIME()
    ctypes.windll.kernel32.GetSystemTimes(
        ctypes.byref(idle), ctypes.byref(kernel), ctypes.byref(user)
    )

    def q(ft):
        return (ft.dwHighDateTime << 32) + ft.dwLowDateTime

    return q(idle), q(kernel), q(user)


def cpu_percent() -> int:
    try:
        i1, k1, u1 = _idle_kernel_user()
        time.sleep(0.12)
        i2, k2, u2 = _idle_kernel_user()
        idle = i2 - i1
        total = (k2 - k1) + (u2 - u1)
        if total <= 0:
            return 0
        busy = max(0.0, 1.0 - (idle / float(total)))
        return int(round(busy * 100))
    except Exception:
        return 0


def gpu_info():
    try:
        out = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=name,memory.used,memory.total,utilization.gpu",
                "--format=csv,noheader,nounits",
            ],
            timeout=8,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        name, used, total, util = [x.strip() for x in out.split(",", 3)]
        return name, int(float(used)), int(float(total)), int(float(util))
    except Exception:
        return "unavailable", 0, 0, 0


def disk_free_gb() -> float:
    try:
        u = shutil.disk_usage("C:\\")
        return round(u.free / (1024**3), 1)
    except Exception:
        return 0.0


def collect() -> dict:
    used, total, load = ram_info()
    gpu_name, vram_used, vram_total, gpu_pct = gpu_info()
    return {
        "ok": True,
        "collected_at": iso_now(),
        "ram_used_gb": used,
        "ram_total_gb": total,
        "ram_load_percent": load,
        "cpu_percent": cpu_percent(),
        "gpu_name": gpu_name,
        "gpu_percent": gpu_pct,
        "vram_used_mb": vram_used,
        "vram_total_mb": vram_total,
        "disk_free_gb": disk_free_gb(),
        "ollama_status": ping("http://127.0.0.1:11434/api/tags"),
        "gateway_status": port_open("127.0.0.1", 18789),
        "error": "",
    }


def write_markdown(data: dict) -> str:
    host = os.environ.get("COMPUTERNAME", "?")
    user = os.environ.get("USERNAME", "?")
    lines = [
        "# System status %s" % data["collected_at"][:16].replace("T", " "),
        "Host: %s" % host,
        "User: %s" % user,
        "RAM used: %s GB" % data["ram_used_gb"],
        "RAM total: %s GB" % data["ram_total_gb"],
        "RAM load: %s%%" % data["ram_load_percent"],
        "CPU load: %s%%" % data["cpu_percent"],
        "GPU: %s" % data["gpu_name"],
        "VRAM used: %s MB" % data["vram_used_mb"],
        "VRAM total: %s MB" % data["vram_total_mb"],
        "GPU utilization: %s%%" % data["gpu_percent"],
        "C: free %s GB" % data["disk_free_gb"],
        "Ollama: %s" % data["ollama_status"],
        "Gateway: %s" % data["gateway_status"],
    ]
    body = "\n".join(lines) + "\n"
    open(os.path.join(REPORTS, "system-status.md"), "w", encoding="utf-8").write(body)
    return body


def main(argv) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv[1:])
    try:
        data = collect()
    except Exception as e:
        data = {
            "ok": False,
            "collected_at": iso_now(),
            "ram_used_gb": 0,
            "ram_total_gb": 0,
            "ram_load_percent": 0,
            "cpu_percent": 0,
            "gpu_name": "unavailable",
            "gpu_percent": 0,
            "vram_used_mb": 0,
            "vram_total_mb": 0,
            "disk_free_gb": 0,
            "ollama_status": "down",
            "gateway_status": "closed",
            "error": "collect_failed",
        }
        _ = e
    open(os.path.join(REPORTS, "system-status.json"), "w", encoding="utf-8").write(
        json.dumps(data, indent=2) + "\n"
    )
    md = write_markdown(data)
    if args.json:
        print(json.dumps(data, separators=(",", ":")))
    else:
        print(md)
    return 0 if data.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
