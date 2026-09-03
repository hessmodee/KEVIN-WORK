# Kevin Desktop Installation Qualification v1

**Program:** `computer-fluency`  
**Stage:** YELLOW qualification / no production mutation  
**Candidate source:** `extensions/kevin-desktop`  
**Owner intent:** give Kevin bounded ordinary-computer fluency while preserving the existing protected-effect denies.

## Current proven boundary

The Kevin Desktop v0.1 source is merged and CI-proven. It defines three optional native OpenClaw tools:

- `kevin_desktop_find_folder`
- `kevin_desktop_open_folder`
- `kevin_app_launch`

The app launcher is code-owned and limited to Notepad, Calculator, Paint and Explorer. Folder actions are limited to a single direct Desktop child and reject traversal/separators/drive syntax/unsafe targets. The plugin does **not** authorize arbitrary shell, caller-selected executable/path/arguments, unrestricted filesystem search, downloads, installs, generic mouse/keyboard automation, credentials, permission widening, or owner-representing sends.

This source/CI state is **not** proof that HESS-PC has the plugin installed or that `main` can use it.

## Fresh installed-runtime facts to respect

The latest fixed HESS-PC tool-policy diagnosis reports:

- root `tools.profile` = `coding`;
- root protected deny list present;
- `main` has no separate tools block;
- latest main canary observed zero visible tools and no `kevin_system_status`;
- protected global denies include `exec`, `process`, `write`, `edit`, `apply_patch`, `sessions_spawn`, `web_search`, `web_fetch`, and `skill_workshop`.

Any install/exposure candidate must preserve those protected denies. Do not solve a missing optional tool by removing a global deny or enabling a broad group.

## OpenClaw installation semantics researched

Official OpenClaw plugin documentation currently describes these relevant invariants:

1. `openclaw plugins install <local-path>` is the native local plugin install surface; noninteractive untrusted local sources require an explicit reviewed confirmation/force path.
2. Plugin installs are code execution and should be pinned/reproducible.
3. Native plugins require `openclaw.plugin.json` with an inline config schema.
4. Runtime proof should use `openclaw plugins inspect <id> --runtime --json`; cold manifest presence alone is not enough.
5. Optional plugin tools must be explicitly allowlisted before they are sent to the model.
6. `tools.alsoAllow` adds named tools to the active tool profile, while global deny still wins; `allow` and `alsoAllow` cannot coexist in the same scope.
7. A restrictive `plugins.allow` list, when present, must also permit the plugin id.
8. Installing/updating plugin code requires Gateway reload/restart before live runtime proof.

Research references:

- `https://github.com/openclaw/openclaw/blob/main/docs/tools/plugin.md`
- `https://github.com/openclaw/openclaw/blob/main/docs/cli/plugins.md`
- `https://github.com/openclaw/openclaw/blob/main/docs/gateway/config-tools.md`
- `https://github.com/openclaw/openclaw/blob/main/docs/plugins/tool-plugins.md`

The installed HESS-PC OpenClaw version must still be checked before relying on current-main documentation semantics.

## Required exact production crossing

Before any production install, create or prove a typed/reversible crossing with all of these preconditions:

1. **Installed-version proof**
   - exact installed OpenClaw package version;
   - `plugins install`, `plugins inspect --runtime`, config validation and Gateway RPC forms are confirmed on that version;
   - no caller-selected CLI command or argument transport.

2. **Pinned source proof**
   - plugin source/artifact is tied to an immutable reviewed KEVIN-WORK commit or exact digest;
   - runtime dependencies are deterministic and lifecycle scripts remain disabled where package installation is used;
   - staged bytes are independently checked before installation.

3. **Exact-current config proof**
   - record the current config SHA/semantic SHA without publishing config values;
   - prove whether `plugins.allow` exists and whether a per-agent `main.tools` block exists;
   - reject unexpected configuration shape rather than flattening or rewriting it generically.

4. **Narrow exposure mutation**
   - preserve root protected denies byte/semantic-equivalently;
   - enable only plugin id `kevin-desktop` if needed;
   - expose only `kevin_system_status`, `kevin_desktop_find_folder`, `kevin_desktop_open_folder`, and `kevin_app_launch` to `main`;
   - do not allow a group wildcard such as `group:plugins` when exact tool names can be used;
   - no arbitrary shell/runtime/fs/web grant accompanies the change.

5. **Transactional rollback**
   - snapshot exact pre-install config and plugin-index/install state;
   - if install, config validation, Gateway reload, runtime inspect, main canary or Benchmark fails, restore the exact starting state;
   - verify rollback rather than assuming command success.

## Production proof sequence

Do not skip levels:

`CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> RUNTIME-INSPECT-PROVEN -> MAIN-TOOL-SURFACE-PROVEN -> REAL-OWNER-ROUND-TRIP-PROVEN -> REPLAY-PROVEN`

Minimum live tests after a qualified crossing:

1. `plugins inspect kevin-desktop --runtime --json` reports exactly the three intended Kevin Desktop tools.
2. `main` canary shows the intended Kevin tool surface and protected denies remain effective.
3. Positive: resolve one known direct Desktop folder.
4. Negative: traversal/path syntax is rejected.
5. Positive: open one known direct Desktop folder and independently verify Explorer outcome.
6. Negative: ambiguous/not-found target fails closed.
7. Positive: launch one allowlisted app and independently verify the process/window outcome.
8. Negative: prohibited executable/request is rejected before OS launch.
9. Replay a second representative folder/app task.
10. Fresh Benchmark remains `PASS 30/30 critical=0`.

## Kevin learning objective

Kevin is not being trained to memorize a button sequence. He is being trained to own the reusable trajectory:

`owner intent -> inspect exact current state -> select qualified typed primitive -> execute -> verify real postcondition -> recover/rollback -> record evidence -> extract reusable procedure -> replay`

If a missing capability is encountered, Kevin must name the exact missing typed primitive or evidence dependency. He must not improvise an arbitrary shell, generic UI robot or broad filesystem grant.

## Immediate next action

The governed `computer-fluency-desktop-install-qualification` work item should independently refresh the installed-version/plugin/config evidence and either:

- produce the exact typed installation/exposure candidate that satisfies this contract; or
- record the smallest exact blocker/read-only primitive needed to qualify it.

No production Desktop installation should be claimed until HESS-PC reports the installed result and real round-trip evidence.
