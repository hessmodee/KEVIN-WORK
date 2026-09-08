# LESSON — Support `cron.ok=false` from `Config warnings:`

**Date:** 2026-09-08  
**Failure family:** representation / parser, not scheduler outage  
**Authority:** GREEN diagnosis + source repair. Runtime Support publisher remains unproven until a fresh snapshot uses the split fields.

## What failed

Fresh Engineering evidence showed six canonical scheduler lanes:

- enabled
- last_status = ok
- consecutive_errors = 0

Support still published `cron.ok=false` with `error: "Config warnings:"` and an empty `jobs` array.

HQ and humans could read that as "Kevin's schedulers are down" while the actual lanes were healthy.

## Competing hypotheses

1. The six Engineering lanes are actually failing and Support is the truthful source.
2. Support is parsing an OpenClaw `Config warnings:` banner as a cron list failure, with zero jobs parsed.
3. HQ is hard-coding healthy and hiding a real problem.

Discriminating test: compare Engineering `action.cron` (typed per-lane last_status/errors) against Support `cron.jobs`. When jobs are empty and the error is exactly a config-warning banner, hypothesis 2 wins. Hypothesis 3 is forbidden: never hard-code healthy.

## Repair

Keep both facts:

- `scheduler_ok` from Engineering per-lane inventory when that inventory is complete and healthy.
- `config_warnings` from the Support parser banner.

Never collapse warning visibility into scheduler failure. Never delete the warning.

Source: `control-plane/autonomy/kevin-support-cron-truth-v1.py` plus HQ evidence adapter.

## Prevention

Any publisher that shells out to OpenClaw cron/config listing must treat warning banners and job rows as different fields. Tests cover warning-only, warning-plus-healthy-engineering, and a real failed job.

## Resume

Original objective was not "make HQ look green." Original objective is honest platform truth so Supervisor can be judged against real work supply. After this representation repair, resume invocation-runtime qualification.
