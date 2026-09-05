# ROLLBACK — kevin-desktop-ui-v0 candidate

## Current state (Phase 2)
No live `openclaw.json` mutation. No Chat tools.allow mutation. Rollback = repository revert.

## Rollback steps
1. `git revert` the PR commit(s) that added `candidates/desktop/kevin-desktop-ui-v0` + contract docs, **or** delete that directory on a follow-up PR.
2. Confirm no `kevin-desktop-ui` / `kevin_ui_*` entries exist in live `openclaw.json`.
3. Confirm Chat `tools.allow` / `alsoAllow` unchanged (exact Desktop inventory only).
4. Confirm ports 18789 / 19001 still UP; Benchmark still PASS when next scheduled.

## If a future Phase 3 crossing applied (NOT done yet)
1. Restore exact-byte backup of `openclaw.json` from the crossing receipt backup dir.
2. Remove any `kevin-desktop-ui` plugin registration.
3. Strip `kevin_ui_*` from Chat allow lists (exact-N restore).
4. Minimal gateway reload per typed crossing contract; do not kill Reader.
5. Fresh canary + Benchmark 30/30 critical 0.
