import { afterEach, describe, expect, it } from "vitest";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { getToolPluginMetadata } from "openclaw/plugin-sdk/tool-plugin";
import entry from "./index.js";
import {
  APP_ALLOWLIST,
  DEFAULT_LIST_LIMIT,
  LIST_ROOT_ALLOWLIST,
  MAX_LIST_LIMIT,
  findDesktopFolder,
  isSafeDesktopName,
  isSecretDeniedName,
  launchAllowedApp,
  listFolder,
  openDesktopFolder,
  type SpawnFn,
} from "./desktop.js";
import {
  CLOSE_APP_ALLOWLIST,
  closeAllowedApp,
  type CloseRunFn,
} from "./close.js";

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
  return { profile: root, desktop };
}

describe("kevin-desktop plugin contract", () => {
  it("declares the five bounded desktop tools including list_folder and kevin_app_close", () => {
    const tools = getToolPluginMetadata(entry)?.tools ?? [];
    expect(tools.map((tool) => tool.name)).toEqual([
      "kevin_desktop_find_folder",
      "kevin_desktop_open_folder",
      "kevin_desktop_list_folder",
      "kevin_app_launch",
      "kevin_app_close",
    ]);
    expect(tools.every((tool) => tool.optional === true)).toBe(true);
  });

  it("keeps fixed application allowlist narrow", () => {
    expect(Object.keys(APP_ALLOWLIST).sort()).toEqual(["calculator", "explorer", "notepad", "paint"]);
    expect(JSON.stringify(APP_ALLOWLIST)).not.toMatch(/cmd\.exe|powershell|pwsh|wscript|cscript/i);
  });

  it("keeps list roots on known user folders only", () => {
    expect([...LIST_ROOT_ALLOWLIST]).toEqual([
      "Desktop",
      "Documents",
      "Downloads",
      "Pictures",
      "Music",
      "Videos",
    ]);
    expect(DEFAULT_LIST_LIMIT).toBe(50);
    expect(MAX_LIST_LIMIT).toBe(100);
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
    const { desktop } = await desktopFixture();
    const result = await findDesktopFolder("classic cars", [desktop]);
    expect(result).toEqual({ ok: true, action: "find_folder", name: "classic cars", matches: 1 });
    expect(JSON.stringify(result)).not.toContain(desktop);
  });

  it("does not recursively discover nested folders", async () => {
    const { desktop } = await desktopFixture();
    await mkdir(join(desktop, "Classic Cars", "Nested"));
    const result = await findDesktopFolder("Nested", [desktop]);
    expect(result.ok).toBe(false);
    expect(result.error).toBe("not_found");
  });

  it("opens only the resolved direct child through explorer with shell disabled", async () => {
    const { desktop } = await desktopFixture();
    const calls: Array<{ exe: string; args: readonly string[]; shell: unknown }> = [];
    const result = await openDesktopFolder("Classic Cars", [desktop], fakeSpawn(calls));
    expect(result.ok).toBe(true);
    expect(calls).toHaveLength(1);
    expect(calls[0].exe).toBe("explorer.exe");
    expect(calls[0].args).toEqual([join(desktop, "Classic Cars")]);
    expect(calls[0].shell).toBe(false);
  });
});

