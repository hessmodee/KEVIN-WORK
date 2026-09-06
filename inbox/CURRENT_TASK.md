# CURRENT_TASK

**Updated:** 2026-09-06 14:58 MT
**Status:** recovery SAFE STOP preserved production; exact config drift diagnosis required before R04 repair

Owner directed Bess to resume Kevin repair after Grok credits exhausted. Canonical handover remains `AI-HANDOVER.md`.

## Proven this session
- Owner returned the private `Kevin-Evidence-20260906-141701-b9b2d9` archive. Native Ollama isolation PASS for both `llama3.1:8b` and `qwen2.5:14b`.
- Current production config SHA is `29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA`; current sanitized metadata still proves exact-five Desktop tools, 15 protected global denies, repaired local Qwen 16k model contract, and 2048/2048/4000 compaction contract.
- PR89 proves exact-five was intentional and reached fresh Benchmark 30/30 on 2026-09-04 with config SHA `DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4`. Never regress to exact-four.
- Benchmark remains exactly 29/30 critical1, R04 only. UI Bridge task remains Disabled/stale. Supervisor remains `NO_ELIGIBLE_MISSION`; 27 composite skills are proven.
- PR135 merged recovery bootstrap `tools/Repair-Kevin-Recovery-20260906-v2.ps1` as `0024db4cdfa142924c1fff25e70895f8b2760a7b`, Windows PowerShell 5.1 tested.
- Owner ran the exact recovery `-CheckOnly`. It correctly SAFE STOPPED: `current config differs semantically from proven exact-five config beyond touch metadata`. The Apply guard did not run because CheckOnly exited nonzero. No baseline, config, UI task, or other production state was changed by that attempt.
- Therefore `29383...` contains at least one semantic JSON difference from `DBF596...` beyond only `meta.lastTouchedAt` / `meta.lastTouchedVersion`. Do not rebaseline R04 and do not restore DBF596 blindly until the exact delta is classified.
- PR136 merged read-only redacted diagnostic `tools/Diagnose-Kevin-Config-Drift-20260906.ps1` as `952b9b31b1b595c76741ad1adda33ec6aa477ab8`. Windows PowerShell 5.1 parser, secret-redaction self-test, and read-only authority-boundary checks passed. It performs no writes, restarts, network calls, config changes, or task changes.

## Exact next step
Owner runs the merged `tools/Diagnose-Kevin-Config-Drift-20260906.ps1` once on HESS-PC and returns its console output from `KEVIN_CONFIG_DRIFT_DIAG_READY` through `VERDICT|...`.

The diagnostic pins current `29383...` and trusted `DBF596...`, finds the trusted bytes only in bounded local OpenClaw/Maintenance backup locations, recursively compares semantic JSON paths, and reports changed paths with type + short hashes. Only tightly bounded known non-secret operational values may be shown; sensitive/unknown values remain hashed/redacted. This is diagnosis only.

## Decision after the diff
- If drift is truly benign generated metadata: narrowly qualify those exact paths and rerun recovery CheckOnly; never broaden ignores generically.
- If drift is an intentional later feature/config change: establish its local/repository provenance and prove its semantics, then preserve it and qualify the current config before R04 rebaseline.
- If drift is unproven, unsafe, or accidental: restore only the affected semantics from a trusted proven state through a rollback-backed repair; do not blindly bless current bytes.
- Only after config provenance is settled: repair R04 to fresh 30/30, repair/prove UI Bridge, fresh exact-five owner-intent tool/negative canaries, correct stale HQ four-tool truth, then restore eligible GREEN work selection and owner-value execution.

## Preserved constraints
Local/free Ollama default. Exact-five is intentional. Keep failure history. No blind R04 blessing, no obsolete September 3 repair script, no arbitrary shell/tool widening, no silent public sends/purchases/trades, and no false claim that GitHub source changed production before HESS-PC proves it. Fresh correlated runtime evidence outranks prose.
