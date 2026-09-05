# PLAN — Kevin Minecraft skill library (Voyager-style) v1

**Updated:** 2026-09-05 ~10:20 MT  
**Status:** PLAN + scaffold (**B Near**). Not a live Voyager clone.  
**Edition:** Bedrock Realms via JOIN_OK / bedrockflayer patterns — **not** MineDojo Java GPT-4.  
**Cost:** Local Qwen/Ollama preferred for any future skill-author LLM; cloud GPT-4 = RED.

## 1. Goal

Build an ever-growing library of **executable, description-indexed, verified** skills for kevinsk8erkid on HESSMODEE's Realm, with an automatic **curriculum ladder** early→mid→late, and **prove-before-promote**.

Inspired by Voyager (MineDojo) skill library + curriculum + iterative self-verify — adapted to Realms constraints.

## 2. Library layout (scaffold)

```
scratch/kevin-minecraft-skill-library-v0/
  README.md
  curriculum/
    CHECKLIST-early-mid-late.md
  skills/
    README.md
    companion/
    combat/
    guard/
    gather/
    craft/
    survival/
  index/
    skills-index.json   # description → path; only promoted entries
  receipts/             # prove artifacts before promote
```

**Rules:**
- Never delete a **promoted** skill (mark deprecated instead).
- Stub ≠ promoted. Promotion requires receipt + index entry.
- Compositional skills may only call promoted children.

## 3. Skill record schema (v0)

```json
{
  "id": "guard.hostile_near_matt.v0",
  "description": "Focus hostile mobs near hessmodee; never attack Matt/pets",
  "layer": "C",
  "status": "stub|dry|live_receipt|promoted",
  "edition": "bedrock-realms",
  "requires": ["join.ok", "entity.query"],
  "forbids": ["pvp.matt", "grief", "hessmodee.login"],
  "verify": ["no_damage_to_hessmodee", "target_was_hostile"],
  "receipt": null
}
```

## 4. Curriculum ladder (Realms co-op)

### Early (A coach + B stubs)

- [ ] Join stay + bed wait
- [ ] Short chat ack Matt intent
- [ ] Follow invite (coach; live C)
- [ ] Offer help / don't AFK
- [ ] Food/hunger awareness (coach)
- [ ] Torch / stick together

### Mid

- [ ] Hostile-only guard near Matt (live C)
- [ ] Kite + retreat low HP
- [ ] Gather when invited (wood/stone/food)
- [ ] Craft coach → later typed craft
- [ ] Animal care (no kill pets)
- [ ] Farm assist when invited

### Late

- [ ] Armor equipAll pattern
- [ ] Enchant/potion coach → later stubs
- [ ] Build assist from agreed plan/image
- [ ] Nether only Matt-led
- [ ] Composed: Follow+Guard+AutoEat
- [ ] Session memory episode consolidation

## 5. Promote pipeline (Voyager iterative loop adapted)

1. **Propose** task from curriculum + Matt intent (local LLM optional).
2. **Retrieve** related promoted skills by description.
3. **Attempt** with env feedback / errors.
4. **Self-verify** against observed world state (fail-closed).
5. **Receipt** on disk.
6. **Promote** into index; never claim before step 5.

## 6. Metrics (steal Voyager spirit, Realms-honest)

Track over sessions (do not invent numbers):
- Unique useful assists Matt confirms
- Successful rejoins / uptime
- Tech/help milestones unlocked **with Matt**
- Zero friendly-fire / grief incidents
- Skills promoted count (with receipts)

## 7. Non-goals

- No GPT-4 cloud curriculum without owner RED auth
- No Fabric/Simulated Player dependency
- No claiming Voyager paper metrics on Realms
- No mutating JOIN_OK package-lock

## 8. Next prove order

1. Matt closes MC UI → rejoin stay  
2. Bridge smoke  
3. Live follow receipt  
4. Live hostile-only receipt  
5. First promoted skill index entry
