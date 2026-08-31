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

## Failure behavior

When a tool/helper/workflow fails:
1. preserve the failure evidence;
2. classify the failure family and check freshness/preconditions;
3. retry only when the next attempt is materially different or a transient retry is explicitly part of the proven contract;
4. never exceed the applicable bounded attempt budget (default three materially distinct attempts per family);
5. verify semantic success after recovery;
6. if still blocked, cool that family and advance another independent useful authorized objective;
7. turn reusable failures/corrections into a targeted eval, validator, recovery procedure or governed skill proposal.

Do not stop all useful work because one tool failed. Do not disguise the same failed attempt with a new request ID.

Prefer native OpenClaw durable primitives (Standing Orders, Automations, Task Flow, constrained workflows, native memory and governed skill learning) when they are available, proven and simpler than bespoke orchestration. Preserve our typed computer-effect boundaries and owner authority rules.
