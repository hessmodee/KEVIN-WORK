# Kevin helper/tool notes

These workspace helpers are executable files, not assumed OpenClaw tool IDs. Use only helpers/capabilities that actually exist, are permitted for the current task, and have an appropriate proof/authority level.

Known helper examples in the workspace include:

- `python helper_append_daily_note.py "note"`
- `python helper_weather_83263.py`
- `python helper_morning_brief.py`
- `python helper_self_check.py`
- `python helper_context_83263.py`
- `python helper_system_status.py`
- `python helper_board.py`
- `python helper_reader_status.py`
- `python helper_sanitize_check.py`
- `python helper_web_fetch.py <approved-url>` only inside its proven/allowed network and data boundary.

Do not invent tool names or assume a helper is authorized for a new effect simply because the file exists.

## Native primitive selection

When installed/proven and compatible with Kevin's boundaries, use the smallest native primitive that matches the job:

- **Standing Orders:** persistent ownership/intent and escalation rules.
- **Automations:** precise or recurring timing/event wakeups.
- **Heartbeat:** ambient awareness only; never a hidden work queue.
- **Background Tasks:** detached-work activity ledger, not scheduler/state machine.
- **Task Flow:** revisioned durable multi-step workflow state, waiting/resume/cancel and child task linkage.
- **Lobster/constrained workflows:** deterministic multi-tool pipelines with bounded grammar and approval/resume checkpoints.
- **Skill Workshop/self-learning:** governed procedural/recovery learning from substantial real work.
- **Kevin Skill Lab:** executable composites using only already-PROVEN GREEN primitives.
- **Workspace memory:** always-loaded durable operational memory.

Do not add another custom scheduler, polling loop, worker or sub-agent if a proven native primitive already solves the same need more simply.

## Reasoning vs deterministic enforcement

Use the local model for ambiguity, intent understanding, synthesis, prioritization and hypothesis generation.

Use deterministic code/contracts for:
- authority and effect classification;
- schemas/types;
- exact target/path/recipient allowlists;
- freshness and evidence identity;
- revision/state transitions;
- retry/failure budgets and cooldowns;
- idempotency/replay;
- hashes/trust anchors;
- WIP/resource limits;
- semantic postcondition checks where deterministic checks are possible;
- rollback and recovery;
- production promotion gates.

## Failure behavior

When a tool/helper/workflow fails:
1. preserve the failure evidence and the original objective;
2. classify the failure family and check freshness/preconditions;
3. ask whether the evaluator/validator itself could be stale before modifying the system to satisfy it;
4. retry only when the next attempt is materially different or a transient retry is explicitly part of the proven contract;
5. never exceed the applicable bounded attempt budget (default three materially distinct attempts per family);
6. verify semantic success after recovery with the applicable domain/global regression evidence;
7. if still blocked, cool that family and advance another independent useful authorized objective;
8. turn reusable failures/corrections into a targeted eval, validator, recovery procedure, typed self-heal, or governed skill proposal.

Do not stop all useful work because one tool failed. Do not disguise the same failed attempt with a new request ID.

## Tool proof / capability truth

A tool is not "working" merely because its executable exists or a task is registered. Distinguish:

`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

For repair/control capabilities separately track whether Kevin himself can notice/select/verify the action without Bess.

## Learning from tool trajectories

After substantial real work, preserve enough trace/evidence to determine whether a stable procedure should become a skill/eval. Prefer learning when it would remove at least two future model/tool steps, reduce recurring error, improve recovery, or materially accelerate a repeated owner workflow.

Do not promote arbitrary model-generated commands into tools. New primitive authority requires its own typed design, deterministic/adversarial evaluation and owner-approved production boundary.

## Resource discipline

Default to one primary local reasoning worker. Parallel agents/workers require a measured reason. Favor deterministic pipelines for repeated low-ambiguity work so the 14B model spends context and compute on decisions that actually require reasoning.

Prefer native OpenClaw durable primitives and constrained typed computer-effect boundaries over unrestricted execution surfaces.
