# LESSON — Skill Lab uncoupled from WAITING_ITEM_BUDGETS + throw-space fix (2026-09-11)

**Actor:** GROKBOT_ACTED (typed repair). Not Kevin-learned. Not PASS.

## Matt lock
Skill Lab must run GAP→LAB→PROVE even when Supervisor is THROTTLED / `waiting_item_budgets=true`. Floor may still paint THROTTLED for select HOLD. No Supervisor select. No Grok-bind. No budget reset.

## Coupling found
- Lab cron `kevin-skill-lab-v1` already fired every 120s, but capability progress looked frozen under budgets because (1) `OwnerWorkStage` only stages on `ROUTED_TO_SKILL_LAB` (Supervisor HOLD), and (2) floor truth lagged.
- Uncouple = runner continues while budgets wait; log `SKILL LAB UNCOUPLED_FROM_BUDGETS waiting_item_budgets=True (lab continues)`.

## failed=5 families
1. **malformed throw-as-cmdlet (3):** `throw'...'` without space → PowerShell cmdlet-not-found (`throwworkbook sheets invalid`). Fix: `throw '...'` in `kevin-skill-lab.ps1` v1.0.10.
2. **runner FAILED (2):** collision/replay; operator step failed — manifests retained; Lab requeue later, no new packs from RUNTIME.

## Regression
Invalid 0-sheet workbook while `waiting_item_budgets=true` → clean `REJECTED workbook sheets invalid` (not throwworkbook…). Proof under `reports/engineering/lab-throw-syntax-regression-REJECTED-2026-09-11.json`.

## Tick/Boot
`Kevin-Tick-Owned-Repairs` → `Publish-Kevin-HqLiveFloor -PushPublic` keeps live `skill_lab` counts. Lab cron remains independent of Supervisor select.
