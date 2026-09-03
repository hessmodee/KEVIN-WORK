import { lstat, readdir } from "node:fs/promises";
import { join } from "node:path";
import { spawn, type ChildProcess, type SpawnOptions } from "node:child_process";

export type DesktopResult = {
  ok: boolean;
  action: "find_folder" | "open_folder" | "launch_app";
  name?: string;
  app?: string;
  matches?: number;
  error?: "invalid_name" | "not_found" | "ambiguous" | "unsafe_target" | "unsupported_platform" | "launch_failed";
};

export type SpawnFn = (
  command: string,
  args: string[],
  options: SpawnOptions,
) => Pick<ChildProcess, "unref">;

const nodeSpawn: SpawnFn = (command, args, options) => spawn(command, args, options);
const FORBIDDEN_NAME = /[\\/:*?"<>|\u0000-\u001F]/;

export const APP_ALLOWLIST = Object.freeze({
  notepad: { exe: "notepad.exe", args: [] as string[] },
  calculator: { exe: "calc.exe", args: [] as string[] },
  paint: { exe: "mspaint.exe", args: [] as string[] },
  explorer: { exe: "explorer.exe", args: [] as string[] },
});

export type AllowedApp = keyof typeof APP_ALLOWLIST;

export function isSafeDesktopName(value: unknown): value is string {
  if (typeof value !== "string") return false;
  if (value.length < 1 || value.length > 120) return false;
  if (value !== value.trim()) return false;
  if (value === "." || value === "..") return false;
  if (FORBIDDEN_NAME.test(value)) return false;
  return true;
}

export function defaultDesktopRoots(env: NodeJS.ProcessEnv = process.env): string[] {
  const roots: string[] = [];
  const userProfile = env.USERPROFILE;
  if (userProfile) roots.push(join(userProfile, "Desktop"));
  for (const key of ["OneDrive", "OneDriveCommercial", "OneDriveConsumer"] as const) {
    const base = env[key];
    if (base) roots.push(join(base, "Desktop"));
  }
  return [...new Set(roots.map((p) => p.toLowerCase()))].map((lower) => {
    const original = roots.find((p) => p.toLowerCase() === lower);
    return original ?? lower;
  });
}

async function safeDirectChildFolders(name: string, roots: readonly string[]): Promise<string[]> {
  if (!isSafeDesktopName(name)) return [];
  const matches: string[] = [];
  for (const root of roots) {
    let entries;
    try {
      entries = await readdir(root, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      if (entry.name.localeCompare(name, undefined, { sensitivity: "accent" }) !== 0) continue;
      const candidate = join(root, entry.name);
      try {
        const info = await lstat(candidate);
        if (!info.isDirectory() || info.isSymbolicLink()) continue;
      } catch {
        continue;
      }
      matches.push(candidate);
    }
  }
  return [...new Set(matches.map((p) => p.toLowerCase()))].map((lower) => {
    const original = matches.find((p) => p.toLowerCase() === lower);
    return original ?? lower;
  });
}

export async function findDesktopFolder(
  name: string,
  roots: readonly string[] = defaultDesktopRoots(),
): Promise<DesktopResult> {
  if (!isSafeDesktopName(name)) return { ok: false, action: "find_folder", error: "invalid_name" };
  const matches = await safeDirectChildFolders(name, roots);
  if (matches.length === 0) return { ok: false, action: "find_folder", name, matches: 0, error: "not_found" };
  if (matches.length > 1) return { ok: false, action: "find_folder", name, matches: matches.length, error: "ambiguous" };
  return { ok: true, action: "find_folder", name, matches: 1 };
}

function launchDetached(exe: string, args: readonly string[], spawnFn: SpawnFn = nodeSpawn): boolean {
  try {
    const child = spawnFn(exe, [...args], {
      shell: false,
      detached: true,
      windowsHide: false,
      stdio: "ignore",
    });
    child.unref();
    return true;
  } catch {
    return false;
  }
}

export async function openDesktopFolder(
  name: string,
  roots: readonly string[] = defaultDesktopRoots(),
  spawnFn: SpawnFn = nodeSpawn,
): Promise<DesktopResult> {
  if (process.platform !== "win32" && spawnFn === nodeSpawn) {
    return { ok: false, action: "open_folder", name, error: "unsupported_platform" };
  }
  if (!isSafeDesktopName(name)) return { ok: false, action: "open_folder", error: "invalid_name" };
  const matches = await safeDirectChildFolders(name, roots);
  if (matches.length === 0) return { ok: false, action: "open_folder", name, matches: 0, error: "not_found" };
  if (matches.length > 1) return { ok: false, action: "open_folder", name, matches: matches.length, error: "ambiguous" };
  const opened = launchDetached("explorer.exe", [matches[0]], spawnFn);
  return opened
    ? { ok: true, action: "open_folder", name, matches: 1 }
    : { ok: false, action: "open_folder", name, matches: 1, error: "launch_failed" };
}

export function launchAllowedApp(app: string, spawnFn: SpawnFn = nodeSpawn): DesktopResult {
  if (process.platform !== "win32" && spawnFn === nodeSpawn) {
    return { ok: false, action: "launch_app", app, error: "unsupported_platform" };
  }
  if (!Object.prototype.hasOwnProperty.call(APP_ALLOWLIST, app)) {
    return { ok: false, action: "launch_app", app, error: "unsafe_target" };
  }
  const spec = APP_ALLOWLIST[app as AllowedApp];
  const launched = launchDetached(spec.exe, spec.args, spawnFn);
  return launched
    ? { ok: true, action: "launch_app", app }
    : { ok: false, action: "launch_app", app, error: "launch_failed" };
}
