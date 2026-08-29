# Kevin Control Plane v1

Status: isolated candidate implementation. Nothing in this branch is production until a hash-pinned owner bootstrap installs the validated local components.

## Purpose

Remove the owner from routine troubleshooting and mission dispatch while preserving the existing authority boundary. Kevin remains self-improving, not self-authorizing.

## Local components

- `kevin-mission-dispatcher-v0.1.ps1`: work-conserving selector. It dispatches only when telemetry is fresh, governance and Benchmark are healthy, no engineering worker is active, the shared 14B mutex is free, and either the Supervisor is blocked/cooling or an explicit typed GREEN mission request is received.
- `kevin-mission-worker-v0.1.ps1`: isolated candidate factory. It uses only the local `kevin-lab-qwen` lane, writes only candidate artifacts under `workspace/mission-lab`, performs a second adversarial review, and never executes or promotes generated candidate code.
- `kevin-work-order-intake-v0.1.ps1`: typed GitHub work-order intake. It accepts only the locally hardcoded GREEN verb/target pairs, enforces expiry and idempotency, ignores replayed orders, and publishes a sanitized acknowledgement to `reports/control-plane-latest.json`.
- `mission-catalog-v1.json`: hash-pinned candidate mission catalog and work-conserving budgets.

## Remote work orders

The public GitHub branch is transport, not authority. A work order cannot provide a command string or executable path. The local intake accepts only:

- `dispatch_mission` to a mission ID already present in the installed local catalog.
- `run_reconcile` targeting `autonomy`.
- `run_benchmark` targeting `kevin-benchmark-v1`.
- `run_support_bridge` targeting `kevin-support-bridge-v1`.
- `refresh_autonomy_telemetry` targeting `autonomy-telemetry`.

Orders expire within 24 hours and require an idempotency key. Local state, not GitHub, decides whether an order is allowed.

## Work-conserving semantics

Work-conserving does not mean constant GPU use. When useful authorized work is available and the resource/safety gates pass, Kevin should dispatch it. If the primary Supervisor mission is healthy and progressing, the dispatcher yields. If one candidate mission hits repeated infrastructure failure, it cools rather than loop-spamming. Completed missions have a repeat cooldown so the factory rotates across useful work rather than manufacturing duplicate artifacts.

## Security invariants

- No arbitrary shell strings from GitHub.
- No permission or authority expansion.
- No Production Chat tool changes.
- No automatic production promotion of generated code.
- No credentials or secrets in work orders or public telemetry.
- One 14B candidate worker at a time.
- Candidate generation and adversarial review are isolated from production mutation.
- Owner Authorization, Desired State, and Work-Order Intake are not remotely self-updatable in v1.
