import { afterEach, describe, expect, it } from "vitest";
import { mkdtemp, mkdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { getToolPluginMetadata } from "openclaw/plugin-sdk/tool-plugin";
import entry from "./index.js";
import {
  APP_ALLOWLIST,
  findDesktopFolder,
  isSafeDesktopName,
  launchAllowedApp,
  openDesktopFolder,
  type SpawnFn,
} from "./desktop.js";

const cleanup: string[] = [];
afterEach(async () => {
  for (const p of cleanup.splice(0)) await rm(p, { recursive: true, force: true });
});

function fakeSpawn(calls: Array<{ exe: string; args: readonly string[]; shell: unknown }>): SpawnFn {
  return (exe, args = [], options = {}) => {
    calls.push({ exe, args, shell: options.shell });
    return { unref() {} };
  };
}

async function desktopFixture() {
  const root = await mkdtemp(join(tmpdir(), "kevin-desktop-test-"));
  cleanup.push(root);
  const desktop = join(root, "Desktop");
  await mkdir(desktop);
  await mkdir(join(desktop, "Classic Cars"));
  return desktop;
}

describe("kevin-desktop plugin contract", () => {
  it("declares only the three bounded desktop tools", () => {
    const tools = getToolPluginMetadata(entry)?.tools ?? [];
    expect(tools.map((tool) => tool.name)).toEqual([
      "kevin_desktop_find_folder",
      "kevin_desktop_open_folder",
      "kevin_app_launch",
    ]);
    expect(tools.every((tool) => tool.optional === true)).toBe(true);
  });

  it("keeps fixed application allowlist narrow", () => {
    expect(Object.keys(APP_ALLOWLIST).sort()).toEqual(["calculator", "explorer", "notepad", "paint"]);
    expect(JSON.stringify(APP_ALLOWLIST)).not.toMatch(/cmd\.exe|powershell|pwsh|wscript|cscript/i);
  });
});

describe("Desktop folder boundary", () => {
  it("rejects paths, traversal, separators, and whitespace tricks", () => {
    for (const value of ["../secret", "..", ".", "C:\\Windows", "foo/bar", " foo", "foo ", "foo|bar", ""]) {
      expect(isSafeDesktopName(value)).toBe(false);
    }
    expect(isSafeDesktopName("Classic Cars")).toBe(true);
  });

  it("finds one direct Desktop child without returning its private path", async () => {
    const desktop = await desktopFixture();
    const result = await findDesktopFolder("classic cars", [desktop]);
    expect(result).toEqual({ ok: true, action: "find_folder", name: "classic cars", matches: 1 });
    expect(JSON.stringify(result)).not.toContain(desktop);
  });

  it("does not recursively discover nested folders", async () => {
    const desktop = await desktopFixture();
    await mkdir(join(desktop, "Classic Cars", "Nested"));
    const result = await findDesktopFolder("Nested", [desktop]);
    expect(result.ok).toBe(false);
    expect(result.error).toBe("not_found");
  });

  it("opens only the resolved direct child through explorer with shell disabled", async () => {
    const desktop = await desktopFixture();
    const calls: Array<{ exe: string; args: readonly string[]; shell: unknown }> = [];
    const result = await openDesktopFolder("Classic Cars", [desktop], fakeSpawn(calls));
    expect(result.ok).toBe(true);
    expect(calls).toHaveLength(1);
    expect(calls[0].exe).toBe("explorer.exe");
    expect(calls[0].args).toEqual([join(desktop, "Classic Cars")]);
    expect(calls[0].shell).toBe(false);
  });
});

describe("Application launch boundary", () => {
  it("launches only fixed allowlisted executable identities", () => {
    const calls: Array<{ exe: string; args: readonly string[]; shell: unknown }> = [];
    const result = launchAllowedApp("notepad", fakeSpawn(calls));
    expect(result.ok).toBe(true);
    expect(calls).toEqual([{ exe: "notepad.exe", args: [], shell: false }]);
  });

  it("rejects arbitrary executables and commands", () => {
    const calls: Array<{ exe: string; args: readonly string[]; shell: unknown }> = [];
    for (const value of ["cmd", "powershell", "C:\\Windows\\System32\\cmd.exe", "notepad.exe /A secret.txt"]) {
      const result = launchAllowedApp(value, fakeSpawn(calls));
      expect(result.ok).toBe(false);
      expect(result.error).toBe("unsafe_target");
    }
    expect(calls).toHaveLength(0);
  });
});
