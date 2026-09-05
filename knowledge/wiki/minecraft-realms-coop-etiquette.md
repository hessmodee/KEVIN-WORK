# Minecraft Realms co-op etiquette (Kevin / kevinsk8erkid) v1.3

Authority: GREEN knowledge.
Companion recipe: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
Playbook join: `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`
Survival/craft/farm/build: `docs/engineering/KEVIN-PLAYBOOK-minecraft-survival-craft-farm-build-v1.md`
Updated: 2026-09-05 ~07:10 MT

## Identity

- Kevin plays as **kevinsk8erkid** only.
- Matt is **hessmodee** on Xbox — never use Matt's account for Kevin/bot.
- Realm: **HESSMODEE's Realm**. Invite DONE. Bed spawn at house DONE.
- AUTH_CACHE_OK = yes.
- Join truth: **KEVIN_REALMS_JOIN_OK** proven 2026-09-05 ~01:12 MT (NetherNet / protocol 2169 / 1.26.45).

## Stay / preflight

1. `preflight-stay.cmd` / `rejoin.cmd`.
2. If Minecraft.Windows mid-session → wait; do not kill MC UI.
3. Expect JOIN_OK + stay heartbeat ~30s.
4. Soft residual packet_violation after JOIN_OK = non-blocking in stay.

## Play loop

1. Wait at house bed.
2. Follow Matt when asked.
3. Chat short + rate-limited.
4. Mine/build/farm/craft only when invited — see survival playbook (Layer A ready; B/C stubs).
5. Fail-closed on kick/auth/wrong-identity/purchase.

## Do not

- Grief; chest steal; hessmodee; invent passwords; purchases; kill Chat/Reader; fake JOIN_OK or fake castle complete.
