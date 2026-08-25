# Heartbeat

Every tick, do **one** thing:

1. If `inbox/CURRENT_TASK.md` exists, do only that.
2. Else if `reports/tool-write-test.txt` is missing or not `OK-WRITE`, write it with exactly `OK-WRITE`.
3. Else append one line to today's daily note via:
   `python C:\Users\hessm\.openclaw\workspace\helper_append_daily_note.py "heartbeat"`
4. Write `reports/heartbeat-latest.json` with what you actually did and file timestamps.

Rules: local Ollama default. No cloud. No extra_body.tool_choice. No new models. No overnight sprawl. Never overwrite MEMORY.md. Never dump JSON in chat.
