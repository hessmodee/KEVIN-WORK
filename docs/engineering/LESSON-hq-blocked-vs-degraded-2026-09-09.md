# LESSON — HQ must not paint invocation fail-closed as DEGRADED (2026-09-09)

**Authority:** GREEN-C truth hygiene. Pages source only. Not PASS.

## Owner complaint

HQ showed Kevin as not working / DEGRADED while Benchmark was 30/30, six scheduler lanes were `ok`, and Supervisor was selecting a live WorkInstance.

## Root cause

Two HQ surfaces disagreed.

- `docs/hq-owner-console-v10.js` `executionTruth()` already maps `BLOCKED_INVOCATION_RUNTIME` → mode `blocked` with headline "Invocation fail-closed on the 8-vehicle job".
- `docs/ops/ops-v11.js` `kevinStates()` mapped `CONTROLLER_ERROR` **and** `BLOCKED_INVOCATION_RUNTIME` → `['degraded']`.

DEGRADED means the platform floor is sick (bridge/tick/ollama/gateway, overall health, or a Supervisor crash). `BLOCKED_INVOCATION_RUNTIME` means the scheduler recovered and the invocation worker fail-closed. Painting that as DEGRADED trains the owner to treat a governed diagnostic as a broken machine.

Tools UNVERIFIED is a separate badge: main canary freshness is 1800s and the last published canary is 2026-09-08. Stale canary ≠ missing Calculator launch.

## Fix

- `BLOCKED_INVOCATION_RUNTIME` → `blocked` / BLOCKED.
- `CONTROLLER_ERROR` stays `degraded` (scheduler actually crashed).
- Avatar mode `blocked` is distinct from bandage/bruise `degraded` and X-eyes `disconnected`.

## Kevin self-rule

When HQ and continuation disagree, continuation + Support hashes + Engineering lanes win. Do not "fix degraded" by widening tools or recopied Supervisor.
