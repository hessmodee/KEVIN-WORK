# Kevin Desktop

Bounded local Windows computer-control tools for Kevin.

## v0.1 tools

- `kevin_desktop_find_folder` — resolve one direct Desktop child folder by name without returning the private host path.
- `kevin_desktop_open_folder` — open that exact resolved folder in Windows Explorer.
- `kevin_app_launch` — launch one fixed allowlisted app: Notepad, Calculator, Paint, or Explorer.

## Safety contract

This plugin intentionally does **not** provide arbitrary shell, PowerShell, `cmd.exe`, arbitrary executable paths, caller-supplied arguments, recursive filesystem search, downloads, installs, generic mouse/keyboard automation, credential access, or permission changes.

Folder names are direct-child names only. Separators, traversal, drive syntax, control characters, and Windows-forbidden filename characters are rejected. Symlink targets are rejected. Application launch uses `child_process.spawn` with `shell: false` and a code-owned executable allowlist.

## Learning / transfer intent

The plugin is a primitive, not the finished autonomy outcome. Kevin should learn a reusable trajectory:

`owner intent -> resolve bounded target -> typed action -> verify real visible outcome -> record evidence -> replay -> promote procedure`

A successful model response is not proof that Explorer or an app actually opened. Production promotion requires an Omen-side real-turn test and independent postcondition evidence.
