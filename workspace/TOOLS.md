# Helpers (exec these; they are not OpenClaw tool ids)

python helper_append_daily_note.py "note"
python helper_weather_83263.py
python helper_morning_brief.py
python helper_self_check.py
python helper_context_83263.py
python helper_system_status.py
python helper_web_fetch.py https://example.com
python helper_board.py

If a tool fails: say FAIL, write one line to the daily note, stop. Do not retry. Do not invent tools.
There is no tool named heartbeat.
