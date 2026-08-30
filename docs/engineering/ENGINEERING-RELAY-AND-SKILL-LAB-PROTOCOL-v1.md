# Kevin Engineering Relay + Skill Lab Protocol v1

Status: DESIGN CONTRACT
Purpose: remove Matt from routine copy/paste troubleshooting while preserving Kevin's authority boundaries.

## Existing proven channel reused

Kevin Support Bridge v1.1d publishes a sanitized rolling support snapshot to `reports/support-latest.json`. Maintenance Intake v1.1d polls `inbox/maintenance/manifest.json`, stages only hash-pinned GREEN maintenance payloads, and never self-approves application.

The Engineering Relay extends this pattern. It does not replace Support Bridge, Maintenance Intake, Supervisor, Benchmark, Forge, Operator, or the UI Bridge.

## Engineering Relay

Remote inbox: `inbox/engineering/request.json`
Remote response: `reports/engineering/latest.json`
Local state: `reports/engineering/relay-state.json`

Accepted request envelope:

- schema = 1
- kind = `kevin-engineering-request`
- id = unique stable request id
- authority = `GREEN`
- created_at / expires_at
- operation from a fixed allowlist
- params specific to the typed operation

Allowed v1 operations:

1. `snapshot` — publish a fresh sanitized engineering snapshot.
2. `benchmark` — run the existing pinned Benchmark job and return the exact fresh result.
3. `action_selftests` — run Operator, Initiative, and UI Bridge self-tests only.
4. `action_status` — inspect Action Era queue/proof/status metadata.
5. `stage_composite_skill` — fetch and validate a declarative composite skill made solely from proven GREEN primitives and stage it for Skill Lab.

Explicitly forbidden:

- arbitrary shell or command strings
- arbitrary PowerShell arguments
- arbitrary file paths
- credentials/config contents/environment dumps
- permission changes
- production Chat tools
- browser submit/send/buy
- financial transactions
- safety weakening
- automatic primitive-authority expansion

## Skill Lab principle

Primitive capability != composite skill.

A primitive is a narrow typed operation with its own authority surface, such as:

- `create_text`
- `create_spreadsheet`
- `ui_notepad_write`

A composite skill is a declarative sequence built only from primitives already present in the proven primitive registry.

A composite skill may be autonomously staged, executed, verified, scored, and registered because it does not create a new primitive authority. It only composes already-authorized GREEN operations.

## Skill lifecycle

PROPOSED -> SCHEMA_VALID -> STAGED -> RUNNING -> VERIFIED -> PROVEN

Failure at any step is recorded as REJECTED or FAILED with evidence. A failed skill never silently enters the registry.

## Promotion rule

- New primitive: full proof bar + explicit authority review.
- Composite skill using only proven GREEN primitives: may become PROVEN after deterministic successful execution and evidence.
- Any Yellow/Red step: composite skill is not eligible for autonomous execution.

## Evidence requirements

Every proven composite skill must retain:

- skill id and version
- exact manifest hash
- primitive dependencies and their proven identities
- work-order ids
- output hashes
- UI evidence hashes when applicable
- timestamps/durations
- failure history
- deterministic replay result or equivalent verification

## Idempotency and rate limits

- request ids are processed once
- expired requests are ignored
- duplicate semantic skills are suppressed
- bounded daily remote engineering request budget
- bounded skill step count and payload sizes
- no request may alter the relay's own allowlist

## Human involvement target

Matt should not be the transport layer for logs or ordinary repair evidence. The expected human checkpoints are limited to true owner-authority events such as administrative credentials, privileged installation, new primitive authority, or consequential Yellow/Red actions.
