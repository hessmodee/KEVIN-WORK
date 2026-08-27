"""Fail if public dashboard JSON contains private machine details."""
from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
REPORTS = os.path.join(ROOT, "reports")

PATTERNS = [
    (r"C:\\Users", "windows-path"),
    (r"hessm", "username"),
    (r":18789\b", "gateway-port"),
    (r"127\.0\.0\.1", "loopback"),
    (r"api[_-]?key", "api-key"),
    (r"xai-[A-Za-z0-9]{8,}", "xai-key"),
    (r"ghp_[A-Za-z0-9]{8,}", "github-pat"),
    (r"github_pat_", "github-pat"),
]


def scan(obj, path="$"):
    hits = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            hits.extend(scan(v, path + "." + str(k)))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            hits.extend(scan(v, path + "[%s]" % i))
    elif isinstance(obj, str):
        for pat, name in PATTERNS:
            if re.search(pat, obj, re.I):
                hits.append("%s %s" % (name, path))
    return hits


def main() -> int:
    files = ["dashboard-state.json", "system-status.json"]
    fails = 0
    for name in files:
        path = os.path.join(REPORTS, name)
        print("##", name)
        if not os.path.isfile(path):
            print("skip missing")
            continue
        try:
            data = json.loads(open(path, encoding="utf-8").read())
        except Exception as e:
            print("FAIL parse", e)
            fails += 1
            continue
        hits = scan(data)
        if hits:
            print("FAIL", "; ".join(hits[:8]))
            fails += 1
        else:
            print("PASS")
    print("fails:", fails)
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
