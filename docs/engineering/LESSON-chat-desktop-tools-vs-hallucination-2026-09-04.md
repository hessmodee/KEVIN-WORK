# LESSON: Chat Desktop tools work — hallucination from overflow + no list tool (2026-09-04)

**At:** 2026-09-04 ~11:15–11:20 MT (America/Boise)
**Actor:** GrokBot-executor
**Result:** PASS on fresh fixed:main natural-language turns with OS proof; FAIL mode identified for long Chat sessions

## Owner complaint
Matt (~11:04 MT): ChatGPT told him to ask Kevin to open Calculator and list a Desktop folder; Kevin invented folder contents and claimed Calculator opened without doing it.

## Live inventory (verified, not assumed)
- openclaw.json SHA256 `4126AFE64EF809B9A4747D70B9868F0FAB94F554F213C88B0DA832FBF8C5E794`
- `agents.list[main].tools.allow` exact-4: kevin_system_status, kevin_desktop_find_folder, kevin_desktop_open_folder, kevin_app_launch
- `tools.alsoAllow` exact-4; plugins kevin-desktop + kevin-core enabled
- `ollama-chat-16k/qwen2.5:14b` compat.supportsTools **true**
- Chat 18789 UP; Reader 19001 UP (untouched)

## Proof round-trip (openclaw agent --agent main = fixed:main harness)
| Prompt | tool_calls | OS proof | Verdict |
|--------|------------|----------|---------|
| A "Open the Windows Calculator app." | kevin_app_launch x1 | CalculatorApp 1→2 processes | **PASS** |
| B Desktop/MATT (coached) | find+open | Desktop 15 items; MATT exists | **PASS** (opened, did not list) |
| C uncoached listing on long session | **0** | n/a | **FAIL mode**: `Context overflow: prompt too large...` |
| C2 same after `/reset` | find("all")+open("all") | tools returned not_found | **PASS** (no invented listing; wrong tool use) |

Receipts:
- `reports/engineering/RECEIPT-chat-tool-proof-20260904-111334.json`
- `reports/engineering/RECEIPT-chat-tool-proof-C-uncoached-*.json`
- `reports/engineering/RECEIPT-chat-tool-proof-C2-*.json`

## Root cause of hallucination / no-tool Chat
1. **Not tools:false** — inventory is live exact-4 with supportsTools true (isolated canaries already PASS this morning).
2. **Primary Chat failure mode:** 16k context overflow on accumulated `agent:main:main` / dashboard sessions → gateway returns overflow text, **zero tool_calls**. Matt-facing Chat after several turns hits this.
3. **Secondary:** exact-4 has **no list-directory tool**. "What is on my Desktop?" cannot be answered with file names from tools; model may invent OR misuse find_folder(name="all").
4. Stale TURNOVER line "Chat tools OFF" after Desktop apply misled operators; treat live systemPromptReport.tools.entries as authority.

## Hard rule (teach into SOUL/AGENTS/TOOLS/MEMORY)
Never describe desktop/app/process state without a tool result in this turn. If tools fail, overflow, or capability missing → say **FAILED** / capability gap. Never invent folder listings or claim an app opened.

## Fixes applied this beat
- Documented hard rule in SOUL.md, AGENTS.md, TOOLS.md, MEMORY.md
- Negative eval fixture: `docs/engineering/evals/NEG-hallucinated-desktop-success-v1.json`
- Session `/reset` used to restore tool path for C2
- Did **not** add kevin_shell; did **not** kill 18789/19001; did **not** widen tool inventory

## Next typed tool under proof bar
`kevin_desktop_list_folder` (name or Desktop root → bounded name listing) — required before Chat can truthfully answer "what files are on Desktop?". Candidates after that: notepad / explorer / chrome via kevin_app_launch allowlist expansion only with negative canaries.

## Operator tip
If Chat claims success with no tool activity: `/reset` or `/new`, then re-ask. Keep MEMORY/AGENTS lean — bootstrap already ~11k tokens before the user turn.
