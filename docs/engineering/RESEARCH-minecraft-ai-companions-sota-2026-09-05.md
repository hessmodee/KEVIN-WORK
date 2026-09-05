# RESEARCH — Minecraft AI companions SOTA (2026-09-05)

**Updated:** 2026-09-05 ~10:20 MT  
**Authority:** UNDYING GREEN+YELLOW research/teach (no paid GPT Voyager spend).  
**Audience:** Kevin + Matt + coaches building elite Bedrock Realms co-player **kevinsk8erkid**.  
**Honesty layers:** **A READY** = join/coach/persona proven today; **B Near** = scaffolds/stubs/IMPORT_OK; **C Destination** = live follow/combat/skill-loop receipts not yet claimed.

## 0. Absolute constraints (encode first)

| Constraint | Truth |
| --- | --- |
| Edition | **Bedrock Realms** (HESSMODEE's) — NOT Java Mineflayer LAN as production path |
| Join | NetherNet **JOIN_OK** (protocol **2169**) + `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` / rejoin-companion bridge |
| Identity | Play as **kevinsk8erkid** only; never bot-login **hessmodee** |
| Etiquette | No PvP Matt; no grief; no force Realms addons; no Chat/Reader kills; never mutate JOIN_OK `package-lock` |
| Brain cost | Voyager-style cloud GPT-4 loops = **RED/purchasing** — prefer local Qwen/Ollama when adding LLM loop; cloud is gated destination |
| Live status | Coach + join + IMPORT_OK + bridge smoke **READY**; live FOLLOW/COMBAT **not receipt-proven** |

Java Mineflayer / Fabric / Simulated Player addons may inspire *patterns* only. Do not invent Fabric-on-Realms.

## 1. Survey of winning systems (cite + steal)

### 1.1 Voyager (MineDojo) — skill library + curriculum

**Cite:** Wang et al., *Voyager: An Open-Ended Embodied Agent with Large Language Models* (MineDojo; GPT-4 blackbox); https://github.com/MineDojo/Voyager ; paper PDF via voyager.minedojo.org.

**What worked:**
1. **Automatic curriculum** — LLM proposes next milestone from env snapshot + completed/failed tasks (exploration-maximizing).
2. **Ever-growing skill library** — successful executable programs stored with descriptions; vector retrieval by task/env; compositional reuse.
3. **Iterative prompting** — env feedback + execution errors + **self-verify** before promote.
4. **Metrics** — unique items, distance traveled, tech-tree unlocks (reported gains vs prior SOTA in paper).

**Honesty:** Original Voyager is **Java + Mineflayer + GPT-4**. We steal the *architecture*, not the stack or the spend.

**Steal for Kevin (map):**
| Voyager | Kevin |
| --- | --- |
| skill library of verified JS | durable `skills/` + MEMORY; never delete proven skills |
| auto curriculum | curriculum ladder early→mid→late Realms co-op |
| iterative prompt + self-verify | prove-before-promote; receipts before OK markers |
| compositional skills | compose follow+guard+gather only after each is receipted |

### 1.2 Mindcraft (+ MineCollab)

**Cite:** mindcraft-bots/mindcraft; White/Nottingham et al., *Collaborating Action by Action…* arXiv:2504.17950 (MINDcraft + MineCollab).

**What worked:**
- LLM + Mineflayer; **bot profiles** (prompts/examples JSON); name must match gamertag.
- Conversational companion; parameterized high-level tools (`!collectBlocks`, `!givePlayer`, …).
- MineCollab: multi-agent collab bottlenecks = natural language coordination.

**Steal for Kevin:** profile **kevinsk8erkid**; companion persona in SOUL; chat-driven goals; typed tool registry (not free-form invent); collab patterns = short chat + acknowledge Matt intent.

### 1.3 Altera Project Sid / PIANO

**Cite:** Altera, *Project Sid: Many-agent simulations toward AI civilization* arXiv:2411.00114; PIANO = Parallel Information Aggregation via Neural Orchestration.

**What worked:**
- Parallel output streams (chat + act) stay coherent via cognitive controller.
- Social roles; Theory of Mind for co-op; avoid incoherent action loops.

**Steal for Kevin:** interruptible loops; don't freeze chat while pathfinding; acknowledge Matt intent; social role = loyal co-player (not civilization sim).

### 1.4 Seeker-Craft / MineBot / AIBot family (patterns)

**What worked (community/research lore):**
- Typed tool registry; deterministic task state machines.
- Success only from **observed world state** (fail-closed).
- Tiered tasks + recovery modes.

**Steal for Kevin:** typed in-world tools; fail-closed; receipts; recovery tiers (retry → different approach → cool).

### 1.5 MC-CIV / ClawCraft (patterns)

**What worked:**
- Brain–body split; ReAct loops; instincts interrupt (hunger/danger).
- Memory consolidation; loyalty/personality.

**Steal for Kevin:** survival instincts > optional build; memory episodes of Realm sessions; loyalty to Matt.

### 1.6 Prismarine / bedrockflayer body patterns

**Cite:** mineflayer ecosystem (pathfinder, mineflayer-pvp, armor-manager, auto-eat, collect-block, guard, mineflayer-statemachine); adapt via **bedrockflayer** / stack spike — Java APIs are pattern refs only.

**Steal for Kevin:**
- Pathfinder goals; PVE combat plugins; `equipAll`; auto-eat; collect-block; guard.
- State machine: Follow ↔ Look ↔ Guard ↔ Retreat ↔ Idle (+ mother/follow).
- Current truth: **IMPORT_OK** + bridge inject smoke; live GoalFollow/combat **NOT_PROVEN**.

### 1.7 PvP-bot combat lore (PVE adaptation)

**Steal:** strafe; crit timing; retreat low HP; kite; prioritize hostiles near Matt; **never friendly fire** (hessmodee / pets / golems / villagers).

## 2. What we do NOT steal / claim

| Temptation | Verdict |
| --- | --- |
| "Kevin is Voyager SOTA on Realms" | **FORBIDDEN** — different edition, no GPT-4 curriculum proven |
| Paid GPT-4 Voyager cloud loop | **RED** until owner auth |
| Fabric / Understudy / Simulated Players as required path | Prefer protocol bot; no force addons |
| Live FOLLOW_OK / COMBAT_OK | Not claimed without receipts |
| Java Mineflayer LAN = Realms production | LESSON: mineflayer-java-not-bedrock-realms-fork |

## 3. Honesty matrix (A/B/C)

| Capability | Layer | Status 2026-09-05 |
| --- | --- | --- |
| Join Realms as kevinsk8erkid | **A READY** | JOIN_OK NetherNet 2169 + rejoin.cmd |
| Etiquette / no grief / no PvP Matt | **A READY** | Standing orders + NEGs |
| Companion persona / proactive coach | **A READY** | Playbooks + SOUL/AGENTS |
| Bridge inject / IMPORT_OK | **B Near** | Stack spike smoke |
| Skill library scaffold + curriculum plan | **B Near** | This research + PLAN |
| Live follow / combat / dig / craft | **C Destination** | Not receipt-proven |
| Local LLM skill-authoring loop | **C Destination** | Prefer Ollama/Qwen; gated |
| Cloud GPT-4 Voyager clone | **C + RED** | Needs purchasing auth |

## 4. Top techniques Kevin should run now (behavioral)

Even before live autopilot receipts, Kevin **runs** these as standing behavior:

1. **Prove-before-promote** — never emit FOLLOW_OK/COMBAT_OK/fake kills without world-state receipt.
2. **Proactive interruptible companion** — offer help; stay near when invited; never AFK-idle unless asked; chat stays alive during long actions (PIANO).
3. **Hostile-only + no friendly fire** — prioritize threats near Matt; never swing hessmodee/pets.
4. **Durable skill library discipline** — keep proven skills; index by description; compose only after verify (Voyager).
5. **Fail-closed Realms path** — JOIN_OK + rejoin; BLOCKED_MC_UI → wait for Matt close UWP; never kill Chat/Reader; never mutate JOIN_OK lockfile.

## 5. Related Kevin docs

- Elite playbook: `docs/engineering/KEVIN-PLAYBOOK-elite-minecraft-coplayer-v1.md`
- Skill library PLAN: `docs/engineering/PLAN-kevin-minecraft-skill-library-voyager-style-v1.md`
- Troubleshooting: `docs/engineering/RUNBOOK-minecraft-realms-companion-troubleshooting-v1.md`
- Companion combat playbook: `docs/engineering/KEVIN-PLAYBOOK-minecraft-companion-proactive-combat-build-v1.md`
- Stack PLAN: `docs/engineering/PLAN-kevin-minecraft-highlevel-bot-stack-v1.md`
- Wiki lessons: `knowledge/wiki/minecraft-ai-companion-lessons.md`
- NEG SOTA honesty: `docs/engineering/evals/NEG-minecraft-sota-fake-claims-voyager-spend-fabric-realms-v1.json`

## 6. Recommended next prove (after Matt closes MC UI)

1. Preflight CLEAR → `rejoin.cmd` stay as kevinsk8erkid.
2. Optional: `scratch/kevin-minecraft-stack-spike-v0/smoke-bridge.cmd`.
3. Live inject GoalFollow `hessmodee` → receipt before any FOLLOW_OK claim.
4. Hostile-only guard near Matt → receipt before COMBAT_OK.
5. Only then promote skills into library under prove-before-promote.

---
*Research synthesis for teach-and-transfer. Patterns from cited systems; Realms constraints override Java/Fabric fantasies.*
