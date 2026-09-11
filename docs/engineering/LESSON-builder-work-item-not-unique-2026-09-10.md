# LESSON — builder WORK_ITEM_NOT_UNIQUE (2026-09-10)

Not PASS. Isolated diagnose is not Action Era.

## What happened

Matt ran the GREEN-C paste for builder v1.0.2. Live hashes matched:

- invocation `471E5051…`
- builder `EC92A4E3…` (v1.0.2)
- puller v1.4
- `python_exit = 2`

Diagnose published `BUILDER_REJECTED` / `reason=WORK_ITEM_NOT_UNIQUE` at `2026-09-10T23:13:35-06:00`. That is a typed reject, not a traceback and not a Supervisor crash. The UTF-8 BOM family is closed.

GitHub `inbox/autonomy/work-items.json` on `main` is unique: 17 items, exactly one `owner-west-motor-parts-chase-fresh-8-v1`. GitHubBridge does **not** pull that file. HESS-PC local `work-items.json` is the file the builder reads. `len(matches) != 1` covers both **0 matches** and **2+ matches**. v1.0.2 could not tell them apart.

## Discriminating test

- 0 matches → `WORK_ITEM_NOT_FOUND` + `match_count=0`
- 2+ matches → `WORK_ITEM_NOT_UNIQUE` + `match_count>=2`
- GitHub source unique + local reject ⇒ local file diverged (duplicate, missing id, or rewritten shape). Do not reset history to create a clean retry.

## Causal fix

- Builder **v1.0.3** (`83B3EDA6…`): split the two reasons, emit `match_count` / `items_count`, `--repair-unique`.
- Repair unique: 0 matches inserts the canonical fictional 8-vehicle item; 2+ keeps the OPEN + 8-vehicle copy and archives extras under `inbox/autonomy/archive/`. Other WorkInstances stay.
- Diagnose v1.3.1 runs that repair once, then retries the builder. Puller **v1.5** pins `83B3EDA6…`.
- v1.0.2 (`EC92A4E3…`) stays as the BOM-safe historical pin. Unversioned GitHub builder stays until HESS-PC apply. ControlPlane worker pin stays `16C49542…`. Do not recopy Supervisor.

## What Kevin should do next time

1. `WORK_ITEM_NOT_UNIQUE` is not "the skill is missing" and not "reset the queue."
2. Count matches. Publish `match_count`. Never collapse 0 and 2+ into one reason again.
3. Repair the local JSON. Do not recopy Supervisor. Do not send the job to `fixed:main`.
4. After a typed unique repair, resume `owner-west-motor-parts-chase-fresh-8-v1`. Keep the 09:31 burned turn.

## Prevention

Regression: `tests/test_proven_skill_request_builder_v1.py` covers missing, duplicate, insert, and dedupe. Diagnose selftest parses both reason codes and `match_count`.

PASS still requires workbook + note + DONE + hashes + immutable receipt.
