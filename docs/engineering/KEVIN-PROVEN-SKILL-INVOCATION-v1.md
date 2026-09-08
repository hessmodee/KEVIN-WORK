# Kevin Proven Skill Invocation v1

**Status:** source candidate; runtime promotion requires independent HESS-PC proof.  
**Authority delta:** NONE.  
**Purpose:** turn an already-PROVEN composite skill into a reusable bounded production capability for fresh owner inputs without rewriting or erasing Skill Lab qualification history.

## Problem

Skill Lab correctly preserves immutable qualification history. If `skill@version` is already PROVEN, replay protection verifies the preserved proof and consumes the redundant qualification request rather than rerunning it. That is correct for qualification, but it does not give Kevin a general production path for using the same skill again with fresh owner data.

The missing layer is therefore **invocation**, not re-qualification.

## Contract

`kevin-proven-skill-invocation-v1.py` accepts a fresh `kevin-proven-skill-invocation` request and will stage work only when all of these conditions are true:

1. the registry is schema-valid;
2. the requested `skill_key` exists exactly once;
3. its authority is `GREEN` and status is `PROVEN`;
4. the preserved Skill Lab proof exists;
5. the preserved manifest hash equals the registry `manifest_sha256`;
6. the preserved proof identity equals the registry `proof_sha256`;
7. the fresh request uses the exact primitive sequence proven by that skill;
8. every requested primitive is also on Invocation v1's stricter allowlist;
9. every payload passes existing bounded file/workbook validation;
10. the invocation ID is new, or an idempotent retry of the exact same request.

Only then does the lane emit fresh `kevin-green-work-order` records into the already-reviewed queue.

## Invocation v1 allowlist

The first release deliberately supports only:

- `create_spreadsheet`
- `create_text`

`ui_notepad_write` may already be Skill-Lab-qualified, but Invocation v1 does not inherit it automatically. A qualification allowlist and a production-invocation allowlist are intentionally separate.

Invocation v1 cannot:

- execute shell or arbitrary code;
- install software;
- browse or control a computer;
- send messages;
- purchase anything;
- change permissions;
- add a primitive to either allowlist;
- alter the composite skill registry;
- promote a skill;
- overwrite a Skill Lab proof.

## Fresh-run identity

Each invocation has an owner/request-selected `invocation_id` and stages unique work-order IDs:

`invoke-<invocation_id>-s01`

with semantic keys:

`invoke:<skill_key>:<invocation_id>:step:1`

Reusing an invocation ID with the exact same request is idempotent. Reusing it with different content fails closed.

## Evidence and receipt

The invocation run stores:

- skill key;
- immutable proven `manifest_sha256`;
- immutable proven `proof_sha256`;
- original preserved proof file name;
- exact proven primitive sequence;
- request SHA-256;
- per-order payload and order SHA-256;
- correlated completion-record SHA-256;
- output file name, byte count and SHA-256;
- final invocation receipt SHA-256.

A successful model turn, queue write, or source commit is not an owner outcome. The invocation becomes `PROVEN` only after every step has a correlated DONE record with output evidence.

## Fail-closed cases covered by CI

The proof suite must demonstrate at minimum:

- fresh successful invocation + receipt;
- idempotent exact retry;
- changed request under the same invocation ID rejected;
- unknown/unproven skill rejected;
- preserved proof identity mismatch rejected;
- primitive-order mutation rejected;
- path escape rejected;
- unreviewed primitive rejected;
- tampered DONE record rejected.

The workflow runs on both Linux and Windows.

## First HESS-PC acceptance test

After source CI passes and the lane is crossed to HESS-PC through a typed, rollback-safe path, invoke:

`west-motor-parts-chase-board-pack@1`

with fictional data for eight dealership vehicles. The fresh workbook must include at least:

- priority;
- stock number;
- part / need;
- vendor / source;
- ordered date;
- ETA;
- blocker;
- owner;
- next action;
- completion state.

The companion note must explain operating use. No customer PII, credentials, purchases, public posts, or live financial effects may be used in this acceptance test.

**PASS requires:** real workbook + real note + correlated DONE records + output hashes + final invocation receipt. A chat statement does not count.

## Next integration after v1 proof

Once Invocation v1 is independently HESS-PC-proven:

`WorkInstance -> Capability Router -> PROVEN skill match -> Proven Skill Invocation -> existing GREEN executor -> receipt -> Supervisor resume`

If no proven skill can satisfy the required capability:

`WorkInstance -> missing capability -> research/build -> Skill Lab -> independent proof -> registry -> invoke -> resume original objective`

This is the core bridge from Kevin's current skill-learning foundation to reusable autonomous work.
