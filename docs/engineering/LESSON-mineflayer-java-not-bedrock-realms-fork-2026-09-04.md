# LESSON: Mineflayer is Java Edition — Realms edition fork (2026-09-04)

**At:** 2026-09-04 ~14:42 MT
**Actor:** GrokBot-executor
**Result:** TEACH — do not apply live Realms until Matt names edition

## One-liner

**mineflayer ≠ Bedrock.** Mineflayer speaks **Java Edition** protocol only. Java Realms and Bedrock Realms are different products; the bot stack must fork on Matt's answer.

## Why it matters

- Local v0 prove (`KEVIN_MC_V0_OK`) used flying-squid + Mineflayer offline — that only validates **Java** protocol skills.
- Pointing the same bot at a Bedrock Realm will fail (wrong protocol), waste owner time, or tempt unsafe workarounds.
- Live apply must **ask/branch**, not guess. Until Matt says Java or Bedrock, edition = **UNKNOWN** and Realms join is blocked.

## Branch rule

| Matt Realm edition | Use |
| --- | --- |
| Java | Mineflayer (+ pathfinder) with Kevin MS auth; invite to existing Realm |
| Bedrock | Separate Bedrock-compatible stack PLAN; do not force Mineflayer |
| UNKNOWN | Docs + scratch only; refuse live Realms join (fail-closed) |

## Companion

- PLAN: `docs/engineering/PLAN-kevin-minecraft-realms-player-2026-09-04.md`
- Prior local prove LESSON: `docs/engineering/LESSON-minecraft-v0-local-prove-2026-09-04.md`
- Recipe (scratch): `docs/engineering/KEVIN-RECIPE-mineflayer-scratch-v1.md`

## Invariants

- No invent Microsoft passwords; no Realms purchase without separate auth
- Prefer invite to Matt's existing Realm
- Credentials Kevin-local never git
- Do not kill Chat 18789 / Reader 19001; do not widen Desktop in Realms PLAN
