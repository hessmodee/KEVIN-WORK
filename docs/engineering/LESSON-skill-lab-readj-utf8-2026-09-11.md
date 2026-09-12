# LESSON — Skill Lab ReadJ must use UTF8 (2026-09-11)

**Actor:** GROKBOT_ACTED (kevin-skill-lab.ps1 v1.0.11). Not Kevin-learned. Not PASS.

## Symptom
After Lab `W()` wrote UTF8 running-state JSON, each tick called `Skill $manifest` via `ReadJ` using `Get-Content -Raw` **without** `-Encoding UTF8`. Windows PowerShell mis-decoded the file; `create_text` `content.Length` inflated (~2x) past the 60000 cap → `SKILL LAB ERROR text cap` loop while AE order was already DONE. Blocked Consume/PROVE for `cache-valley-appliance-repair-launch-pack@2`.

## Fix
`ReadJ`: `Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json` (match `W()` UTF8Encoding).

## Proof
cache-valley@2 PROVEN after v1.0.11 (create_spreadsheet + create_text only).

## Standing bans (Matt via CoS)
- No `ui_notepad_write` / Notepad as Lab proof. Do not requeue `engineering-relay-first-composite`.
- Floor center/`painted_hint` never `OUTCOME_PROVEN` under HOLD — THROTTLED (budgets) or READY (idle). Stripes use `west_motor_proven` / `transport_proven` / `outcome_proven` fields.
