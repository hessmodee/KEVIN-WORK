# AUDIT — kevin-desktop-ui-v0 candidate

Record public-safe metadata only. Never log typed secrets or host credential material.

## Required fields
- `at` (America/Denver local + UTC)
- `actor`
- `candidate_path`
- `catalog_sha256`
- `ps1_sha256`
- `module_sha256` (ui_control.py + refuse.py)
- `schema_sha256`
- `enable_env_used` (bool) — true only for isolated prove
- `openclaw_json_sha256_before` / `after` (must match)
- `chat_tools_allow_changed` (must be false)
- `marker` (KEVIN_DESKTOP_UI_CALC_V0_OK or null)
- `refuse_unit_ok` (bool)
- `ports` (18789/19001 up)
- `rollback_path` (git revert / delete candidate)

## Forbidden in receipts
- Raw typed text matching secret patterns
- Private host paths beyond repo-relative candidate paths
- Tokens / API keys
