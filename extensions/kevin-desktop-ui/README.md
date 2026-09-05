# kevin-desktop-ui - Phase 2 disabled-by-default extension

Authority: GREEN candidate package only.
Port of candidates/desktop/kevin-desktop-ui-v0 into TypeScript extension with vitest.

## Status

PHASE2_DISABLED_EXT_VITEST - refuse gates under vitest.
Not for live Chat until Phase 3. Live kevin-desktop stays frozen.

## Enable

Default OFF. Set KEVIN_DESKTOP_UI_ENABLE=1 for isolated candidate only.
Even when enabled, returns candidate_no_live_uia.

## Tools

- kevin_ui_focus_app
- kevin_ui_click
- kevin_ui_type

App allowlist: calculator only.

## Test
Run package test script; expect marker PHASE2_EXT_VITEST_OK

## Hard no
- No live config apply
- No Chat widen
- No CUA
- Do not modify live kevin-desktop
Marker line: KEVIN_DESKTOP_UI_PHASE2_EXT_VITEST_OK
