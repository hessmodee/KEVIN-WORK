import { lstat, readdir } from "node:fs/promises";
import { join } from "node:path";
import { spawn, type ChildProcess, type SpawnOptions } from "node:child_process";

export type DesktopEntryKind = "file" | "dir";

export type DesktopListEntry = {
  name: string;
  kind: DesktopEntryKind;
};

export type DesktopResult = {
  ok: boolean;
  action: "find_folder" | "open_folder" | "launch_app" | "list_folder";
  name?: string;
  app?: string;
  root?: AllowedListRoot;
  matches?: number;
  entries?: DesktopListEntry[];
  count?: number;
  truncated?: boolean;
  redacted?: number;
  error?:
    | "invalid_name"
    | "invalid_root"
    | "invalid_limit"
    | "not_found"
    | "ambiguous"
    | "unsafe_target"
    | "unsupported_platform"
    | "launch_failed";
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

/** Fixed known-user-folder roots for list_folder only. No arbitrary paths. */
export const LIST_ROOT_ALLOWLIST = Object.freeze([
  "Desktop",
  "Documents",
  "Downloads",
  "Pictures",
  "Music",
  "Videos",
] as const);

export type AllowedListRoot = (typeof LIST_ROOT_ALLOWLIST)[number];

export const DEFAULT_LIST_LIMIT = 50;
export const MAX_LIST_LIMIT = 100;

/** Optional secret-deny: omit matching basenames from list results (still counted in redacted). */
const SECRET_DENY_BASENAME =
  /^(?:\.env(?:\..*)?|.*(?:secret|credential|password|passwd|private.?key).*(?:\..*)?|.*\.(?:pem|key|pfx|p12|keystore)|id_rsa(?:\..*)?|id_ed25519(?:\..*)?|id_dsa(?:\..*)?)$/i;

export function isSafeDesktopName(value: unknown): value is string {
  if (typeof value !== "string") return false;
  if (value.length < 1 || value.length > 120) return false;
  if (value !== value.trim()) return false;
  if (value === "." || value === "..") return false;
  if (FORBIDDEN_NAME.test(value)) return false;
  return true;
}

export function isAllowedListRoot(value: unknown): value is AllowedListRoot {
  return typeof value === "string" && (LIST_ROOT_ALLOWLIST as readonly string[]).includes(value);
}

export function isSecretDeniedName(name: string): boolean {
  return SECRET_DENY_BASENAME.test(name);
}

export function clampListLimit(value: unknown): number | null {
  if (value === undefined || value === null) return DEFAULT_LIST_LIMIT;
  if (typeof value !== "number" || !Number.isInteger(value)) return null;
  if (value < 1 || value > MAX_LIST_LIMIT) return null;
  return value;
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

export function resolveKnownFolderRoots(
  root: AllowedListRoot,
  env: NodeJS.ProcessEnv = process.env,
): string[] {
  if (root === "Desktop") return defaultDesktopRoots(env);
  const userProfile = env.USERPROFILE;
  if (!userProfile) return [];
  return [join(userProfile, root)];
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

async function resolveListTargetPath(
  root: AllowedListRoot,
  name: string | undefined,
  env: NodeJS.ProcessEnv,
): Promise<{ paths: string[]; error?: DesktopResult["error"] }> {
  const roots = resolveKnownFolderRoots(root, env);
  if (roots.length === 0) return { paths: [], error: "not_found" };
  if (name === undefined) {
    const kept: string[] = [];
    for (const r of roots) {
      try {
        const info = await lstat(r);
        if (info.isDirectory() && !info.isSymbolicLink()) kept.push(r);
      } catch {
        continue;
      }
    }
    if (kept.length === 0) return { paths: [], error: "not_found" };
    return { paths: kept };
  }
  if (!isSafeDesktopName(name)) return { paths: [], error: "invalid_name" };
  const matches = await safeDirectChildFolders(name, roots);
  if (matches.length === 0) return { paths: [], error: "not_found" };
  if (matches.length > 1) return { paths: matches, error: "ambiguous" };
  return { paths: matches };
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

export type ListFolderOptions = {
  root?: unknown;
  name?: unknown;
  limit?: unknown;
  env?: NodeJS.ProcessEnv;
};

/**
 * Bounded depth-1 listing of an allowlisted known user folder, or one safe direct child.
 * Returns basenames + kind only — never private host paths. Secret-deny names are omitted.
 */
export async function listFolder(options: ListFolderOptions = {}): Promise<DesktopResult> {
  const rootRaw = options.root === undefined ? "Desktop" : options.root;
  if (!isAllowedListRoot(rootRaw)) {
    return { ok: false, action: "list_folder", error: "invalid_root" };
  }
  const root = rootRaw;
  const limit = clampListLimit(options.limit);
  if (limit === null) {
    return { ok: false, action: "list_folder", root, error: "invalid_limit" };
  }

  let childName: string | undefined;
  if (options.name !== undefined && options.name !== null) {
    if (!isSafeDesktopName(options.name)) {
      return { ok: false, action: "list_folder", root, error: "invalid_name" };
    }
    childName = options.name;
  }

  const env = options.env ?? process.env;
  const resolved = await resolveListTargetPath(root, childName, env);
  if (resolved.error === "invalid_name") {
    return { ok: false, action: "list_folder", root, name: childName, error: "invalid_name" };
  }
  if (resolved.error === "not_found") {
    return { ok: false, action: "list_folder", root, name: childName, matches: 0, error: "not_found" };
  }
  if (resolved.error === "ambiguous") {
    return {
      ok: false,
      action: "list_folder",
      root,
      name: childName,
      matches: resolved.paths.length,
      error: "ambiguous",
    };
  }

  const byName = new Map<string, DesktopListEntry>();
  let redacted = 0;
  for (const dirPath of resolved.paths) {
    let entries;
    try {
      entries = await readdir(dirPath, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (entry.name === "." || entry.name === "..") continue;
      if (isSecretDeniedName(entry.name)) {
        redacted += 1;
        continue;
      }
      const candidate = join(dirPath, entry.name);
      let kind: DesktopEntryKind | null = null;
      try {
        const info = await lstat(candidate);
        if (info.isSymbolicLink()) continue;
        if (info.isDirectory()) kind = "dir";
        else if (info.isFile()) kind = "file";
        else continue;
      } catch {
        continue;
      }
      const key = entry.name.toLowerCase();
      if (!byName.has(key)) {
        byName.set(key, { name: entry.name, kind });
      }
    }
  }

  const sorted = [...byName.values()].sort((a, b) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: "base" }),
  );
  const truncated = sorted.length > limit;
  const page = sorted.slice(0, limit);
  return {
    ok: true,
    action: "list_folder",
    root,
    name: childName,
    entries: page,
    count: page.length,
    truncated,
    redacted,
    matches: resolved.paths.length,
  };
}
