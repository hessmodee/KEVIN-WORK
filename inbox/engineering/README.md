# Kevin Engineering Relay Intake Contract

This directory is an **input contract**, not a queue of arbitrary files.

## Canonical request slot

The live HESS-PC Engineering Relay reads exactly:

`inbox/engineering/request.json`

Writers MUST replace that one file with a new, unique, unexpired typed request. Do not create loose per-request JSON files in this directory and assume the Relay will discover them.

Historical requests belong under `inbox/engineering/archive/` only after they are terminal and no longer needed by the live crossing.

## Required request envelope

```json
{
  "schema": 1,
  "kind": "kevin-engineering-request",
  "id": "unique-id",
  "authority": "GREEN",
  "operation": "allowlisted-operation",
  "created_at": "ISO-8601 timestamp",
  "expires_at": "ISO-8601 timestamp",
  "params": {}
}
```

The Relay itself enforces schema, GREEN authority, expiry, replay protection, a daily request budget, operation allowlisting, governed Skill Lab paths, and pinned SHA-256 for staged composite skills.

## Truth rule

A repository request is not proof of execution. Completion requires a matching `request.id` and terminal result in `reports/engineering/latest.json`, followed by the applicable Skill Lab/operator proof if the request staged executable work.

`DUPLICATE_IGNORED` means the request ID was already processed; it is terminal replay protection, not an active task.

## Authority boundary

This crossing is intentionally typed and narrow. It does not grant arbitrary remote shell, arbitrary code execution, permission widening, credential access, external sends, purchases, financial transactions, or automatic promotion of new primitive authority.
