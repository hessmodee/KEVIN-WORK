#!/usr/bin/env python3
"""Separate Support config-warning visibility from scheduler health.

Support's legacy `cron.ok=false` can be caused by an OpenClaw `Config warnings:`
parser path with zero parsed jobs. That is not scheduler failure. Canonical
per-lane health lives on Engineering `action.cron`. This module never hard-codes
health; it only refuses to treat a warning-only parse as `scheduler_ok=false`.
"""
from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional

VERSION = "1.0.0"
EXPECTED_LANES = (
    "kevin-engineering-relay-v1",
    "kevin-maintenance-intake-v1",
    "kevin-skill-lab-v1",
    "kevin-support-bridge-v1",
    "kevin-supervisor-v1",
    "kevin-benchmark-v1",
)
WARNING_PREFIXES = ("config warnings:", "config warning:")


def _text(value: Any) -> str:
    return str(value or "").strip()


def is_config_warning_parse(error: Any, jobs: Any) -> bool:
    text = _text(error).lower()
    empty_jobs = not isinstance(jobs, list) or len(jobs) == 0
    return empty_jobs and any(text.startswith(prefix) or text == prefix.rstrip(":") for prefix in WARNING_PREFIXES)


def engineering_lanes_healthy(rows: Any) -> bool:
    if not isinstance(rows, list) or not rows:
        return False
    by = {str(row.get("declaration_key", "")): row for row in rows if isinstance(row, dict)}
    if any(key not in by for key in EXPECTED_LANES):
        return False
    for key in EXPECTED_LANES:
        row = by[key]
        if row.get("enabled") is not True:
            return False
        if str(row.get("last_status", "")).lower() != "ok":
            return False
        if int(row.get("consecutive_errors") or 0) != 0:
            return False
    return True


def interpret_cron(support_cron: Optional[Dict[str, Any]] = None, engineering_cron: Optional[Iterable[Any]] = None) -> Dict[str, Any]:
    support_cron = support_cron if isinstance(support_cron, dict) else {}
    jobs = support_cron.get("jobs") if isinstance(support_cron.get("jobs"), list) else []
    error = _text(support_cron.get("error"))
    warning_only = is_config_warning_parse(error, jobs)
    eng_rows = list(engineering_cron) if engineering_cron is not None else None
    eng_healthy = engineering_lanes_healthy(eng_rows) if eng_rows is not None else False

    if eng_healthy:
        scheduler_ok = True
        evidence_source = "engineering.action.cron"
        published_jobs = list(eng_rows or [])
    elif jobs:
        scheduler_ok = all(
            isinstance(job, dict)
            and job.get("enabled") is True
            and str(job.get("last_status", "")).lower() == "ok"
            and int(job.get("consecutive_errors") or 0) == 0
            for job in jobs
        )
        evidence_source = "support.cron.jobs"
        published_jobs = jobs
    else:
        scheduler_ok = None
        evidence_source = "unverified"
        published_jobs = []

    # Warning-only Support output must never become scheduler_ok=false.
    if warning_only and scheduler_ok is not True:
        scheduler_ok = None
        if evidence_source == "support.cron.jobs":
            evidence_source = "unverified"

    return {
        "schema": 1,
        "kind": "kevin-support-cron-truth",
        "version": VERSION,
        "scheduler_ok": scheduler_ok,
        "config_warnings": error if warning_only else "",
        "warning_only_parse": warning_only,
        "jobs": published_jobs,
        "evidence_source": evidence_source,
        "support_ok_field_is_not_scheduler_health": warning_only,
        "legacy_support_ok": support_cron.get("ok"),
    }


def main() -> int:
    import argparse
    import json
    from pathlib import Path

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--support", help="support-latest.json")
    parser.add_argument("--engineering", help="engineering/latest.json")
    args = parser.parse_args()
    support = json.loads(Path(args.support).read_text(encoding="utf-8")) if args.support else {}
    engineering = json.loads(Path(args.engineering).read_text(encoding="utf-8")) if args.engineering else {}
    out = interpret_cron(support.get("cron") if isinstance(support, dict) else {}, (engineering.get("action") or {}).get("cron") if isinstance(engineering, dict) else None)
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
