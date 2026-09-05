# RECEIPT - Bedrock Realms AUTH_CACHE_OK + NETHERNET_GATE (join timeout)

At: 2026-09-04 ~23:52 MT
Actor: GrokBot-executor (HESS-PC)
Status: **AUTH_CACHE_OK** yes; join = **NETHERNET_GATE** / REALMS_JOIN_TIMEOUT (not KEVIN_REALMS_JOIN_OK)

## Auth

- Device-code MST5AFKQ completed by Matt as **kevinsk8erkid** (browser: "All done! You're now signed in to Minecraft for Nintendo Switch", profile K).
- Poller printed `AUTH_CACHE_OK` + `[msa] Signed in with Microsoft` in `scratch/kevin-minecraft-bedrock-v0/_auth-run.log`.
- Cache warm at `credentials/kevin-minecraft/` (profilesFolder): `6eb2d0_{live,xbl,mcs,pfb,bed}-cache.json` present (secrets never printed / never committed).
- Never hessmodee. No invented passwords. Chat 18789 / Reader 19001 left listening.

## Join attempt

```
[realms] gamertag: kevinsk8erkid
[realms] profilesFolder: ...\credentials\kevin-minecraft
[realms] pick hint: HESSMODEE
[realms] chosen: HESSMODEE's Realm
[realms] err Connect timed out
REALMS_JOIN_TIMEOUT
Possible NETHERNET_GATE (Realms 26.10+ JSON-RPC). See PrismarineJS bedrock-protocol #717.
EXIT=4
```

- Auth tokens sufficient to list/pick Realm (HESSMODEE's Realm).
- RakNet/connect path timed out at 60s -> classified **NETHERNET_GATE** residual (no JSON-RPC error string, but matches PLAN/LESSON expected post-auth gate).

## Tokens

| Token | Value |
| --- | --- |
| AUTH_CACHE_OK | **yes** |
| Join result | **NETHERNET_GATE** (REALMS_JOIN_TIMEOUT exit 4) |
| KEVIN_REALMS_JOIN_OK | no |

## Residuals

1. Live spawn still blocked by NetherNet / Realms signalling (bedrock-protocol #717) until library/protocol support lands or Microsoft path changes.
2. Do not re-run device-code unless cache deleted or AUTH_CACHE_OK regresses.
3. Do not invent credentials or use hessmodee for bot.

## Companion

- LESSON: `docs/engineering/LESSON-bedrock-realms-device-code-nethernet-2026-09-04.md` (update ~23:52 MT)
- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Scratch log: `scratch/kevin-minecraft-bedrock-v0/_realms-join.log`
- Prior auth LESSON: `docs/engineering/LESSON-bedrock-device-code-firstparty-otc-2026-09-04.md`
