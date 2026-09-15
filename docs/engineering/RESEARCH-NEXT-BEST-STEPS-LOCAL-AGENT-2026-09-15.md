# RESEARCH — next best steps for Kevin (2026-09-15)

**Free sources only.** Steal loops, not Mac Studio hardware. Do not install PCClaw / unvetted ClawHub / Hermes into production.

## What successful local agents actually do

OpenClaw / Henry / Hermes succeed because of **time + tools + a written job**, not a bigger chat model.

```
trigger (heartbeat | cron | Tick)
  → context (SOUL / AGENTS / USER / MEMORY)
  → model turn with tools visible
  → tool calls that leave evidence
  → verify
  → idle until next trigger
```

- OpenClaw heartbeat is a periodic **full agent turn**. Empty `HEARTBEAT.md` + `heartbeat.every: 0m` **skips** that turn. Kevin's plant clock is Tick/Supervisor instead — that is valid **if** Tick owns Chat/services and Supervisor can close `KEVIN_ACTED`.
- Henry (Alex Finn): mission board, brain/muscle routing, standing orders, cron. Hardware (Mac Studios + Opus orchestrator) is **not** required and not copyable here.
- Hermes: strong self-skill-writing loop; official comparison says OpenClaw wins channels/tool policy. CURRENT_TASK forbids installing Hermes into production.

Useful X signal: Finn local-models loop (LM Studio/Ollama → wire API → agent uses it); 0xCodio “store blind spots”; Kanika charter/template/trigger/send-rule. Most linked 2026-09 posts were Grok Bot / Astra cloud promo — ignore for Kevin while Grokbot credits are dead.

Citations: https://docs.openclaw.ai/gateway/heartbeat · https://docs.openclaw.ai/automation/standing-orders · https://docs.openclaw.ai/start/why-openclaw/openclaw-and-hermes-agent · https://hermes-agent.nousresearch.com/docs/

## Why Kevin was stuck (correct, not vibes)

1. Chat gateway `:18789` down because Keeper matched Reader `:19001`.
2. Completions labeled MIXED because outside engineers diagnose/close, and the outcomes publisher **hardcoded MIXED**.
3. Supervisor re-selects already-PROVEN OPEN work items; Skill Lab IDLE; OpenClaw cron empty while gateway was down.
4. Live Chat was frozen on `kevin-lab-qwen` with 0 tools even though `fixed:main` has exact-five in config.
5. Over-governance is not the same as autonomy. Docs already said GREEN/YELLOW undying; runtime still asked and still puppeteered.

## Ranked FREE next steps (do in order)

1. Keep Chat `:18789` up via Tick + Keeper (done 2026-09-15; wean on next Tick).
2. Honest actors: receipt `actor` field; publisher no longer hardcodes MIXED (done). `KEVIN_ACTED` only for Tick/Supervisor/Action Era with no `diagnose-*`.
3. Close already-PROVEN OPEN work items so Supervisor can select new GREEN owner work (not re-invoke lot-walk).
4. Unfreeze Chat onto `fixed:main` exact-five (config already has the five tools). Talking to `kevin-lab-qwen` tools:0 is why Matt is not talking to Kevin.
5. One GREEN `KEVIN_ACTED` canary: Tick invokes an already-PROVEN `create_text`/`create_spreadsheet` pack with no outside RequestId.
6. Optional later YELLOW: a dedicated ops agent with bounded coding tools for Kevin-owned file writes. Do not dump `exec` onto Chat. Do not copy Opus-as-required-orchestrator.

## Hardware truth (this box)

Live `system-status.json` 2026-09-15: ~32 GB RAM, RTX 3060 12 GB. Ollama tags: `qwen2.5:14b`, `llama3.1:8b`. This is a proven local-agent box for 8B–14B tool use. It is not a MiniMax/GLM farm. Local Qwen is the brain while Grokbot credits are dead.
