# LESSON — Skill Lab spreadsheet sheet-cap (max 5)

**At:** 2026-09-04 08:35 MT America/Boise
**Pattern:** skill-lab/workbook-sheets-cap
**Proven on:** cache-valley-appliance-repair-launch-pack@3 (request bess-stage-appliance-repair-v3-202609040829)

1. Skill Lab `Workbook` validation rejects any `kevin-xlsx-spec` with sheet count outside 1..5 (`throw 'workbook sheets invalid'`). A 6-tab launch pack fails at stage/run, not later.
2. Keep owner value by merging adjacent tabs instead of deleting them. For Cache Valley Appliance Repair, `Launch Checklist` folded into `Readiness Gates` (Blocking + Next Action columns) — still 5 sheets: Readiness Gates, Service Scope, Tool Plan, Pricing Model, Customer Intake.
3. Pin SHA-256 of the exact UTF-8 skill JSON in `inbox/engineering/request.json`; Engineering Relay fetches from hessmodee/KEVIN-WORK main and rejects hash mismatch.
4. Avoid non-ASCII punctuation in composite skill text payloads (em dashes, smart quotes). PowerShell `ConvertTo-Json` round-trips can mojibake Unicode, then Skill Lab `Match` fails with `work-order collision/replay mismatch` even after operator DONE. Prefer ASCII `-` / plain apostrophes.
5. After a failed same-id run, bump `version` and use unique output filenames (`Kevin ...`) so order ids and Kevin Outputs paths do not collide with prior attempts.
6. Do not reuse a processed request id (relay returns `DUPLICATE_IGNORED`). Budget is 24 GREEN remote requests/day.