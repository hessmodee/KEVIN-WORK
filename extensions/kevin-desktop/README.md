# Kevin Desktop

Bounded local Windows computer-control tools for Kevin.

## v0.3 tools

- `kevin_desktop_find_folder` — resolve one direct Desktop child folder by name without returning the private host path.
- `kevin_desktop_open_folder` — open that exact resolved folder in Windows Explorer.
- `kevin_desktop_list_folder` — depth-1 basename listing of allowlisted known user folders.
- `kevin_app_launch` — launch one fixed allowlisted app: Notepad, Calculator, Paint, or Explorer.
- `kevin_app_close` — close one fixed allowlisted app: Notepad, Calculator, Paint, or Minecraft.
  - Graceful: CloseMainWindow then UIA WindowPattern.Close, then taskkill without /F, then audited Force.
  - `minecraft` requires `KEVIN_ALLOW_CLOSE_MC=1` (Matt authorized 2026-09-05 for Realms stay preflight).
  - Never closes Chat/Reader/node gateways (name + path guards in `scripts/kevin-app-close.ps1`).
  - Explorer is intentionally NOT closable via this tool.

## Safety contract

This plugin intentionally does **not** provide arbitrary shell, PowerShell, `cmd.exe`, arbitrary executable paths, caller-supplied arguments, recursive filesystem search, downloads, installs, generic mouse/keyboard automation, credential access, or permission changes.

Close uses a **code-owned** PowerShell helper with fixed `-ProcessName` mapped from the allowlist key only. The automatic `$PID` bug is fixed (`$procId`).

## Prove receipts (HESS-PC 2026-09-05)

- Parent: Minecraft.Windows closed → `KEVIN_APP_CLOSE_OK` (CloseMainWindow).
- Calculator open→focus→close → `KEVIN_CALC_OPEN_USE_CLOSE_OK` (process CalculatorApp).
- Marker: `KEVIN_APP_CLOSE_MC_OK` when Minecraft already gone or closed by Kevin path.

## Learning / transfer intent

`owner intent -> resolve bounded target -> typed launch/use/close -> verify real outcome -> record evidence -> replay -> promote`

Production promotion requires Omen-side real-turn test and independent postcondition evidence.
