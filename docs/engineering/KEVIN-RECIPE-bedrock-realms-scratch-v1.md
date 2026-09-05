# KEVIN-RECIPE: bedrock Realms co-op scratch v1

## Intent

Join Matt Bedrock Realm as kevinsk8erkid with fail-closed auth.

## Steps

1. Owner: run install-deps.cmd in scratch/kevin-minecraft-bedrock-v0
2. Owner: node scripts/device-code-auth.js (browser device code as kevinsk8erkid)
3. Eng: node scripts/realms-join.js -> KEVIN_REALMS_JOIN_OK
4. Etiquette: no grief; follow Matt; respawn at house bed

## Fail-closed

- No token cache -> READY_FOR_OWNER_DEVICE_CODE
- Missing deps -> MISSING_DEPS / READY_FOR_OWNER_NPM
- NetherNet JSON-RPC -> NETHERNET_GATE (document; no hessmodee fallback)
