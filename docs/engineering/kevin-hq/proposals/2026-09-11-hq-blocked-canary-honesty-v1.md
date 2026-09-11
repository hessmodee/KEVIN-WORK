# Proposal — HQ BLOCKED_INVOCATION + Tools CANARY STALE honesty (v1)
**Updated:** 2026-09-11 13:46 MT  
**Authority:** Matt lock via CoS 2026-09-11 — Priority = Kevin autonomy / HESS-PC self-control / west-motor owner outcome  
**Box draft only.** CoS owns HESS runtime paste. Minecraft **PAUSE**.

## Goal
Ship HQ honesty for invoke fail-closed and tools canary freshness — no celebration fluff, no false READY/ON.

## Packets
1. `drafts/p0-blocked-invocation-honesty/`  
   - `BLOCKED_INVOCATION_RUNTIME` / `failure_sha256`→`INVOCATION_WORKER_FAILED` → Command/Attention paint **BLOCKED**  
   - Reason chip: worker exit / fail-closed / sticky RequestId family  
   - Fixtures: BLOCKED_INVOCATION · STAGE_OK_WAITING (still not PASS) · HEALTHY_READY  
   - Note: **Isolated STAGE_OK ≠ Action Era ≠ PASS**

2. `drafts/p0-tools-canary-stale/`  
   - Tools chip/System/pulse: **CANARY STALE** when canary/evidence aged or missing  
   - Never imply tools ON when canary stale  
   - Complements P1-4 (#127) — canary-specific; do **not** redo #127  
   - Fixtures: TOOLS_ON_FRESH · TOOLS_CANARY_STALE · TOOLS_OFF

## Hard bans
No HESS-PC operate · no Minecraft · no #122–#133 redos · no Supervisor/ControlPlane pin changes.

## Ship label
Both packets **READY_FOR_HQ_SHIP** when pure node tests PASS + DESIGN complete (this beat).
