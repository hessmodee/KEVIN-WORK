---
name: disk-proof
description: Verify Kevin work on disk with Get-Content timestamps, never chat claims.
---

After any write or exec, the file must exist and the timestamp must be now.
If the user says you did it and the file is missing, you did not do it. Run the helper again via exec.
Helpers: helper_append_daily_note.py, helper_weather_83263.py, helper_morning_brief.py, helper_self_check.py.
