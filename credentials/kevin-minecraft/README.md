# credentials/kevin-minecraft — README ONLY (no secrets)

Authority: UNDYING GREEN+YELLOW. Teach-and-transfer.
Companion: docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md
Scratch: scratch/kevin-minecraft-bedrock-v0

## Purpose

Kevin-local cache for Microsoft/Xbox device-code tokens used by bedrock-protocol + prismarine-auth when joining Matt's Bedrock Realm as **kevinsk8erkid**.

## Paths (HESS-PC / Omen)

- Token cache dir (profilesFolder): this directory
- Expected cache files after owner device-code: opaque prismarine-auth cache JSON (names vary)
- NEVER commit contents of this folder to git

## Hard no

- No hessmodee credentials here (Matt Xbox = hessmodee is Realm owner only)
- No invent Kevin MS password
- No paste tokens into MEMORY / HQ / Slack / PLAN / receipts
- No purchase

## Owner next

1. Double-click or run: scratch/kevin-minecraft-bedrock-v0/install-deps.cmd
2. When eng reports READY_FOR_OWNER_DEVICE_CODE, run the printed node script and complete browser/device code as **kevinsk8erkid**
3. Tokens land here; eng then retries Realms join (NetherNet gate may still block 26.10+)
