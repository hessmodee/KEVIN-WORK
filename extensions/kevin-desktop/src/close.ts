import { spawnSync, type SpawnSyncReturns } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

export type CloseResult = {
  ok: boolean;
  action: "close_app";
  app?: string;
  processName?: string;
  method?: string;
  detail?: string;
  error?:
    | "unsafe_target"
    | "not_authorized"
    | "unsupported_platform"
    | "script_missing"
    | "close_failed"
    | "protected";
};

/** Close allowlist — explorer excluded (shell host). minecraft gated by env. */
export const CLOSE_APP_ALLOWLIST = Object.freeze({
  notepad: { processName: "Notepad" },
  calculator: { processName: "CalculatorApp" },
  paint: { processName: "mspaint" },
  minecraft: { processName: "Minecraft.Windows", requireEnv: "KEVIN_ALLOW_CLOSE_MC" as const },
});

export type ClosableApp = keyof typeof CLOSE_APP_ALLOWLIST;

export type CloseRunFn = (
  command: string,
  args: string[],
) => Pick<SpawnSyncReturns<string>, "status" | "stdout" | "stderr" | "error">;

const defaultRun: CloseRunFn = (command, args) =>
  spawnSync(command, args, {
    encoding: "utf8",
    windowsHide: true,
    shell: false,
  });

export function defaultCloseScriptPath(metaUrl: string = import.meta.url): string {
  return join(dirname(fileURLToPath(metaUrl)), "..", "scripts", "kevin-app-close.ps1");
}

/**
 * Graceful-then-audited close for allowlisted apps only.
 * Minecraft requires KEVIN_ALLOW_CLOSE_MC=1 (Matt authorized 2026-09-05).
 * Never closes Chat/Reader/node gateways (enforced in script + name gate).
 */
export function closeAllowedApp(
  app: string,
  options: {
    force?: boolean;
    graceMs?: number;
    env?: NodeJS.ProcessEnv;
    scriptPath?: string;
    run?: CloseRunFn;
  } = {},
): CloseResult {
  const env = options.env ?? process.env;
  if (process.platform !== "win32" && !options.run) {
    return { ok: false, action: "close_app", app, error: "unsupported_platform" };
  }
  if (!Object.prototype.hasOwnProperty.call(CLOSE_APP_ALLOWLIST, app)) {
    return { ok: false, action: "close_app", app, error: "unsafe_target" };
  }
  const spec = CLOSE_APP_ALLOWLIST[app as ClosableApp];
  if ("requireEnv" in spec && spec.requireEnv) {
    if (String(env[spec.requireEnv] ?? "") !== "1") {
      return {
        ok: false,
        action: "close_app",
        app,
        processName: spec.processName,
        error: "not_authorized",
        detail: `${spec.requireEnv}=1 required`,
      };
    }
  }
  const scriptPath = options.scriptPath ?? defaultCloseScriptPath();
  if (!options.run && !existsSync(scriptPath)) {
    return { ok: false, action: "close_app", app, error: "script_missing", detail: scriptPath };
  }
  const graceMs = options.graceMs ?? 5000;
  const args = [
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    scriptPath,
    "-ProcessName",
    spec.processName,
    "-GraceMs",
    String(graceMs),
  ];
  if (options.force) args.push("-Force");

  const run = options.run ?? defaultRun;
  const result = run("powershell.exe", args);
  const out = `${result.stdout ?? ""}\n${result.stderr ?? ""}`.trim();
  if (out.includes("KEVIN_APP_CLOSE_DENIED_PROTECTED")) {
    return { ok: false, action: "close_app", app, processName: spec.processName, error: "protected", detail: out };
  }
  if (out.includes("KEVIN_APP_CLOSE_ALREADY_GONE") || out.includes("KEVIN_APP_CLOSE_OK")) {
    const methodMatch = out.match(/method=(\w+)/);
    return {
      ok: true,
      action: "close_app",
      app,
      processName: spec.processName,
      method: methodMatch?.[1] ?? (out.includes("ALREADY_GONE") ? "already_gone" : "ok"),
      detail: out,
    };
  }
  return {
    ok: false,
    action: "close_app",
    app,
    processName: spec.processName,
    error: "close_failed",
    detail: out || result.error?.message || `status=${result.status}`,
  };
}