describe("list_folder boundary", () => {
  it("lists Desktop root depth-1 names without private paths", async () => {
    const { profile, desktop } = await desktopFixture();
    await writeFile(join(desktop, "notes.txt"), "hi");
    await mkdir(join(desktop, "Classic Cars", "Nested"));
    const result = await listFolder({ root: "Desktop", env: { USERPROFILE: profile } });
    expect(result.ok).toBe(true);
    expect(result.action).toBe("list_folder");
    expect(result.root).toBe("Desktop");
    expect(result.entries?.map((e) => e.name).sort()).toEqual(["Classic Cars", "notes.txt"]);
    expect(result.entries?.find((e) => e.name === "Classic Cars")?.kind).toBe("dir");
    expect(result.entries?.find((e) => e.name === "notes.txt")?.kind).toBe("file");
    expect(result.entries?.some((e) => e.name === "Nested")).toBe(false);
    expect(JSON.stringify(result)).not.toContain(profile);
    expect(JSON.stringify(result)).not.toContain(desktop);
  });

  it("lists a safe direct Desktop child folder", async () => {
    const { profile, desktop } = await desktopFixture();
    await writeFile(join(desktop, "Classic Cars", "car.txt"), "x");
    const result = await listFolder({
      root: "Desktop",
      name: "Classic Cars",
      env: { USERPROFILE: profile },
    });
    expect(result.ok).toBe(true);
    expect(result.name).toBe("Classic Cars");
    expect(result.entries).toEqual([{ name: "car.txt", kind: "file" }]);
  });

  it("refuses traversal, absolute escapes, and invalid roots/limits", async () => {
    const { profile } = await desktopFixture();
    for (const name of ["../secret", "..", "C:\\Windows", "foo/bar", "foo\\bar"]) {
      const result = await listFolder({ root: "Desktop", name, env: { USERPROFILE: profile } });
      expect(result.ok).toBe(false);
      expect(result.error).toBe("invalid_name");
    }
    expect((await listFolder({ root: "C:\\Windows" as never, env: { USERPROFILE: profile } })).error).toBe(
      "invalid_root",
    );
    expect((await listFolder({ root: "Desktop", limit: 0, env: { USERPROFILE: profile } })).error).toBe(
      "invalid_limit",
    );
    expect((await listFolder({ root: "Desktop", limit: 101, env: { USERPROFILE: profile } })).error).toBe(
      "invalid_limit",
    );
  });

  it("redacts secret-deny basenames and honors limit truncation", async () => {
    expect(isSecretDeniedName(".env")).toBe(true);
    expect(isSecretDeniedName("credentials.json")).toBe(true);
    expect(isSecretDeniedName("notes.txt")).toBe(false);
    const { profile, desktop } = await desktopFixture();
    await writeFile(join(desktop, ".env"), "x");
    await writeFile(join(desktop, "credentials.json"), "x");
    await writeFile(join(desktop, "a.txt"), "x");
    await writeFile(join(desktop, "b.txt"), "x");
    await writeFile(join(desktop, "c.txt"), "x");
    const result = await listFolder({ root: "Desktop", limit: 2, env: { USERPROFILE: profile } });
    expect(result.ok).toBe(true);
    expect(result.redacted).toBeGreaterThanOrEqual(2);
    expect(result.entries?.some((e) => e.name === ".env")).toBe(false);
    expect(result.entries?.some((e) => e.name === "credentials.json")).toBe(false);
    expect(result.count).toBe(2);
    expect(result.truncated).toBe(true);
  });

  it("lists Documents known-folder root when present", async () => {
    const { profile } = await desktopFixture();
    const docs = join(profile, "Documents");
    await mkdir(docs);
    await writeFile(join(docs, "todo.md"), "x");
    const result = await listFolder({ root: "Documents", env: { USERPROFILE: profile } });
    expect(result.ok).toBe(true);
    expect(result.root).toBe("Documents");
    expect(result.entries).toEqual([{ name: "todo.md", kind: "file" }]);
    expect(JSON.stringify(result)).not.toContain(docs);
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

describe("Application close boundary", () => {
  it("keeps close allowlist narrow and excludes explorer", () => {
    expect(Object.keys(CLOSE_APP_ALLOWLIST).sort()).toEqual([
      "calculator",
      "minecraft",
      "notepad",
      "paint",
    ]);
    expect(CLOSE_APP_ALLOWLIST).not.toHaveProperty("explorer");
  });

  it("refuses minecraft close without KEVIN_ALLOW_CLOSE_MC=1", () => {
    const result = closeAllowedApp("minecraft", {
      env: {},
      run: () => ({ status: 0, stdout: "", stderr: "", error: undefined }),
    });
    expect(result.ok).toBe(false);
    expect(result.error).toBe("not_authorized");
  });

  it("closes calculator via fixed script args when authorized path mocked", () => {
    const calls: Array<{ command: string; args: string[] }> = [];
    const run: CloseRunFn = (command, args) => {
      calls.push({ command, args });
      return {
        status: 0,
        stdout: "KEVIN_APP_CLOSE_OK method=CloseMainWindow name=CalculatorApp",
        stderr: "",
        error: undefined,
      };
    };
    const result = closeAllowedApp("calculator", { force: true, run, scriptPath: "C:\\fake\\kevin-app-close.ps1" });
    expect(result.ok).toBe(true);
    expect(result.method).toBe("CloseMainWindow");
    expect(calls).toHaveLength(1);
    expect(calls[0].command).toBe("powershell.exe");
    expect(calls[0].args).toContain("-File");
    expect(calls[0].args).toContain("CalculatorApp");
    expect(calls[0].args).toContain("-Force");
    expect(calls[0].args.join(" ")).not.toMatch(/cmd\.exe|18789|19001/i);
  });

  it("rejects arbitrary close targets", () => {
    const result = closeAllowedApp("powershell", {
      run: () => ({ status: 0, stdout: "", stderr: "", error: undefined }),
    });
    expect(result.ok).toBe(false);
    expect(result.error).toBe("unsafe_target");
  });

  it("surfaces protected denial from script", () => {
    const result = closeAllowedApp("notepad", {
      run: () => ({
        status: 10,
        stdout: "KEVIN_APP_CLOSE_DENIED_PROTECTED",
        stderr: "",
        error: undefined,
      }),
      scriptPath: "C:\\fake\\kevin-app-close.ps1",
    });
    expect(result.ok).toBe(false);
    expect(result.error).toBe("protected");
  });
});

