# Kevin Open PR / WIP Classification — 2026-08-31

Purpose: reduce candidate pile-up, duplicate integration reasoning and false WIP. This is a classification/cleanup plan, not proof that a PR may be deleted without preserving evidence.

Default active WIP cap from the Autonomy Master Plan:
- 1 ACTIVE production/proof crossing
- 1 STAGING/EVAL item
- 1 RESEARCH/DESIGN item with a named downstream consumer

## Current classifications

| PR | Subject | Classification | Decision / reason |
|---|---|---|---|
| #31 | HQ direct-chat typed transport | **SUPERSEDED / EVIDENCE REFERENCE** | Exact proven candidate bytes were published to current `main` via merged PR #33. Keep head/gate evidence in handoff, but do not treat draft #31 as active WIP. |
| #30 | HQ direct-chat base | **SUPERSEDED / EVIDENCE REFERENCE** | Exact candidate subtree was published to `main` through #33. Production crossing remains active as a new Maintenance integration task, not as continued speculative work on #30. |
| #29 | Sanitized OS Awareness -> Support/HQ contract | **STAGING/EVAL (P1)** | Useful near-term integration, but not allowed to displace current P0 work-selection/HQ crossing. Advance only when staging slot is available. |
| #26 | GREEN OS Awareness v0.1 | **SUPERSEDED / PROOF REFERENCE** | OS Awareness v0.1 is already OWNER-AUTHORIZED + OMEN-PROVEN through later production path. Preserve evidence; do not treat draft as unfinished core work. |
| #25 | Skill Lab v1.0.4 Windows runtime fix | **VERIFY-THEN-SUPERSEDE** | Live Skill Lab is successfully proving composites. Confirm exact installed/current runner lineage once, then close/supersede stale candidate branch if later production identity covers it. |
| #24 | Self-maintenance transport + watchdog | **SUPERSEDED / ARCHITECTURE REFERENCE** | Typed Maintenance v1.3.3 and later watchdog work now exist/proven. Preserve useful architecture notes, but do not treat old PR as active production crossing. |
| #23 | Out-of-band self-heal watchdog | **SUPERSEDED / ARCHITECTURE REFERENCE** | Later self-reliance/watchdog line supersedes this initial candidate. |
| #22 | Typed GREEN Maintenance v1.2 | **SUPERSEDED / PROOF REFERENCE** | Production Maintenance is v1.3.3, so v1.2 draft is historical proof/evidence. |
| #21 | Skill Lab v1.0.3 crash-safe recovery | **VERIFY-THEN-SUPERSEDE** | Important recovery lessons, but later v1.0.4/source and current successful Skill Lab likely supersede it. Confirm installed lineage and preserve fixtures before closing. |
| #19 | Browser observe/navigate contract | **RESEARCH REFERENCE / FUTURE STAGING** | Valuable P1 contract. Do not promote broad browser authority while P0 communication/work-selection is unresolved. Use native OpenClaw managed browser/computer capabilities as comparison before bespoke production work. |
| #17 | Integrated autonomy control-plane | **STAGING/EVAL FOUNDATION** | Directly relevant to current work-conservation defect. Do not assume its CI behavior equals live production behavior. Use its adversarial cases/architecture as input to a simpler demand-aware work-selection repair. |
| #16 | Knowledge provenance/freshness | **RESEARCH REFERENCE** | Keep as design/eval source for Second Brain/provenance. Not current active WIP. |
| #15 | Postmortem / three-failure cooling | **RESEARCH REFERENCE / RULE SOURCE** | Its cooling/failure-evidence concept is now part of master doctrine. Consider folding validated invariants into the domain eval stack rather than keeping a standalone active lane. |
| #14 | Tool Budget Governor | **RESEARCH REFERENCE** | Useful budget/no-progress invariants. Compare with native OpenClaw workflow/task limits and retain only controls that still add measurable value. Not current active WIP. |

## Active WIP after classification

### ACTIVE production/proof crossing
**HQ direct chat Maintenance/Work-Order production crossing** — source is on main; next boundary is exact typed installation path -> Omen -> owner round trip.

### STAGING/EVAL
**Work-selection / Tick autonomy no-spin repair** takes priority because current live autonomy can say `NO_DISPATCH_NEEDED` with explicit owner backlog and zero workers. PR #17 may provide tests/reference but is not itself the production claim.

### RESEARCH/DESIGN
Only one named item at a time. Current recommended research consumer: native OpenClaw durability/skill/channel capability inventory directly supporting work-selection, communication, memory and skill-learning migrations.

## Cleanup rule

Chief Engineer should close/supersede stale draft PRs when:
1. exact useful head/evidence is recorded in handoff/docs;
2. a later production-proven descendant clearly supersedes it, or exact source was already published to main;
3. no active CI/integration dependency still targets the branch;
4. closing does not delete required evidence.

When closure tooling is unavailable, mark it explicitly SUPERSEDED in durable docs/comments and exclude it from WIP/priority calculations.

Do not create a replacement PR merely to clean up the PR list.
