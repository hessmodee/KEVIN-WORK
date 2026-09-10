# LESSON — HQ must not paint invocation fail-closed as DEGRADED (2026-09-09)

**Authority:** GREEN-C truth hygiene. Pages source only. Not PASS.

## Owner complaint

HQ showed Kevin as not working / DEGRADED while Benchmark was 30/30, six scheduler lanes were `ok`, and Supervisor was selecting a live WorkInstance.

## Root cause

`docs/ops/ops-v11.js` `kevinStates()` mapped `CONTROLLER_ERROR` **and** `BLOCKED_INVOCATION_RUNTIME` → `['degraded']`. Owner console v10 already mapped the invocation fail-closed to mode `blocked`.

DEGRADED means the platform floor is sick. `BLOCKED_INVOCATION_RUNTIME` means the scheduler recovered and the invocation worker fail-closed. Painting that as DEGRADED trains the owner to treat a governed diagnostic as a broken machine.

## Fix

- `BLOCKED_INVOCATION_RUNTIME` → `blocked` / BLOCKED.
- `CONTROLLER_ERROR` stays `degraded` (scheduler actually crashed).
- Avatar stays healthy on BLOCKED (platform floor is fine). The badge tells the truth.

## Kevin self-rule

When HQ and continuation disagree, continuation + Support hashes + Engineering lanes win. Do not "fix degraded" by widening tools or recopied Supervisor.
