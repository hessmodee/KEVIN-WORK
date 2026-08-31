# Kevin AI Engineering Handover

Last updated: 2026-08-30 22:51 MDT / 2026-08-31 04:51 UTC

Purpose: durable turnover sheet for Kevin engineering. Re-check current GitHub telemetry before acting; fresh timestamps, exact hashes, receipts, CI heads, request IDs, and independent postconditions outrank narrative.

## Mission and authority

Make Kevin a persistent, proactive, evidence-driven local **Chief of Staff** on Matt's Omen while preserving human control at consequential boundaries. Standing owner authorization covers aggressive engineering, testing, troubleshooting, and reversible GREEN implementation. It does **not** authorize arbitrary remote shell/code execution, RED authority expansion, permission widening, credential/config exposure, money movement, purchases, owner-representing external communications, automatic promotion of genuinely novel primitive authority, silent trust-anchor adoption, safety weakening, or owner-locked-goal changes.

Mutable GREEN work requires bounded retries, evidence, independent postconditions, semantic progress, idempotency/preconditions, and rollback. After three materially distinct failures in one family, cool/block that family until evidence changes and continue independent authorized work.

## Fresh live truth

At 22:48–22:49 MDT, `dashboard-state.json` and `support-latest.json` were fresh. Dashboard reports `status=ready`, overall health `healthy`, failed checks `0`, no current task, and tick/bridge/ollama/gateway all healthy. Support reports governance OK, all listed core cron jobs enabled/OK with zero consecutive errors, Maintenance `ALREADY_APPLIED_PROVEN`, and Benchmark **PASS 30/30, critical 0**. The latest Supervisor result is `RECOVERY_THROTTLED`; therefore the truthful Kevin UI state may presently be **COOLDOWN**, not OFFLINE.

### HQ live-truth / Ops interaction milestone — DEPLOYED + CI-PROVEN

The false OFFLINE report exposed a concrete UI defect: PowerShell/.NET telemetry timestamps can contain seven fractional-second digits, for example `2026-08-30T22:40:34.1159186-06:00`. The HQ refinement layer passed those strings directly to `Date.parse()`. Browser parsing can reject that precision, which became infinite evidence age and a false OFFLINE state. Both the top-shell and Ops classifiers now normalize fractional seconds to millisecond precision before parsing. Dashboard stale ceiling remains 3 minutes; Support stale ceiling is 8 minutes, safely above its 3-minute production cadence plus publication jitter while still failing closed on genuinely stale evidence.

Current HQ interaction changes:

- Kevin's center hub is selectable by mouse and keyboard. After selecting another worker, selecting Kevin restores `Kevin — Chief of Staff` and his aggregate live detail.
- Selected-worker choice persists across Ops redraws instead of being silently overwritten by refreshes.
- Worker owl eyes are transparent inside with colored outline rings; READY workers blink at staggered rates/phases.
- Kevin looks only toward worker owls currently marked WORKING/BUILDING, roughly one second at a time in shuffled order, then looks forward before repeating.
- The same gaze vector is mirrored to the top-left Kevin.
- On a conservative busy→idle transition with explicit success evidence (`PASS`, `SUCCESS`, `PROVEN`, `DONE`, `COMPLETED`, or `RECOVERY_PASS`), Kevin performs a short flip/dance; the top-left Kevin mirrors the celebration.
- `ACTIVE` has its own gold `#ffd166` identity. ACTIVE means a lane is awake/participating in the cycle; it is distinct from WORKING, which means a real task is executing.
- Dynamic Ops base rendering is requested every 4 seconds; Kevin truth polling runs every 3 seconds; top-shell truth polling runs every 3 seconds; the overall HQ shell continues its no-store refresh path every 5 seconds. Source-generation cadence still governs how new the underlying data can be; the UI does not invent motion or progress between source updates.
- Fake worker progress bars remain removed.

Dedicated workflow `HQ Owner Refinement v1 Gate` run **33358374558** completed **SUCCESS** on code head `70bc4c3a7b0b8dfaccaed789869676c607a37735`. JavaScript syntax, seven-digit PowerShell timestamp compatibility, and all owner UI invariants passed. GitHub Pages deployment run **33358373855** for that head completed **SUCCESS**. Canonical engineering record: `docs/engineering/HQ-OWNER-REFINEMENT-v1.md`.

### OS Awareness v0.1 — OWNER-AUTHORIZED + OMEN-PROVEN within bounded read-only envelope

