# Kevin Desktop — list_folder typed production crossing contract

**Date:** 2026-09-04
**Authority:** YELLOW qualification / production effect NONE until crossing apply under undying green/yellow auth
**Status:** QUALIFICATION CONTRACT for exact-4 → exact-5 widen (list_folder only)

## Scope

Add exactly one new fixed:main visible tool:

- `kevin_desktop_list_folder`

Prior exact-4 inventory must remain:

1. `kevin_system_status`
2. `kevin_desktop_find_folder`
3. `kevin_desktop_open_folder`
4. `kevin_app_launch`

Final exact-5 inventory (order fixed):

1. `kevin_system_status`
2. `kevin_desktop_find_folder`
3. `kevin_desktop_open_folder`
4. `kevin_desktop_list_folder`
5. `kevin_app_launch`

No `kevin_shell`. No app-allowlist expansion. No other new tools.

## Tool semantics

- Depth-1 listing only.
- Roots allowlist: Desktop (default), Documents, Downloads, Pictures, Music, Videos.
- Optional `name`: safe direct child under that root (same `isSafeDesktopName` rules as find/open).
- Limit default 50, max 100.
- Return basenames + `file`/`dir` kind only — never private host paths.
- Optional secret-deny omits `.env*`, `*credential*`, `*password*`, `*.pem`/`*.key`/`*.pfx`/`*.p12`, `id_rsa*` etc. (count in `redacted`).
- Refuse `..`, `.`, absolute/drive syntax, separators, control chars, invalid root, invalid limit.
- Symlink entries skipped.

## Crossing operation

`install_kevin_desktop_list_folder_v0_2` in `candidates/maintenance/production-crossing-v2`.

Preconditions:

- source_contract = this file
- plugin_id = kevin-desktop
- plugin_version = 0.2.0
- fixed_main_tools_before = exact-4 list above
- requested_tools = exact-5 list above
- benchmark PASS 30/30 critical 0
- rollback_required true

## Protected denies

Existing global denies remain. Crossing must not add shell, PowerShell, cmd, caller-selected executable/path/argv, unrestricted filesystem, recursive search, generic mouse/keyboard, downloads, installs, credentials, permissions or owner-representing sends.

## Live proofs required

1. Stage/build plugin 0.2.0; isolated unit + plugin validate PASS.
2. Backup openclaw.json; mutate only alsoAllow + main.tools.allow to exact-5; preserve denies.
3. Minimal Chat gateway reload; do not kill Reader 19001 / Chat 18789 process identity intent.
4. Positive: list Desktop returns real basenames matching OS sample.
5. Negatives: traversal / absolute / invalid_root fail closed.
6. Prior four tools still invoke.
7. Benchmark PASS 30/30 critical 0.
8. Fresh session Chat: "list what's on my Desktop" emits `kevin_desktop_list_folder` tool_call + real listing (not invent).
9. Rollback dry-restore hash match recorded.

## Authority

Owner undying GREEN+YELLOW auth (2026-09-04) authorizes tools/abilities/upgrades without per-step ask. This widen stays YELLOW typed crossing (not RED). If a RED/Matt-only gate is required beyond yellow, stop with packet READY and do not apply.
