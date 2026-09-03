# CURRENT_TASK

**Updated:** 2026-09-03 ~08:45 MT  
**Owner priority:** establish one automatic cross-AI handover/source-convergence system first; then continue Kevin computer fluency, UI reliability, tool exposure, and autonomous learning with minimum Matt intervention.

## P0 — canonical handover and cross-AI convergence

Matt requires one current handover that survives abrupt ChatGPT/Grok/model/token/credit/session turnover and is accessible to ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin and other agents.

Target contract:

- `AI-HANDOVER.md` is the **only human current handover**.
- `reports/handoff-latest.json` is its machine twin only, never a competing authority.
- `.github/scripts/build-canonical-handover.py` derives the handover from current task + published Support/Engineering/autonomy evidence.
- `.github/workflows/canonical-handover.yml` refreshes after `main` changes and every ten minutes as a backstop, with bounded race retry and no unchanged-state churn.
- Kevin HQ exposes `docs/handover.html`, which displays the raw canonical file from `main` and links GitHub/raw access.
- Every AI checkpoints after every material repair/proof/production/task transition rather than waiting for an end-of-chat handoff.
- **Local-only durable work is unfinished work.** Grokbot/local agents must publish the corresponding repository source and sanitized proof/receipt after direct HESS-PC work. Remote GitHub work is not production until HESS-PC proves it installed.
- One outside AI writer at a time; Kevin's qualified local schedulers may continue.

Current implementation branch: `bess-canonical-handover-v1-20260903`. Finish CI/PR, merge, verify the automatic refresh commits a current `AI-HANDOVER.md`, and verify the HQ route loads it.

## P1 — current live platform truth

Fresh published HESS-PC evidence now shows:

- Benchmark **PASS 30/30, critical 0**. The old R04 29/30 handover state is obsolete and must not be resurrected.
- Support/Engineering scheduled jobs are enabled and reporting `ok` with zero consecutive errors.
- Supervisor last result remains `NO_ELIGIBLE_MISSION`; current useful computer-fluency demand must be put into the governed selector instead of manufacturing cycles.
- Engineering reports UI Bridge task/hash present but heartbeat materially stale (about 5,853 seconds at the 08:40 MT snapshot). Do not call it healthy from task/hash presence.
- Skill Lab reports 9 proven composites; latest proven `kevin-ui-recovery-functional-proof@1` uses `ui_notepad_write`.
- Installed Maintenance identity reported by fresh Support is `AC55B4813F39642E82E8C19B2CB0CEFB6D7D5BCF953470B66B33773909436A0D`.

## P1 — Kevin Desktop / local computer fluency

Candidate branch: `bess-local-computer-fluency-v1-20260903`  
PR: **#47 — Add bounded local desktop control for Kevin**

Candidate adds:

- `kevin_desktop_find_folder`
- `kevin_desktop_open_folder`
- `kevin_app_launch` for fixed reviewed apps (Notepad, Calculator, Paint, Explorer)
- durable local-computer-fluency curriculum and cross-platform plugin validation.

Push candidate gate run `33766748609` passed on Ubuntu and Windows, including unit tests, TypeScript build, generated metadata identity, and OpenClaw plugin validation. This is **CI-PROVEN candidate only**.

PR #47 became non-mergeable after `main` advanced. Reconcile/rebase the candidate with current main, rerun CI, review the resulting diff, then merge only if green. Do not call it installed yet.

After merge, build/use a typed, pinned, reversible installation crossing; expose only the smallest intended fixed:main surface (`kevin_system_status` plus the three bounded Desktop tools); preserve protected denies; then prove real HESS-PC owner-intent round trips and forbidden negative cases.

## P1 — fixed:main tool surface

Current diagnosis proved fixed:main effectively has no useful Kevin tool inventory despite the root coding profile. Do not solve this by granting broad `exec`, arbitrary filesystem, arbitrary process/browser/session or caller-selected shell authority.

Required crossing after qualified Desktop install:

1. expose only intended typed Kevin tools;
2. prove a useful allowed natural-language action;
3. prove forbidden/action-negative cases fail closed;
4. independently verify the real desktop/app postcondition on HESS-PC;
5. keep Benchmark 30/30 critical0.

## P1 — UI Bridge liveness/watchdog

The UI Bridge liveness watchdog candidate currently fails closed at its staged self-test before installation. Repair the watchdog generator/contract, validate it, install only through a typed/reversible path, and require multiple advancing READY/WORKING heartbeats plus a unique Notepad round trip that does not disturb an owner window.

Do not equate the proven `ui_notepad_write` composite or UI task presence with current bridge liveness.

## P2 — teach Kevin to own the work

For every successful outside repair/crossing:

`detect -> classify -> gather evidence -> select qualified action -> execute -> verify semantic postcondition -> recover/rollback -> record -> create/revise procedure -> replay on a second representative task -> promote responsibility`

Put real `computer-fluency` owner demand into the governed selector so Supervisor/Tick can select and continue it without Bess supplying a work-item ID. Treat each step still performed by Bess/Grok as autonomy debt until Kevin reaches T4/T5 with repeated evidence.

## Coordination

`AI-HANDOVER.md` is canonical. Fresh runtime evidence outranks prose. The scheduled ChatGPT `Kevin Chief Engineer` is paused while this foreground Bess session mutates shared state; re-enable it only after the handover branch is merged/reconciled and update its prompt so it obeys the automatic canonical handover/local-work convergence contract rather than the obsolete R04 bootstrap checkpoint.