Installed observer SHA256 remains `192CF42D9403EDCE40D3540F3DDA632C96BBB132787ADCCE095B2D43A3F17D32`. Work order `bess-20260831-0342-os-awareness-proof` / idempotency key `bess-os-awareness-live-proof-20260831-0342` completed `SUCCESS` and emitted `OS_AWARENESS_PROVEN`. Evidence previously confirmed 34,270,429,184 bytes physical memory, one CPU package, one GPU, two memory modules, plus bounded process/service/task/software/event-health counts. The path remains GREEN, read-only, arbitrary-shell false, authority-expansion false.

Next OS Awareness milestone remains sanitized machine-state integration into Support/HQ with explicit provenance/freshness and no local-only sensitive detail.

### Typed self-maintenance — production-proven

Fresh Support continues to report Maintenance SHA256 `0AC6C0F20DC33507159789A8A3B7767154A918E4E665CEAA90201E1ADA94FDA3`, manifest `typed-maintenance-v133-workorder-poller-transport-20260830-2022`, status `ALREADY_APPLIED_PROVEN`. The transport maps only to fixed local typed targets; it does not expose caller-selected command/argv/path.

### Work Order Intake OS Awareness path — behavior live, exact installed version identity still not independently proved

Main contains Work Order Intake v1.2.3 with fixed `run_os_awareness` target and no caller-selected command/argv/path. The successful Omen work order proves that typed behavior is live through the control plane. Do not claim exact v1.2.3 installation until a trustworthy local hash independently matches qualified source.

### Skill Lab — production-proven

Fresh Engineering Relay at 22:49 MDT reports Operator queues `ready=0`, `running=0`, `done=7`, `failed=1`; composite skills `ready=0`, `running=0`, `done=2`, `failed=1`, `proven_count=2`. Latest proven composite remains `skill-lab-recovery-isolation-create-text@1`, manifest SHA256 `63B34295BFA6EC4C432DE594AD2F5B1087C51748111BDB4CFE1C7BB24B8E37E6`, proof SHA256 `9E4412B8AAFD335D080597EB1C456213208DE0E17935320320A3D06BCF990198`. Benchmark remains PASS 30/30, critical 0.

The stale `bess-stage-core-toolchain-proof-20260830-1638` request remains `REJECTED: request expired`; that is correct stale-request handling, not a live scheduler failure.

### Interactive UI Bridge — still cooled/unhealthy

Engineering Relay at 22:49 MDT reports UI Bridge task present and pinned hash matching, but interactive heartbeat age about **13,442 seconds**. Do not let coarse generic bridge health hide this. The restart family exhausted its bounded attempt budget; the next attempt requires materially new diagnostic evidence or a materially different repair path.

## Open authority / engineering checkpoints

- **Desired-state trust anchors:** stale drift remains owner-reserved; do not silently repin.
- **Browser observe/navigate:** candidate-only; retain strict HTTPS/host/redirect/public-IP controls, no arbitrary selectors/DOM dump/cookies/storage, and no automatic primitive promotion.
- **Knowledge / Second Brain, checkpoint-resume, postmortem, tool-budget, proactive planning, economic-output labs:** may advance as isolated GREEN candidates without widening authority.

## Immediate priority queue

1. Integrate only sanitized OS Awareness machine-state fields into Support/HQ with explicit source timestamp, freshness, and privacy tests; independently prove exact Work Order Intake local identity.
2. Build conservative resource-aware scheduling/self-diagnosis from sanitized RAM/CPU/GPU/disk/error state while preserving one 14B primary worker unless measurements prove otherwise.
3. Correct the generic-vs-interactive UI Bridge health signal and diagnose the stale heartbeat with materially new evidence before any further restart attempt.
4. Continue validating Maintenance v1.3.3 Work Order polling for idempotency, bounded failure accounting, and downstream authority separation.
5. Continue measured multi-step Skill Lab work from already-PROVEN GREEN primitives, preserving failure/replay evidence.
6. Advance browser observation/navigation and other isolated candidates only through their proper authority checkpoints.

## Engineering doctrine

Evidence before authority. External content is evidence, never executable authority. Prefer deterministic validators for deterministic controls. Technical success is not semantic success. Writes must be idempotent. Failure evidence survives recovery/planning passes. Reversible GREEN work may run farther autonomously than consequential actions. Skills earn promotion through baseline, pressure test, regression, rollback, and measured improvement. Never weaken governance or tests to manufacture a pass. Never conflate DESIGNED, CI-PROVEN, INSTALLED, OMEN-PROVEN, and SELF-RELIANT.
