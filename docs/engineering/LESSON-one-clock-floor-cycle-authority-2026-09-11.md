# LESSON: ONE CLOCK — hq-live-floor.cycle is authoritative

Matt P0 2026-09-11 ~22:55 MT: HQ shot showed cycle 449 while metal floor was >=463.

## Rule
- eports/hq-live-floor.json **cycle** is the only clock for paint.
- support-latest.supervisor.cycle must **never** overwrite floor cycle and must **never** be used as painter freeze sentinel.
- Publisher syncs support **UP** to floor only.
- Historic 449 was a dead support sentinel; floor never regresses below 450.

## Actor
GROKBOT_ACTED teach into `tools/Publish-Kevin-HqLiveFloor-v1.ps1` until Tick owns.

## Related
Dealership WI already Lab PROVEN → ROUTEd → five-pack; BLOCKED_INVOCATION_RUNTIME was builder gap (v1.0.5) — closed.
