# KEVIN RECIPE — Stage + prove GREEN composite skills (Relay / Skill Lab) v1

Authority: GREEN only. No Relay shell. No Maintenance production_effect. fixed:main tools:false — use Relay.

## Inventory (how to list proven)
- Registry: `reports/capabilities/composite-skills.json` (status=PROVEN).
- Run receipts: `reports/action-era/skills/done/<id>--<ver>.json`.
- Primitives only: `create_text`, `create_spreadsheet`, `ui_notepad_write` (`reports/capabilities/proven-primitives.json`).

### Owner-value composites (2026-09-04 morning)
| Skill id | Status | Notes |
|---|---|---|
| dealer-vehicle-recon-command-pack@1 | PROVEN ~07:07 MT | create_spreadsheet + create_text |
| vehicle-diagnostic-research-pack@1 | PROVEN ~07:27 MT | create_spreadsheet + create_text |
| business-budget-starter-pack@1 | PROVEN earlier | create_spreadsheet + create_text |
| home-garage-organization-pack@1 | stage/prove target | 4 sheets — validates |
| creator-monetization-pipeline-pack@1 | next | 4 sheets — validates |
| cache-valley-appliance-repair-launch-pack@1 | REJECTED | 6 sheets > cap 5; repair before re-stage |

## Invoke (Relay request schema)
Remote repo: `hessmodee/KEVIN-WORK`.

1. Ensure skill JSON exists at `inbox/skills/<name>.json` with:
   - `schema:1`, `kind:"kevin-composite-skill"`, `authority:"GREEN"`
   - `id` 4..80 `[A-Za-z0-9._-]`, `version`, `name`, `steps` 1..12
   - Each step `operation` ∈ proven primitives + `payload`
2. SHA256 (UTF-8 bytes of exact file text) → `skill_sha256`.
3. PUT `inbox/engineering/request.json`:
```json
{
  "schema": 1,
  "kind": "kevin-engineering-request",
  "id": "unique-id-6-to-96-chars",
  "authority": "GREEN",
  "operation": "stage_composite_skill",
  "created_at": "<now ISO with offset>",
  "expires_at": "<now+hours ISO>",
  "params": {
    "skill_path": "inbox/skills/<name>.json",
    "skill_sha256": "<64 hex>"
  }
}
```
4. Wait Engineering Relay (~2m): `reports/engineering/latest.json` → status **STAGED** (or DUPLICATE_STAGED / REJECTED).
5. Wait Skill Lab (~2m/step): `skills/running` then `skills/done/<id>--<ver>.json` status **PROVEN**.
6. Confirm registry updated + outputs under `Documents\Kevin Outputs` (created by Green Operator).

Allowlisted Relay ops only: `snapshot`, `benchmark`, `action_selftests`, `action_status`, `stage_composite_skill`. Daily budget 24.

## Detect fail
| Signal | Meaning |
|---|---|
| latest.status REJECTED | Schema/SHA/path/authority/expiry |
| DUPLICATE_IGNORED | Same request.id already processed — mint new id |
| BUDGET_EXHAUSTED | Wait until next day MT |
| skills/failed status REJECTED | Manifest validation (sheet/col/name caps) |
| skills/failed status FAILED | Mid-run operator/order failure — read failure_reason + queue/failed |
| STAGED but idle forever | Skill Lab cron / mutex overlap — check cron last_status |

Preflight checklist before stage:
- sheets 1..5; cols ≤16; sheet name ≤31; filename allowlisted (.xlsx/.md/.txt); no overwrite of existing output name if operator blocks overwrite.

## Repair
1. Copy failure JSON + LESSON under `docs/engineering/LESSON-*.md`.
2. Fix skill JSON; bump content; recompute SHA; update GitHub `inbox/skills/...`.
3. New `request.id`; stage again.
4. If operator order failed: inspect `reports/action-era/queue/failed`, UI bridge heartbeat, ACTION-ERA-STATUS — do not invent shell.

## Record LESSON
- Write `docs/engineering/LESSON-<topic>-YYYY-MM-DD.md`.
- Append DAY-BEATS + `memory/YYYY-MM-DD.md`.
- Point from MEMORY.md / AGENTS.md teach-and-transfer (no competing handover; canonical AI-HANDOVER.md owned separately).

## Pointers
- SOUL.md / AGENTS.md: teach-and-transfer standing rule.
- MEMORY.md: durable facts; day file for beats.
- Eval/receipts: `reports/action-era/skills/done`, `reports/engineering/latest.json`, `reports/capabilities/composite-skills.json`.

### Owner-value updates (2026-09-04 ~08:55 MT)
| Skill id | Status | Notes |
|---|---|---|
| cache-valley-appliance-repair-launch-pack@3 | PROVEN ~08:33 MT | 5 sheets; do not re-prove |
| construction-daily-field-log-pack@1 | PROVEN ~08:51 MT | proof A7DDADFE... |
| crypto-research-paper-trading-pack@1 | stage/prove | paper-only; ZERO live trade |
| dealership-friction | N/A | not in inbox; dealer-vehicle-recon already PROVEN |

Aider local: see KEVIN-RECIPE-aider-ollama-scratch-v1.md (scratch only).

### Owner-value updates (2026-09-04 ~09:34 MT)
| Skill id | Status | Notes |
|---|---|---|
| tomorrow-field-work-command-pack@1 | PROVEN ~09:24 MT | proof 9DAD2E7920820A937FE84F5240FAF60902EA9CDA26A1D690B0FB41622402E5DC |
| equipment-tool-control-pack@1 | PROVEN ~09:32 MT | proof 327B135CE2FBDAFE3674E55DB441269FE72BEB01F7D72618A9FA72FF1E7BDA3A |
| vehicle-transport-mission-pack@1 | next | 5 sheets; validates; not yet PROVEN |
| crypto-research-paper-trading-pack@1 | PROVEN ~08:57 MT | paper-only; ZERO live trade |
