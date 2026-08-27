import { describe, expect, it } from "vitest";
import entry from "./index.js";
import { getToolPluginMetadata } from "openclaw/plugin-sdk/tool-plugin";
import {
  PUBLIC_KEYS,
  collectStatus,
  parseStatus,
  publicKeysOf,
  toPublicStatus,
  type Status,
} from "./collect.js";

const sample: Status = {
  ok: true,
  collected_at: "2026-08-26T21:57:00-06:00",
  ram_used_gb: 8.9,
  ram_total_gb: 15.9,
  ram_load_percent: 56,
  cpu_percent: 10,
  gpu_name: "NVIDIA GeForce RTX 3060",
  gpu_percent: 21,
  vram_used_mb: 1408,
  vram_total_mb: 12288,
  disk_free_gb: 135.4,
  ollama_status: "running",
  gateway_status: "open",
  error: "",
};

describe("kevin-core", () => {
  it("declares only kevin_system_status", () => {
    const tools = getToolPluginMetadata(entry)?.tools ?? [];
    expect(tools.map((tool) => tool.name)).toEqual(["kevin_system_status"]);
    expect(tools[0]?.optional).toBe(true);
    expect(tools[0]).not.toHaveProperty("outputSchema");
  });

  it("accepts no parameters", () => {
    const parameters = getToolPluginMetadata(entry)?.tools[0]?.parameters as {
      properties?: Record<string, unknown>;
    };
    expect(parameters?.properties ?? {}).toEqual({});
  });

  it("parses helper JSON into a new approved object", () => {
    const parsed = parseStatus(JSON.stringify(sample));
    expect(parsed.ok).toBe(true);
    expect(parsed.gpu_name).toBe("NVIDIA GeForce RTX 3060");
    expect(parsed.ram_load_percent).toBe(56);
    expect(publicKeysOf(parsed)).toEqual([...PUBLIC_KEYS].sort());
  });

  it("drops extra private fields by construction", () => {
    const parsed = toPublicStatus({
      ...sample,
      username: "hessm",
      local_path: "C:\\Users\\hessm\\secret",
      gateway_port: 18789,
      api_key: "xai-ABCDEFGH1234",
    });
    expect(parsed.ok).toBe(true);
    const blob = JSON.stringify(parsed);
    expect(blob).not.toMatch(/hessm/i);
    expect(blob).not.toMatch(/C:\\Users/i);
    expect(blob).not.toMatch(/18789/);
    expect(blob).not.toMatch(/api_key/);
    expect(blob).not.toMatch(/xai-/);
    expect(publicKeysOf(parsed)).toEqual([...PUBLIC_KEYS].sort());
  });

  it("fails closed on wrong types", () => {
    const parsed = toPublicStatus({ ...sample, ram_used_gb: "9.2" });
    expect(parsed.ok).toBe(false);
    expect(parsed.error).toBe("invalid_shape");
  });

  it("redacts forbidden strings in allowed fields", () => {
    const parsed = toPublicStatus({
      ...sample,
      gpu_name: "C:\\Users\\hessm\\secret",
      error: "xai-ABCDEFGH1234",
    });
    const blob = JSON.stringify(parsed);
    expect(blob).not.toMatch(/hessm/i);
    expect(blob).not.toMatch(/C:\\Users/i);
    expect(blob).not.toMatch(/xai-/);
    expect(parsed.gpu_name).toContain("redacted");
  });

  it("returns structured failure on timeout", async () => {
    const result = await collectStatus(undefined, async () => ({
      code: 124,
      stdout: "",
      stderr: "timeout",
    }));
    expect(result.ok).toBe(false);
    expect(result.error).toBe("timeout");
  });

  it("returns structured failure on helper crash", async () => {
    const result = await collectStatus(undefined, async () => ({
      code: 1,
      stdout: "",
      stderr: "boom",
    }));
    expect(result.ok).toBe(false);
    expect(result.error).toBe("helper_failed");
  });

  it("honors abort", async () => {
    const ac = new AbortController();
    ac.abort();
    const result = await collectStatus(ac.signal, async () => {
      throw new Error("should-not-run");
    });
    expect(result.ok).toBe(false);
    expect(["aborted", "helper_failed"]).toContain(result.error);
  });
});
