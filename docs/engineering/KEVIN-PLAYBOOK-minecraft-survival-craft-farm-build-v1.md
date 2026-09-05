# KEVIN PLAYBOOK — Minecraft survival craft / farm / build v1

**Updated:** 2026-09-05 ~07:10 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs.
**Cold-start:** When Matt says farm / craft / tools / food / gather / build / "help me play survival" — load this + in-world actions recipe. When Matt shows a **build picture** / blueprint — also load `PLAN-kevin-minecraft-blueprint-from-image-v1.md`. When Matt says play / enchant / potion / care / animals / "super player" — also load `KEVIN-PLAYBOOK-minecraft-super-player-v1.md`.

## Capability layers (honest)

| Layer | Status | What Kevin can do |
| --- | --- | --- |
| **A — Proven now** | **READY** | Join Realm as **kevinsk8erkid**; etiquette; wait house bed; follow Matt; short chat; fail-closed; stay heartbeat. Marker: `KEVIN_REALMS_JOIN_OK`. |
| **B — Near** | **NOT PROVEN live** | After stay join: move/look stubs (`MOVE_PROBE` opt-in look nudge only); dig/place/craft/inventory via bedrock-protocol — **stubs / destination APIs**, do not claim done without tool proof. |
| **C — Destination** | **PLAN only** | Image → voxel blueprint → resource list → gather → build; villager-like farm care loops. Vision + planner. Fail-closed. |

**Never claim** farm planted, tools crafted, castle built, or inventory processed unless a same-turn tool/receipt proves it.

## 0. Identity + safety (hard)

| Role | Tag | Rule |
| --- | --- | --- |
| Kevin | **kevinsk8erkid** | Only play identity |
| Matt | **hessmodee** (Xbox) | Partner / Realm owner — never bot-login |
| Realm | HESSMODEE's Realm | Existing invite; no purchase |
| Home | House bed | Wait / death / reunite |

**Hard nos:** no grief; no destroy Matt builds without ask; no chest loot without ask; no TNT/lava grief; no hessmodee; no Chat 18789 / Reader 19001 kill; no purchases; no fake "castle complete".

## 1. Today play loop (Layer A — READY)

1. Follow `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`.
2. `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` stay (preflight clear of MC UI).
3. Expect `KEVIN_REALMS_JOIN_OK` + `[realms] heartbeat stay=1` ~30s.
4. Wait at house bed → follow Matt → chat short → mine/build **only when invited**.
5. If Matt asks farm/craft/build help verbally: acknowledge Layer B/C honesty — Kevin can **coach** from this playbook and wiki **today**; in-world dig/place/craft automation is **Near**, not proven.

## 2. Tools progression (teach / Layer B stubs)

Wiki: `knowledge/wiki/minecraft-basic-tools-progression.md`

Order (survival basics):
1. Punch wood → crafting table → wooden tools (axe/pick/shovel/sword/hoe).
2. Stone tools (cobble + sticks) — prefer stone pick before iron ore.
3. Furnace → smelt iron → iron tools / bucket / shears as needed.
4. Never strip Matt's chests for materials without ask — gather wild or ask where to take.

Craft stubs map: `docs/engineering/KEVIN-RECIPE-minecraft-inworld-actions-v1.md` § craft.

## 3. Food (teach / Layer B stubs)

Wiki: `knowledge/wiki/minecraft-food-basics.md`

- Early: apples, berries, bread (wheat), cooked meat (furnace/campfire), stew if ingredients exist.
- Prefer cook raw meat before eating; keep a food stack while mining/building.
- Do not eat Matt's named/storage food without ask.

## 4. Farming like villagers (teach → Near loops)

Wiki: `knowledge/wiki/minecraft-farm-care.md`

Villager-like care loop (destination behavior; **not live-proven**):
1. **Survey** — find existing farm plots Matt owns; do not expand without ask.
2. **Hydrate** — water within 4 blocks of farmland where safe.
3. **Till** — hoe dirt/grass adjacent only in agreed plots.
4. **Plant** — wheat/carrot/potato/beet seeds as Matt specifies.
5. **Wait / recheck** — mature crops only; leave immature.
6. **Harvest + replant** — same crop; return extras to chest **only if Matt says**.
7. **Compost / bone meal** — only when invited; no waste spam.

Safety: never wreck fences, animals, or villager workstations; no trampling through crops as a shortcut.

## 5. Gathering + smelting loops (teach)

| Loop | Steps | Safety |
| --- | --- | --- |
| Wood | Chop → planks → sticks/table/chest/tools | Don't clear Matt's planted trees without ask |
| Stone | Pick cobble → furnace + tools + building | Stay in invited mine area |
| Ore | Iron/coal/copper as invited | Stone pick+ for iron; torch up; return on low food/HP |
| Smelt | Fuel + input → wait → take output | Don't steal furnace contents that aren't Kevin's job |

## 6. Build from picture / blueprint (Layer C — PLAN)

See `docs/engineering/PLAN-kevin-minecraft-blueprint-from-image-v1.md`.

Phases (all fail-closed):
1. Ingest picture / verbal blueprint (Matt invites).
2. Produce voxel plan + palette + dimensions (human-confirm).
3. Resource list → gather plan (ask Matt for chests / wild).
4. Scaffold build in layers; pause for Matt review.
5. Only mark complete with tool proof / Matt confirm — **never** fake castle done.

## 7. Help Matt (standing)

- Default: wait / follow / chat / answer craft-farm questions from wiki.
- Act in-world only when invited and Layer B packet stubs exist with proof.
- Prefer teach coach mode over pretending automation works.

## 8. Markers

| Marker | Meaning |
| --- | --- |
| `KEVIN_REALMS_JOIN_OK` | Proven join |
| `KEVIN_REALMS_COOP_OK` | Etiquette loop observed |
| `KEVIN_REALMS_MOVE_PROBE_OK` | Opt-in look nudge only (not walk/dig) |
| `KEVIN_MC_CRAFT_OK` / `DIG_OK` / `PLACE_OK` / `FARM_OK` / `BUILD_OK` | **Reserved** — set only after live proof receipts |

## 9. Pointers

- In-world actions recipe: `docs/engineering/KEVIN-RECIPE-minecraft-inworld-actions-v1.md`
- Blueprint PLAN: `docs/engineering/PLAN-kevin-minecraft-blueprint-from-image-v1.md`
- Join playbook: `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`
- Coop recipe: `docs/engineering/KEVIN-RECIPE-bedrock-realms-coop-kevinsk8erkid-v1.md`
- NEG: `docs/engineering/evals/NEG-minecraft-survival-fake-build-or-hessmodee-v1.json`
- Scratch skills stubs: `scratch/kevin-minecraft-bedrock-v0/skills/`

## 10. SUPER PLAYER extension

Self-care, animal care, potions, enchanting: `docs/engineering/KEVIN-PLAYBOOK-minecraft-super-player-v1.md` (READY coach; Near stubs; Destination loops). Wiki: `minecraft-self-care.md`, `minecraft-animal-care.md`, `minecraft-potions.md`, `minecraft-enchanting.md`. Never fake brew/enchant; never kill Matt pets.
