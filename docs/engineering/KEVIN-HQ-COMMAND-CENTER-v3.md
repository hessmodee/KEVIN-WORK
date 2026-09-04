# Kevin HQ Command Center v3

Status: OWNER-DIRECTED UI REFINEMENT

## Purpose

Kevin HQ is an owner-facing command center and observability surface. It is **not** the runtime, not the handover, not the raw engineering database, and not a place to display every internal subsystem merely because telemetry exists.

The primary question for Matt should be answerable in seconds:

1. What is Kevin doing right now?
2. Is useful owner work available or blocked?
3. What actually needs attention?
4. What useful capabilities is Kevin learning/proving?
5. Is the platform healthy enough to trust the answers?

The dashboard must not manufacture motion, accomplishment, work, percentages or urgency.

## Research basis

The refinement follows patterns visible in mature agent platforms rather than copying any one product's visual style.

- OpenAI Agents SDK keeps the agent model centered on a small set of primitives (agents, handoffs/agents-as-tools, guardrails, sessions/HITL and tracing), while tracing captures actual runs, tool calls, handoffs and guardrails for debugging/monitoring. This argues for a small number of owner concepts with drill-down evidence instead of one tab per internal object.
  - https://openai.github.io/openai-agents-python/
  - https://openai.github.io/openai-agents-python/tracing/
- LangSmith separates Projects, Traces, Runs and Threads and uses dashboards for high-level health/usage before drilling into individual execution detail. This supports progressive disclosure: summary first, evidence second.
  - https://docs.langchain.com/langsmith/observability-concepts
  - https://docs.langchain.com/langsmith/dashboards
- Microsoft agent/workflow tooling increasingly separates building, activity and monitoring and provides dedicated health/error views. Multi-agent guidance emphasizes clear specialist responsibilities rather than overloading one parent agent.
  - https://learn.microsoft.com/en-us/microsoft-copilot-studio/flows-overview
  - https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents
- CrewAI's control-plane concepts likewise emphasize agents with defined roles, tasks/processes, persistent flow state, and execution traces/monitoring rather than a dashboard full of disconnected implementation trivia.
  - https://docs.crewai.com/

## Information architecture

### Primary views

1. **Command** — owner-level truth: working/eligible/blocked/idle, queue counts, benchmark, high-signal attention, current engineering priorities, current owner-value skill wave, latest verified proof.
2. **Ops Floor** — preserved animated worker/agent view. This remains the fun visual representation of who is doing work, without becoming the source of truth for whether work happened.
3. **Work Log** — existing activity/evidence history, renamed from Activity so its purpose is obvious.
4. **Skills** — owner-relevant competency ledger and current skill wave. Replaces the old generic Capabilities framing.
5. **System** — platform health, services, load and evidence freshness. Deep truth/diagnostics are available here on demand.

### Removed from primary navigation

- **Talk · Exp** — removed as a tab. The proven local private chat remains available as the persistent `Talk to Kevin` quick action.
- **Roadmap** — removed as a standalone tab. The old roadmap was implementation-heavy and could become stale relative to `CURRENT_TASK.md`. Command now takes live priorities from the current owner task.
- **Diagnostics** — removed as a standalone tab. Engineering diagnostics are preserved behind `System -> Show deep truth & diagnostics`.

## Command-page rules

The Command page intentionally does **not** show:

- 24-hour CPU/RAM/GPU chart;
- Kevin evolution percentage or decorative roadmap percentage;
- Build Lab promotion status as a top-level owner metric;
- raw service rails;
- the full AI handover block;
- the global multi-source truth console;
- repetitive low-value heartbeat/cron detail.

Those details remain available where they belong. The front page is reserved for current owner value and truthful operating state.

## Truth contract

Command distinguishes:

- `WORKING` — active runtime task or active worker evidence exists.
- `ELIGIBLE WORK` — governed non-blocked owner work is present.
- `BLOCKED WORK` — useful governed work exists but prerequisites/tools/proof are missing.
- `TRUE IDLE` — the selector reports no eligible demand and there is no open governed work surfaced by the current backlog.
- `READY` — no active execution is proven and the stronger states above are not supported.

HQ must never display `WORKING` merely because a scheduler is armed or a model turn occurred.

## Current-owner alignment

`inbox/CURRENT_TASK.md` is fetched by Command Center v3 and is used to populate:

- `P0 — current live platform repair targets`
- `P0 — tonight's owner-value skill wave`

That makes current West Motor/iRecon work, vehicle diagnostics, Cache Valley Appliance Repair, crypto research/paper trading, creator monetization and home/garage organization visible while construction stays preserved as legacy context rather than a default owner objective.

## Preserved functionality

- Ops Floor visuals, worker animation and truth patches are unchanged.
- Newswire remains active.
- Canonical AI Handover remains one click away.
- Native local `Talk to Kevin` remains one click away.
- Existing Work Log/activity history remains intact.
- Deep truth console remains intact but is hidden by default and exposed from System.
- Service worker/offline resilience remains, with v3 added to the app shell.
- Existing stale-evidence and Ops Floor invariant tests remain in the gate.

## Acceptance criteria

- Five primary navigation items only: Command, Ops Floor, Work Log, Skills, System.
- No loss of Ops Floor functionality or worker truth behavior.
- No loss of Talk/Handover access.
- No loss of deep diagnostics; they become deliberate drill-down.
- Command uses current owner task instead of the old standalone roadmap for P0 priorities.
- `BLOCKED WORK` is visibly different from `TRUE IDLE`.
- Benchmark/health problems remain visible without flooding the owner with implementation detail.
- Main-page content prioritizes owner outcomes and useful next actions.
- JavaScript syntax, shell invariants, stale-evidence protections and existing Ops Floor tests pass before merge.
