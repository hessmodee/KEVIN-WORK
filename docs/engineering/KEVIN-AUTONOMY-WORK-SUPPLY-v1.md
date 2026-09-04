# Kevin Autonomy Work Supply v1

Date: 2026-09-03
Status: candidate implementation on fresh-main branch
Authority effect: NONE

## Problem proven from live state

The production Supervisor is alive and scheduled, but it is a consumer of `inbox/autonomy/work-items.json`. When that static queue contains only terminal, blocked, cooled, or exhausted items, the selector truthfully returns no eligible mission. That avoids fake activity, but it also means Kevin has no governed mechanism for converting standing owner objectives, due capability-learning work, or stale guardian evidence into fresh bounded work.

This is why `NO_ELIGIBLE_MISSION` can coexist with a real unresolved backlog.

## Required truth model

HQ and the controller must distinguish four states:

1. `WORKING`: active mission lease plus an evidence-producing action is actually running.
2. `ELIGIBLE_WORK`: at least one owner-approved item is runnable now through effective capabilities.
3. `BLOCKED_WORK_PRESENT`: real owner-approved backlog exists, but a prerequisite/tool/proof is missing.
4. `TRUE_IDLE`: no eligible work, no blocked owner backlog, and no due guardian or capability-learning work.

`BLOCKED_WORK_PRESENT` is intentionally not represented as `WORKING`. The point is to eliminate both false busyness and false idleness.

## Work queues

Kevin should pull from three governed queues in priority order:

- Owner outcomes: direct work that produces something useful for Matt.
- Capability learning: execution/replay of approved skills, tool qualification, and responsibility transfer.
- Guardians: due platform/readiness/evidence refresh work.

When one queue is empty or blocked, Kevin may continue with another eligible GREEN queue. He must not manufacture work to keep an animation moving.

## Safety boundary

The supply planner has no execution authority. It may only make a catalog item eligible when every required capability is explicitly present in an effective-capability inventory. Missing evidence blocks the item.

The following effects can never be auto-authorized by Work Supply: arbitrary shell, credentials, permission widening, external sends, purchases, financial transactions, production chat sends, automatic promotion, or safety weakening.

Existing work IDs are never reset by the planner. This prevents attempt-budget laundering and fake novelty.

## Candidate implementation

- `control-plane/autonomy/kevin-work-supply-v1.py`
- `control-plane/autonomy/standing-work-supply-v1.json`
- `tools/test-autonomy-work-supply-v1.py`
- `.github/workflows/autonomy-work-supply-v1-proof.yml`

The initial standing catalog deliberately exposes the current blockers instead of pretending they are solved:

- full autonomy assessment refresh requires a qualified audit capability;
- owner composite-skill proof requires a qualified Skill Lab execution capability;
- Kevin Desktop runtime proof requires the bounded Desktop crossing to be installed and probeable in fixed:main.

## Production integration sequence

1. CI-prove Work Supply.
2. Produce a live effective-capability inventory from HESS-PC, not repository assumptions.
3. Cross the already-reviewed bounded Kevin Desktop plugin into fixed:main and prove positive and negative tests.
4. Integrate Work Supply before selection so the Supervisor selects from base items plus owner-approved supplied items.
5. Add mission leases and expose `BLOCKED_WORK_PRESENT` / queue depth / top blocker in HQ Truth.
6. Route eligible work to the worker that actually owns the qualified tool surface rather than forcing every job through a zero-tool main agent. See `docs/engineering/KEVIN-CAPABILITY-AWARE-ROUTING-v1.md` and `kevin-work-admission-v1.py` (Supply → Selector v1.2 → Router).
7. Re-run owner composite skills through Skill Lab and require a second semantic replay before `REPEATEDLY_PROVEN`.
8. Port receipt verification, tool budget, checkpoint/resume, provenance, and postcondition protections from older candidate PRs onto fresh main in small current-base slices rather than wholesale-merging stale branches.

## Success criteria

- An unresolved owner backlog can no longer display as `TRUE_IDLE`.
- Kevin cannot display `WORKING` without a live mission lease and machine evidence.
- A missing tool becomes a named blocker, not an invented success and not silent idleness.
- When owner work is temporarily unavailable, Kevin can execute due capability-learning or guardian work through already-qualified GREEN mechanisms.
- Every promoted capability is backed by real action receipts, semantic verification, and repeat replay.
