# Kevin HESS Self-Reliance — Bridge Recovery + Invoke Unblock (v1)
**Date:** 2026-09-11 · **Owner goal:** Matt need not be home for routine HESS recovery  
**Authority:** GREEN · **Not PASS** until west-motor workbook+receipt

## Why this exists
Grok Bot local-exec flaps leave CoS unable to shell HESS. Kevin must own recovery of *his* runtime (puller/sticky/diagnose/Supervisor reselect) without waiting for Matt to babysit reconnect UX.

## Two planes (never confuse)
1. **Cursor/Grok Bot Computers link** — Matt or always-on Grok Bot on Omen; Kevin cannot repair Cursor cloud pairing from inside OpenClaw alone.
2. **Kevin runtime (OpenClaw workspace)** — Kevin CAN own: puller v1.6, sticky quarantine, diagnose v1.3.2, Supervisor re-select, skill prove.

## Kevin-owned GREEN loop (when he has any local shell / BootRecovery / Tick)
1. SENSE: read `reports/autonomy-continuation-latest.json`, `reports/invocations/latest-public-reject.json`, `reports/bridge-latest.json`
2. If `BLOCKED_INVOCATION_RUNTIME` / `68845506…`:
   - Run `pull-inbox.ps1` (v1.6) OR BootRecovery path that pulls `omen/pull-inbox.ps1`
   - Expect sticky repair + diagnose; publish worker_live_sha256
3. If diagnose `STAGE_OK_WAITING_ACTION_ERA` + `supervisor_request_id_reason=STAGE_OK`: wait Supervisor; do not recopy Supervisor
4. If typed reason leftovers: sticky quarantine already should heal; re-select WorkInstance `owner-west-motor-parts-chase-fresh-8-v1`
5. VERIFY: workbook + note + DONE + hashes + immutable receipt = PASS only
6. LEARN: append LESSON + failure-family classifier; auto-resume objective

## Ground truth 2026-09-11 ~13:43 MT (public)
- Diagnose v1.3.2: `STAGE_OK_WAITING_ACTION_ERA`, `sticky_repair=ALREADY_CLEAN`, `supervisor_request_id_reason=STAGE_OK`, worker live matches expected v1.1 (`7E1129B7…`)
- `live_action_era_ready_invoke_count=0` and Action Era `ready=0` / `failed=1` / `done=70` — expected after sticky quarantine until live Supervisor re-stages `invoke-owner-west-motor-parts-chase-fresh-8-v1`
- Continuation still `BLOCKED_INVOCATION_RUNTIME` / `68845506…` until live invoke succeeds
- ControlPlane Supervisor snapshot may show `NO_ELIGIBLE_MISSION` — do not confuse with autonomy-continuation selected_id

## Matt-only residual (until Kevin has out-of-band wake)
Keeping **Grok Bot desktop signed-in + Computers Always allow + Sleep Never** on Omen so *any* remote agent can reach HESS. Document in BootRecovery/HQ Attention as ATTN if bridge stale >N minutes.

## Access bridge for any AI Matt tasks
Public repo: `AI-HANDOVER.md`, `inbox/CURRENT_TASK.md`, `inbox/FROM_GROK.md`, `reports/*`. No invented remote shell.

## Minecraft
Paused per Matt 2026-09-11. Do not prioritize FIND_WOLF until autonomy/west-motor PASS.
