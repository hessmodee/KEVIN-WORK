# LESSON — HQ single painter (2026-09-08)

**Family:** HQ dual-clock remount / false health flip  
**Surface:** GitHub Pages HQ (`docs/index.html` + `hq-core-v7.html` + `hq-owner-console-v10.js` + `sw.js`)  
**Not an owner outcome.** This is a display-stability repair. It does not invoke a skill, produce a workbook, or change HESS-PC.

## Defect

Two painters owned the same `#main`:

1. V7 core, every 15s, fetched raw `support-latest.json` from *inside* the iframe (missed the parent evidence adapter) and called `draw()`, which destroyed/recreated `#main` and the ops iframe on `#ops`.
2. V10 owner console, every 10s, fetched from the parent (adapter could promote Engineering lane health) and overwrote the same chrome.

`support.cron.ok=false` with `error: "Config warnings:"` is a known publisher lie. Engineering per-lane truth can still be healthy. Alternating those two clocks made HQ look like it was flipping healthy/dead and remounting the worker-owl floor.

A second remount lived inside V10 itself: `paint()` → `main()` assigned `innerHTML=opsHtml()` every 10s, recreating `ops/embed.html`.

## Repair

- Parent claims `window.__kevinOwnerConsoleV10` *before* the core iframe starts.
- V7 yields (`stopAutonomousPaint`) when the parent owns the document. Standalone `hq-core-v7.html` still paints.
- V10 `install()` is idempotent and stops V7 timers.
- V10 Ops tab updates hero/summary in place and does not remount the ops iframe.
- Service worker cache bumped to `kevin-hq-shell-v7`; retired V8 painters are no longer precached.

## Do not

- Hard-code HQ healthy over `cron.ok=false`.
- Treat this Pages deploy as Supervisor/Skill invocation proof.
- Reset continuation history to “fix” the flash.

## Positive test

Sit on HQ for 60 seconds. Data may refresh. `#main` must not remount the ops iframe. The status pill must not toggle on the 10s/15s beat.

## Negative test

With Engineering stale and Support `cron.ok=false`, HQ shows UNVERIFIED or a config-warning chip, not a healthy/dead flip.
