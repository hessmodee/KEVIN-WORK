# LESSON — HQ one clock is hq-live-floor.json (2026-09-14)

## Defect
GitHub Pages HQ could still paint Support `supervisor.cycle` 449 after the floor
file had advanced past 690 with today's MIXED parts-chase refresh receipt.

This was not a healthy/unhealthy flip. It was cycle-authority bleed:

- `reports/hq-live-floor.json` is the Tick-owned clock (`cycle_authority: hq-live-floor`).
- `reports/support-latest.json` `supervisor.cycle` is a leftover publisher field.
- The P0 floor painter already knew this, but production loaded it through a
  16-chunk base64 eval loader. Service worker `v16` precached those chunks and
  strips query-string cache-busts, so a failed or stale loader left V7/V10
  reading Support.

## Repair
1. Inline `docs/hq-p0-floor-painter-v1.js` (real source, no atob loader).
2. V10 fetches `reports/hq-live-floor.json` and labels Support cycle as bleed.
3. Service worker `kevin-hq-shell-v17` (drop b64 SHELL entries).
4. Tick publish scans all `invoke-owner-*.json` in `invocations/done` for
   `last_invoke_completed_at` instead of freezing on the transport receipt.

## Tests
- Source: `tools/test-hq-one-clock-v1.py`
- Positive: sit on HQ 60s; painted cycle follows floor, not 449.
- Negative: with Support 449 and floor 694, HQ shows floor 694 + a bleed chip.
- Do not treat this paint repair as `kevin_proven_skill_invoke` or KEVIN_ACTED.

## Do not
Recopy Supervisor. Enable Night Forge / Hermes / ClawHub. Write HEARTBEAT.md.
Force-execute the refresh WI. Push from `kevin-work-repo` dirty branch.
