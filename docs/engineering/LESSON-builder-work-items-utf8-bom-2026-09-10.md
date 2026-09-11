# LESSON — builder UTF-8 BOM crash (2026-09-10)

Not PASS. Isolated diagnose is not Action Era.

## What happened

After catalog repair and invocation v1.1.2 (`471E5051…`) were live on HESS-PC, diagnose published:

```
reason = Traceback
reason_class = BUILDER_REJECTED
python_exit = 1
invocation_py_sha256 = 471E5051…
builder_py_sha256 = 93A8A881…
```

Supervisor still published `BLOCKED_INVOCATION_RUNTIME` / `68845506…` because the worker treats any builder python exit 1 as invocation failure.

## Discriminating test

GitHub `inbox/autonomy/work-items.json` is valid UTF-8 JSON (no BOM). Builder v1.0.1 (`93A8A881…`) builds it (`BUILT`, exit 0).

The same bytes prefixed with UTF-8 BOM (`EF BB BF`) — PowerShell `ConvertTo-Json` / `Set-Content -Encoding utf8` default on Windows — make v1.0.1 raise `json.decoder.JSONDecodeError: Unexpected UTF-8 BOM` and exit **1** with a traceback on stderr.

Invocation v1.1.2 already strips BOM in `read_json`. The builder did not. Diagnose `Reason-FromJson` used PowerShell `-match`, which is case-insensitive, so the first capture of the traceback was the word `Traceback`.

## Causal fix

- Builder **v1.0.2** (`EC92A4E3…`): strip BOM, map JSON errors to `WORK_ITEMS_UTF8_BOM` / `WORK_ITEMS_UNREADABLE`, always print one JSON line, exit **2**.
- Diagnose v1.3.0: case-sensitive reason codes; map Unexpected UTF-8 BOM; if live python hashes mismatch, run Repair once (`-SkipDiagnose`) then retry.
- Repair: copies v1.0.2 onto the live unversioned builder path; strips BOM from `work-items.json`.
- Puller v1.4 retargets `BldExpected`.

v1.0.1 stays on disk as the historical pin. Unversioned GitHub builder stays `8E1CDB69…`. ControlPlane worker pin stays `16C49542…`. Do not recopy Supervisor.

## What Kevin should do next time

1. A python traceback is not a reason-code. Parse JSON first. Never publish `Traceback`.
2. Any JSON file written by PowerShell may have a BOM. Read with BOM strip (`utf-8-sig` or skip `EF BB BF`).
3. Builder failures must be `BuilderError` JSON + exit 2, never an uncaught exception + exit 1.
4. After a typed repair of this family, resume `owner-west-motor-parts-chase-fresh-8-v1`. Do not reset the 09:31 burned turn.

## Prevention

Regression: `tests/test_proven_skill_request_builder_v1.py` loads BOM work-items. Diagnose selftest refuses `Traceback` as a reason.

PASS still requires workbook + note + DONE + hashes + immutable receipt.
