#!/usr/bin/env python3
"""CLI adapter for the pure typed GREEN work-order admission policy.

Candidate-only transport shim. It reads JSON files and prints one JSON decision.
It never executes an order, launches a process, performs network I/O, or mutates
production state.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from work_order_policy_v1_1 import evaluate


def load(path: str):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--order", required=True)
    ap.add_argument("--snapshot", required=True)
    ap.add_argument("--ledger", required=True)
    ap.add_argument("--catalog", required=True)
    ap.add_argument("--now")
    ns = ap.parse_args()
    now = datetime.fromisoformat(ns.now.replace("Z", "+00:00")) if ns.now else datetime.now(timezone.utc)
    decision = evaluate(load(ns.order), load(ns.snapshot), load(ns.ledger), load(ns.catalog), now)
    print(json.dumps(decision, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
