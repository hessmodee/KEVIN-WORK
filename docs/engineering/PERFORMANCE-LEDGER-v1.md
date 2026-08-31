# Kevin Performance Ledger v1

Status: production-adjacent measurement schema and baseline register. This file measures safe task execution; it does not grant authority or weaken proof requirements.

## Measurement schema

Each measured task family should record:

- `task_family`
- `skill_or_runner_version`
- `proof_level`
- `started_at`
- `finished_at`
- `elapsed_seconds`
- `queue_wait_seconds`
- `execution_seconds`
- `tool_calls`
- `retries`
- `materially_distinct_failed_attempts`
- `first_pass_success`
- `independent_postcondition`
- `owner_intervention_count`
- `cpu_pressure`
- `ram_pressure`
- `gpu_pressure`
- `disk_pressure`
- `system_error_count_24h`
- `application_error_count_24h`
- `rollback_or_recovery_seconds`
- `regression_detected`
- `bottleneck`
- `reusable_lesson`
- `next_speed_experiment`

Resource-pressure fields must consume only sanitized/proven machine-state telemetry. Unknown or stale telemetry must be recorded as `UNKNOWN`, never guessed.

## Primary metrics

- median successful completion time
- p90 successful completion time
- first-pass success rate
- retry rate
- owner-intervention rate
- regression rate
- median recovery time after recoverable failures
- useful successful work completed per healthy hour

Optimization is valid only when independent postconditions and safety/governance remain at least as strong as the baseline.

## Initial baselines

These rows intentionally distinguish known evidence from fields not yet instrumented. Missing timing/resource values are `TBD` rather than fabricated.

| Task family | Version / identity | Proof level | Outcome baseline | Retries / intervention | Resource baseline | Bottleneck / lesson | Next experiment |
|---|---|---|---|---|---|---|---|
| Typed Maintenance fixed GREEN reconciliation | Maintenance v1.3.3 SHA `0AC6C0F20DC33507159789A8A3B7767154A918E4E665CEAA90201E1ADA94FDA3` | OMEN-PROVEN | Fresh Benchmark postcondition 30/30, critical=0 in latest handover | Exact elapsed/retry fields TBD; owner intervention 0 for currently self-reliant typed cycle | Sanitized OS telemetry available but not yet wired into per-task ledger | Current evidence proves correctness but not latency decomposition | Instrument queue/start/end/postcondition timestamps around one idempotent typed reconciliation |
| Work Order Intake typed poll / identity | v1.2.3 SHA `0C1B36D56488AA850E4F2C2EFDAC01D89D14D75CF854CA347B65D18234AF2BC6` | OMEN-PROVEN identity | Exact installed identity independently proven; expired/duplicate and budget fail-closed behavior observed | Timing/retry split TBD; latest proof required no owner relay | Per-task CPU/RAM/GPU TBD | Need explicit queue-vs-execution timing and autonomous proof collection metrics | Add sanitized timing receipt for one no-op/idempotent poll and one duplicate/expired rejection |
| Skill Lab composite lifecycle | v1.0.4 production baseline | OMEN-PROVEN baseline | 2 PROVEN composites; latest queues 0 READY / 0 RUNNING / 2 DONE, with one historical failed composite | Historical recovery required multiple engineering iterations; current exact per-run retry count TBD | Per-composite resource evidence TBD | Recovery bugs showed value of replay-safe queue state and durable step linkage | Run a controlled multi-step composite with checkpoint/resume and intentional failure; record stage timings and recovery time |

## Required next three baselines

1. **Sanitized OS telemetry adapter** — measure source age, validation time, Support/HQ publish latency, stale-rejection behavior, and zero private-field leakage.
2. **Gmail local adapter selftest** — before credentials: dependency startup time, keyring availability test, deterministic selftest time, secret-leak scan, first-pass success; after owner-local OAuth: send/read latency measured without publishing message bodies or secrets.
3. **General desktop artifact task** — filesystem/spreadsheet/Word task with exact start/end, app/file postcondition, retries, owner intervention, and machine pressure.

## Safe optimization loop

1. Establish a repeatable baseline with fresh evidence.
2. Identify the largest measured bottleneck, not the most visible one.
3. Change one material variable where practical.
4. Re-run deterministic and adversarial validation.
5. Require the same or stronger independent postcondition.
6. Compare median/p90, first-pass success, retry rate, recovery time and resource pressure.
7. Keep the change only if the improvement is material and regressions are absent.
8. Convert stable repeated sequences into typed composite skills.
9. Preserve failed experiments and rollback evidence as reusable engineering lessons.

## Guardrails

- Never reduce validation, provenance, rollback, privacy, or authority checks to improve speed.
- Do not infer CPU/RAM/GPU pressure from task duration; use sanitized OS Awareness evidence only.
- One 14B primary worker remains the default invariant.
- A `BUDGET_EXHAUSTED`, stale request, duplicate rejection, authority rejection, or cooldown can be a correct fast failure and should not be optimized away by evasion.
- Owner intervention is a metric to reduce through safe typed automation, not a reason to cross a credential, money, external-send, trust-anchor, or novel-authority boundary.
