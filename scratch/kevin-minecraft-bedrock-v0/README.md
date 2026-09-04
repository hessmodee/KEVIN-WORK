# scratch/kevin-minecraft-bedrock-v0 — README only (no live auth)

Authority: FREE/SAFE research scaffold. UNDYING GREEN+YELLOW.
Companion PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
Edition: **Bedrock LOCKED** (Matt 2026-09-04 screenshots).

## Goal

Prepare a Bedrock protocol scratch path so Kevin can later join Matt's **existing** Realm as Kevin's own Microsoft account (Omen PC), after invite — **not** via Mineflayer.

## Candidate packages (install later; not required for this README)

- `bedrock-protocol` (PrismarineJS) — Bedrock/RakNet client; optional `realms` join helpers
- `prismarine-auth` — Xbox/Microsoft device-code auth; token cache **Kevin-local only**

Optional later high-level layer: community Mineflayer-like Bedrock wrappers (evaluate freshness before adopting).

## Local prove target (next free eng; still no Realms)

- Marker: `KEVIN_MC_BEDROCK_V0_OK`
- Prefer localhost UDP **19132** offline / Bedrock Dedicated Server (BDS) LAN
- Do not bind Chat 18789, Reader 19001, or Ollama 11434
- No Microsoft login for local v0

## Realms join (later; RED until owner invite + auth)

- Matt Xbox: **hessmodee**; Realm: HESSMODEE's Realm / Electric Boogaloo 2 / Hall of Heroes / Realm Hub
- Kevin: own MS account on Omen; invited member — **no new paid Realm**
- Device-code auth; secrets never git/MEMORY/HQ
- Gate: Realms 26.10+ may require NetherNet/JSON-RPC signalling — verify before claiming Realm-ready
- Live marker later: `KEVIN_REALMS_COOP_OK`

## Hard no

- No live Realm join in this scaffold
- No invent Microsoft passwords
- No purchase
- No Chat Minecraft tool
- No kill Chat/Reader
- No commit of auth caches or tokens
- Mineflayer Java gym is separate: `scratch/kevin-minecraft-v0` — **NON-PATH for Realms**
