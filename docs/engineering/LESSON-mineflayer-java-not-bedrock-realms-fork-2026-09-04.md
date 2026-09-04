# LESSON: Mineflayer is Java Edition — Realms edition fork (2026-09-04)

**At:** 2026-09-04 ~14:42 MT; **amended ~15:05 MT**
**Actor:** GrokBot-executor
**Result:** TEACH — edition **Bedrock LOCKED**; Mineflayer Realms = **NON-PATH** (side gym only)

## One-liner

**mineflayer ≠ Bedrock.** Mineflayer speaks **Java Edition** protocol only. Matt confirmed the Realm is **Bedrock** (screenshots 2026-09-04). Keep Mineflayer as a **Java side gym**; do **not** point it at Matt's Realm.

## Why it matters

- Local v0 prove (`KEVIN_MC_V0_OK`) used flying-squid + Mineflayer offline — that only validates **Java** protocol skills.
- Pointing the same bot at a Bedrock Realm will fail (wrong protocol), waste owner time, or tempt unsafe workarounds.
- Live apply must follow the **Bedrock** stack (`bedrock-protocol` + `prismarine-auth`), not guess or force Mineflayer.

## Branch rule (LOCKED)

| Matt Realm edition | Use |
| --- | --- |
| **Bedrock (LOCKED)** | `bedrock-protocol` + `prismarine-auth`; Kevin MS on Omen; invite to existing Realm |
| Java | N/A for this Realm |
| Mineflayer / flying-squid | **Side gym only** (`scratch/kevin-minecraft-v0`) — **NON-PATH for Realms** |

## Account model (Matt 2026-09-04)

- Matt plays Xbox as **hessmodee**
- Kevin uses **Kevin's own Microsoft account on the Omen PC**
- Prefer **invite** Kevin to existing Realm (HESSMODEE's Realm / Electric Boogaloo 2 / Hall of Heroes / Realm Hub)
- **No** new paid Realm purchase without separate auth
- **No** invent Microsoft passwords; credentials Kevin-local never git

## Companion

- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Prior local Java prove LESSON: `docs/engineering/LESSON-minecraft-v0-local-prove-2026-09-04.md`
- Recipe (Java gym): `docs/engineering/KEVIN-RECIPE-mineflayer-scratch-v1.md`
- Bedrock scratch README: `scratch/kevin-minecraft-bedrock-v0/README.md`

## Invariants

- No invent Microsoft passwords; no Realms purchase without separate auth
- Prefer invite to Matt's existing Realm
- Credentials Kevin-local never git
- Do not kill Chat 18789 / Reader 19001; do not widen Desktop in Realms PLAN
- No live Realm join in docs-only runs
