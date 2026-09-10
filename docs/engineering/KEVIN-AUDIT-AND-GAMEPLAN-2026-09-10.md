# KEVIN AUDIT AND GAME PLAN — 2026-09-10 13:42 MT

Not PASS. Live evidence outranks the Sep 9 pasted audit.

## One-screen verdict

| Item | Live truth |
|---|---|
| HQ badge | **BLOCKED** (correct). Not degraded. Ops floor matches. |
| Platform | GREEN. Benchmark **30/30**, critical 0, RAM 33%, CPU 16%. Six scheduler lanes ok. |
| 8-vehicle job | Still **BLOCKED_INVOCATION_RUNTIME** / `68845506`. Turn 1 at 09:31 kept. |
| Catalog repair | **Ran** 12:53 MT. Live python `75D6031E…` / `93A8A881…`. Did not unblock stage (`ready=0` at 13:39). |
| Tools chip | Canary OMEN_PROVEN 2026-09-08 10:59 MT. Service rail already has `5 · CANARY STALE` in V10 source; Pages still cached `?v=7` so it paints **UNVERIFIED**. This PR cache-busts `?v=8` and uses `toolsChip()` on SKILLS/SYSTEM too. Tools exist. Do not widen. |
| Next repair | Invocation **v1.1.2** (`471E5051…`) + diagnose reason-code. |
| Chat / calculator | Exact-five **launch-only**. Notepad/Paint/Explorer are allowlisted. Tool does not type. qwen2.5:14b hallucinated operate. |
| First PASS | Workbook + note + DONE + hashes + receipt for `owner-west-motor-parts-chase-fresh-8-v1`. |

## Where we are

Kevin's **platform** works. Kevin's **execution muscle** for the owner outcome does not. Supervisor correctly selects the 8-vehicle WorkInstance and fail-closes instead of charging `fixed:main`. That is honest. Idle-without-reason would be the defect.

The calculator/Notepad chat is a **different lane**. Chat cannot write files or type. Action Era `create_spreadsheet` + `create_text` is how Kevin uses the computer for this job.

## Where we are going

1. First fresh PROVEN-skill PASS (8-vehicle board).
2. Repeat invocation of the other 26 PROVEN skills.
3. Then UI Phase 2 operate (Calculator/Notepad type) as a typed crossing — after PASS, not instead of it.
4. T4 for routine GREEN work: sense → repair → resume without Grok.

## Goals not yet accomplished

- 8-vehicle PASS
- Public python reason-code on every fail-closed invoke (this cycle ships the diagnose)
- Fresh main-agent canary (after 22:00Z if allowlisted)
- Console hygiene VBS if not already applied
- Post-22:00Z: do **not** re-queue worker v1.1; it is already applied
- Do not recopy Supervisor v1.8.12

## Game plan (this cycle)

1. Merge this PR (v1.1.2 + diagnose + pull-inbox v1.3).
2. Matt runs the Grokbot paste in FROM_GROK (same shape as the paste that already worked).
3. Read `reports/invocations/latest-public-reject.json`. If `STAGE_OK_WAITING_ACTION_ERA`, wait Supervisor + Action Era. If another reason-code, repair that family next — do not recopy Supervisor.
4. PASS definition unchanged.

## Desktop disconnect — root cause (verified)

OpenClaw 2026-09-09 17:14–18:33 MT: Matt asked Kevin to open Notepad and write a status note. `kevin_app_launch` fired. Kevin claimed to type "Hello, Matt". The tool contract is launch-only (`notepad.exe` / `calc.exe` / `mspaint.exe` / `explorer.exe`, no args). SOUL.md already forbids the claim. qwen2.5:14b ignored it.

Correct Chat reply: `LAUNCHED notepad. NOT_EXECUTED: capability_unavailable` for typing/saving.

This PR adds `typed:false` / `capability:launch_only` to the **source** plugin result so the model sees the boundary in the tool payload. Production Chat still uses the installed plugin until a typed desktop crossing. Do not widen exact-five to fake operate.

## Do not

Recopy Supervisor. Overwrite GitHub ControlPlane pin. Queue another worker install before 22:00Z. Widen tools. Send the 8-vehicle job to `fixed:main`. Claim this chat, this PR, or a diagnose JSON as PASS.
