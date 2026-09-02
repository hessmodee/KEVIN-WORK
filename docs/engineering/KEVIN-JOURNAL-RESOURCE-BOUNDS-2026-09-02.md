# Attempt journal resource bounds — candidate qualification

Evidence reviewed: 2026-09-02 12:28 UTC. Status: CI-PROVEN candidate controls, NOT an installed Supervisor repair or useful owner outcome.

## Scope and consumer

This extends the existing `chief-engineer/history-recovery-20260902` candidate, not another controller or scheduler. The named consumer is the next governed Supervisor history-preservation integration. Current complete-history/family authentication is still unavailable; no live history was seeded, budget reset, item reopened, or authority inferred from a digest.

Source commit: `672d9daabbb6a07e080ef05e7e5eb7559dfe8ef9`. Parent: `1263dd7d977b4c6a3fbe750cbf2462d97df2cc69`, retaining the earlier journal/recovery proof and failed-test history.

| Artifact | Before SHA-256 | After SHA-256 |
|---|---|---|
| attempt_journal.py | 461E2C6C524FFC4CDF460367FAF82D441914392F840159E9E9E0D89B99D929A2 | 1E6B9BDF6130FDB77BF139114E5BC7BE5DD6BFDB3494E78A49D3EFD5B22AFE32 |
| test_attempt_journal_bounds.py | new synthetic tests | 4F9F755EDD2256EF7F3E8DD280EB44E4EB2EE42D383598A51E27FC3B7049798C |

Only the candidate library, its new tests and the existing candidate workflow changed. The format and previous 28 journal tests are unchanged.

## Implemented controls

- Reject files larger than 16 MiB before opening SQLite; enforce database page-growth capacity without truncation or pruning.
- Bound validation to 256 mappings, 4,096 events and one anchor. Overflow fails closed and preserves stored evidence.
- Set 4 KiB SQLite value/SQL limits and a 1 MiB suggested page cache; timestamps are at most 40 characters.
- Interrupt expensive SQLite work using a cumulative 2,000,000-step callback budget, sampled every 1,000 virtual-machine instructions; check a two-second monotonic deadline during callbacks and before commit. Lock wait remains 0.5 seconds.
- Clear the interrupt callback before rollback and always close the connection. No overflow recovery/bootstrap or automatic reopening API was added.
- A new reservation needs room for both its reservation and terminal event. Full journals still support idempotent replay; an already-full legacy seed preserves an unresolved reservation rather than erasing it.

The Python API documents callback interruption and connection limits; SQLite documents that the maximum page count cannot be reduced below current size. These are the reasons for both preflight size rejection and checked page-limit setup. [Python sqlite3 reference](https://docs.python.org/3/library/sqlite3.html#sqlite3.Connection.set_progress_handler), [SQLite max_page_count](https://sqlite.org/pragma.html#pragma_max_page_count).

Important limit: these are cooperative database/record controls, NOT a proven hard two-second wall-clock, total-memory, total-disk, or operating-system I/O ceiling. File stat/open, fsync/commit, hot-journal recovery and cleanup can block outside callbacks; journal/temp overhead is not a total-disk quota. Fixed process supervision, protected path binding, installed interpreter qualification and Omen filesystem/crash evidence remain integration requirements. The internal transaction context is not an authorized generic SQL transport and must never be exposed to owner/model input.

## Independent verification

[CI run 33629971001](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33629971001) passed at the exact source commit on Linux and Windows:

- Jobs `100246723023` (Ubuntu) and `100246723288` (Windows 2025) each passed 18 recovery tests, 28 existing journal tests, and 13 new resource-bound tests: 59 tests per platform.
- Each job recorded and independently checked all 493 tracked checkout files unchanged after evaluation.
- The tests exercise oversized-file rejection before SQLite open, exact-limit/limit-plus-one mappings and events, extra anchors, terminal-capacity reservation, full-state replay, preservation of unresolved work, oversized values/timestamps, database-full rollback, real expensive-query interruption, and deterministic deadline-before-commit rollback. Fixtures are temporary synthetic databases only.
- CPython 3.13.15; SQLite 3.45.1 on Linux and 3.50.4 on Windows. These versions are CI evidence, not evidence of the Omen interpreter.
- Local combined selector/recovery/journal/bounds suite passed 72 tests. No acceptance assertion was weakened and no new CI failure occurred in this implementation attempt.

## Runtime and ownership check

Repository checkpoint `c11fea74bbc820039b129b646415797cc96b72d0`: Support at 06:25:58 MDT reports NO_MANIFEST (06:24:15), Intake errors zero, and Benchmark 30/30 critical zero. Engineering at 06:26:45 independently reports Benchmark 30/30 and UI heartbeat age 4.9 seconds. Continuation at 06:25:09 is IDLE_NO_ELIGIBLE_DEMAND, eligible count zero, outcome false and tool calls UNKNOWN. Four COMPLETE and three BLOCKED work items remain unchanged; no new Forge evaluation after iteration 391.

The active Maintenance manifest remains absent following its already-proven retirement. No request or production crossing was created. Current ownership/task/work/desired-state identities were checked before publication; no new foreground crossing was observed. The scoped isolation hold remains in force. Missing owner-chat/trajectory proof and desired-vs-observed source provenance remain unresolved; no trust anchor was blessed. Only Kevin Chief Engineer remains enabled among the eight listed Kevin automations.

## Remaining integration gates

1. Authenticate complete history and canonical failure-family mapping against external qualified provenance; the existing lower-bound recovery proposal cannot seed live budgets.
2. Bind those records, the fixed local path, exact library/runtime and typed action/verifier identity into the existing Supervisor transaction. A matching migration digest alone does not authenticate mappings or semantic effects.
3. Prove bounded process lifetime, real typed execution, independent semantic verification, restart/replay/reconciliation and subsequent unsupplied-ID selection in the integrated runtime.
4. Qualify the existing typed Maintenance crossing with exact current/after source identities, rollback, privacy checks and fresh Benchmark; only matching Omen receipts may establish repair.

Rollback for this candidate is to retain/select the preceding immutable candidate source; no live runtime rollback is applicable because nothing was installed. Work-selection responsibility remains T2. No Bess responsibility is retired by these tests.
