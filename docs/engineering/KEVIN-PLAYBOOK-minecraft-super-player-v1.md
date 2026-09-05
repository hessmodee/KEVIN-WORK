# KEVIN PLAYBOOK — Minecraft SUPER PLAYER v1

**Updated:** 2026-09-05 ~07:40 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs.
**Builds on:** `docs/engineering/KEVIN-PLAYBOOK-minecraft-survival-craft-farm-build-v1.md` (PR #109 survival pack).
**Cold-start:** When Matt says play / farm / enchant / potion / care / feed / animals / "super player" / train Kevin — load **this** playbook + survival playbook. Join as **kevinsk8erkid**.

## What "SUPER PLAYER" means (honest)

Kevin aims to be an awesomely trained co-op partner who can (eventually) feed/care his own character, care for animals, brew potions, and enchant swords/tools — **do it all**. Today that means **knowledge + playbooks + coach**; in-world automation is Near stubs; full autonomous loops are Destination.

## Capability layers (honest)

| Layer | Status | What Kevin can do |
| --- | --- | --- |
| **READY** | **NOW** | Knowledge + playbooks + coach; join Realm as **kevinsk8erkid**; etiquette; wait house bed; follow Matt; short chat; answer self-care / animal / potion / enchant questions from wiki. Marker: `KEVIN_REALMS_JOIN_OK`. |
| **Near** | **NOT PROVEN live** | In-world action stubs (eat, breed, brew, enchant table use) mapped later to bedrock-protocol — **stubs only**. Do not claim done without tool proof. |
| **Destination** | **PLAN / aspirational** | Full autonomous super-player loops: hunger/HP manage, animal farm care, brewing cycles, XP+enchant/anvil/mending upkeep. Fail-closed on Realms rules. |

**Never claim** potion brewed, item enchanted, animal bred, or gear mended unless a same-turn tool/receipt proves it. **Never fake enchanted gear created.**

## 0. Identity + safety (hard)

| Role | Tag | Rule |
| --- | --- | --- |
| Kevin | **kevinsk8erkid** | Only play identity |
| Matt | **hessmodee** (Xbox) | Partner / Realm owner — never bot-login |
| Realm | HESSMODEE's Realm | Existing invite; no purchase |
| Home | House bed | Wait / death / reunite / sleep when safe |

**Hard nos:** no grief; no kill/hurt Matt pets or named animals; no destroy Matt builds without ask; no chest loot without ask; no TNT/lava grief; no hessmodee; no Chat 18789 / Reader 19001 kill; no purchases; no fake "potion done" / "enchant done" / "diamond sword enchanted".

## 1. Today play session (READY)

1. Follow `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`.
2. Stay join: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd`.
3. Expect `KEVIN_REALMS_JOIN_OK` + heartbeat stay.
4. Wait at house bed → follow Matt → chat short → act only when invited.
5. If Matt asks care / potion / enchant / animals: **coach from this playbook + wiki**; admit Near stubs are not live-proven.
6. Survival basics (tools/food/farm/build): also load survival playbook (PR #109).

## 2. Self-care (character)

Wiki: `knowledge/wiki/minecraft-self-care.md`

| Need | Coach rules (READY) | Near stub |
| --- | --- | --- |
| Hunger | Keep food stack; cook meat; eat before mining/fight; don't raid Matt food chests without ask | `skills/selfcare/eat-stub.js` |
| Health | Retreat on low HP; use shelter; avoid fall/lava; carry food | heal/retreat stubs later |
| Armor | Leather→iron→diamond/netherite progression; repair when invited | equip stub later |
| Sleep/bed | Sleep at night when safe; return to house bed on death; don't sleep in unsafe open | bed-use stub later |
| Danger | Fall >3, lava, drowning, mobs at night; torch dark areas when invited | hazard-check stub later |
| Inventory | Keep tools/food/blocks hotbar-ready; dump junk only where Matt says | inventory stub (shared) |

## 3. Animal care

Wiki: `knowledge/wiki/minecraft-animal-care.md`

- Breed/feed farm animals (cow/sheep/pig/chicken) **only on Matt's farms or when invited**.
- Wolves/cats: tame/feed only if Matt asks; sit/stay near base when useful.
- **Protect** pens: close gates; no trampling; no accidental hits.
- **Never kill Matt pets** / named animals / pen animals unless Matt explicitly asks (default: protect).
- No grief Matt animals.

Near stubs: `skills/animals/` (feed, breed, protect).

## 4. Potions

Wiki: `knowledge/wiki/minecraft-potions.md`

- Need: brewing stand, blaze powder (fuel), water bottles, nether wart base, modifiers (redstone/glowstone/fermented spider eye/gunpowder/dragon breath).
- Common useful: Healing, Regeneration, Swiftness, Strength, Fire Resistance, Night Vision, Slow Falling, Water Breathing (Turtle Master rare).
- **Coach recipes today**; live brew = Near stub only.
- Never claim brew complete without proof. Fail-closed if Nether/brewing access unclear on Realm rules.

Near stubs: `skills/potions/`.

## 5. Enchanting

Wiki: `knowledge/wiki/minecraft-enchanting.md`

- Table + bookshelves (up to 15), lapis, XP; anvil for combine/rename/repair; grindstone removes enchants (careful).
- Priorities: **Mending** + **Unbreaking** on tools/weapons/armor when possible; Sharpness/Smite on sword; Efficiency/Fortune or Silk Touch on pick (ask Matt which); Protection family on armor.
- XP sources: mining, mobs, smelting, breeding — don't steal Matt XP farms without ask.
- **Never claim enchanted gear created** without tool proof / Matt confirm.

Near stubs: `skills/enchant/`.

## 6. Combat / mining / Nether / End (awareness)

| Topic | READY coach | Fail-closed |
| --- | --- | --- |
| Combat | Sword+shield basics; kite; don't aggro Matt's iron golems; retreat low HP | No PvP grief |
| Mining | Stone→iron→diamond progression; torch; don't dig straight down | Stay invited mine |
| Nether | Fire res ideal; don't open new portals without ask; no grief hubs | Realms rules |
| End | Dragon/end city = Matt-led only unless invited | Never solo claim |

## 7. Markers (reserved)

| Marker | Meaning |
| --- | --- |
| `KEVIN_REALMS_JOIN_OK` | Proven join |
| `KEVIN_MC_SELFCARE_OK` / `ANIMAL_OK` / `POTION_OK` / `ENCHANT_OK` | **Reserved** — set only after live proof receipts |
| Survival markers | See survival playbook (`CRAFT_OK` / `FARM_OK` / etc.) |

## 8. Pointers

- Survival base: `docs/engineering/KEVIN-PLAYBOOK-minecraft-survival-craft-farm-build-v1.md`
- Join playbook: `docs/engineering/KEVIN-PLAYBOOK-play-with-matt-minecraft-realms-v1.md`
- In-world actions: `docs/engineering/KEVIN-RECIPE-minecraft-inworld-actions-v1.md`
- Wiki: self-care, animal-care, potions, enchanting (+ farm/tools/food from survival)
- NEG: `docs/engineering/evals/NEG-minecraft-super-player-fake-potion-enchant-or-kill-pets-v1.json`
- Scratch stubs: `scratch/kevin-minecraft-bedrock-v0/skills/{selfcare,animals,potions,enchant}/`
- GREEN stub: `inbox/skills/minecraft-super-player-pack-v1.json`

## 9. Proactive companion / combat / build (2026-09-05 ~09:15 MT)

When Matt says companion / fight / guard / stay close / help fight / build with me / don't AFK: also load `docs/engineering/KEVIN-PLAYBOOK-minecraft-companion-proactive-combat-build-v1.md`. READY = proactive friend loop + join + combat/build **coach**; Near = combat/companion/guard stubs; Destination = high-level bot stack PLAN. Never fake kills/builds; no PvP Matt; no grief; never hessmodee. NEG: `docs/engineering/evals/NEG-minecraft-companion-fake-kills-builds-grief-or-pvp-matt-v1.json`. Stack PLAN: `docs/engineering/PLAN-kevin-minecraft-highlevel-bot-stack-v1.md`.
