# LESSON — home op-test preflight restore companion entry (2026-09-05)

## What happened
Live spike `scratch/kevin-minecraft-stack-spike-v0` had IMPORT/bridge smokes but was missing on-disk companion entry scripts (rejoin-companion / smoke-companion-wire). Parent restored cmd wrappers; worktree still held full bridge + rejoin-companion.js.

## Teach
1. Spike disk can drift from worktree after partial copies — always diff bridge/*.js sizes and assertNethernetReady / enableStayCompanion exports before claiming ready.
2. A rejoin-companion.cmd that only calls gym `rejoin.cmd` is **stay-only**, not companion. Companion op-test needs `node rejoin-companion.js` (JOIN_OK createClient → inject → enableStayCompanion).
3. Safe prep while Matt away: preflight-home-optest.cmd (ports/auth/smokes). Never kill Minecraft.Windows / Chat / Reader; exit 2 = CLOSE_REQUIRED.
4. Gym lock SHA256 26397A3E...865D is the JOIN_OK known-good; spike must not mutate it.

## Receipts
- IMPORT_OK / BRIDGE_SMOKE_OK / COMPANION_WIRE_SMOKE_OK / HOME_OPTEST_PREFLIGHT=GO
- rejoin-companion exit 2 with MC UI open
