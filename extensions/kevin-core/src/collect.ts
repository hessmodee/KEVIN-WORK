import { spawn } from "node:child_process";
import os from "node:os";
import path from "node:path";

export type Status = {
  ok: boolean;
  collected_at: string;
  ram_used_gb: number;
  ram_total_gb: number;
  ram_load_percent: number;
  cpu_percent: number;
  gpu_name: string;
  gpu_percent: number;
  vram_used_mb: number;
  vram_total_mb: number;
  disk_free_gb: number;
  ollama_status: string;
  gateway_status: string;
  error: string;
};

export const PUBLIC_KEYS = [
  "ok",
  "collected_at",
  "ram_used_gb",
  "ram_total_gb",
  "ram_load_percent",
  "cpu_percent",
  "gpu_name",
  "gpu_percent",
  "vram_used_mb",
  "vram_total_mb",
  "disk_free_gb",
  "ollama_status",
  "gateway_status",
  "error",
] as const;

export const STATUS_TIMEOUT_MS = 12_000;

const FORBIDDEN = [
  /C:\\Users/i,
  /hessm/i,
  /:18789\b/,
  /127\.0\.0\.1/,
  /xai-[A-Za-z0-9]{8,}/,
  /ghp_[A-Za-z0-9]{8,}/,
];

const NUM_KEYS = [
  "ram_used_gb",
  "ram_total_gb",
  "ram_load_percent",
  "cpu_percent",
  "gpu_percent",
  "vram_used_mb",
  "vram_total_mb",
  "disk_free_gb",
] as const;

const STR_KEYS = ["collected_at", "gpu_name", "ollama_status", "gateway_status", "error"] as const;

function isoNow(): string {
  return new Date().toISOString();
}

export function fail(error: string): Status {
  return {
    ok: false,
    collected_at: isoNow(),
    ram_used_gb: 0,
    ram_total_gb: 0,
    ram_load_percent: 0,
    cpu_percent: 0,
    gpu_name: "unavailable",
    gpu_percent: 0,
    vram_used_mb: 0,
    vram_total_mb: 0,
    disk_free_gb: 0,
    ollama_status: "unknown",
    gateway_status: "unknown",
    error,
  };
}

function cleanString(value: string): string {
  let next = value;
  for (const re of FORBIDDEN) {
    next = next.replace(re, "redacted");
  }
  return next;
}

export function toPublicStatus(raw: unknown): Status {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return fail("invalid_json");
  }
  const src = raw as Record<string, unknown>;
  const nums: Record<string, number> = {};
  for (const key of NUM_KEYS) {
    const v = src[key];
    if (typeof v !== "number" || !Number.isFinite(v)) {
      if (src.ok === true) {
        return fail("invalid_shape");
      }
      nums[key] = 0;
    } else {
      nums[key] = v;
    }
  }
  const strs: Record<string, string> = {};
  for (const key of STR_KEYS) {
    const v = src[key];
    strs[key] = typeof v === "string" ? cleanString(v) : key === "collected_at" ? isoNow() : "";
  }
  if (!strs.gpu_name) strs.gpu_name = "unavailable";
  if (!strs.ollama_status) strs.ollama_status = "unknown";
  if (!strs.gateway_status) strs.gateway_status = "unknown";

  const built: Status = {
    ok: src.ok === true,
    collected_at: strs.collected_at,
    ram_used_gb: nums.ram_used_gb,
    ram_total_gb: nums.ram_total_gb,
    ram_load_percent: nums.ram_load_percent,
    cpu_percent: nums.cpu_percent,
    gpu_name: strs.gpu_name,
    gpu_percent: nums.gpu_percent,
    vram_used_mb: nums.vram_used_mb,
    vram_total_mb: nums.vram_total_mb,
    disk_free_gb: nums.disk_free_gb,
    ollama_status: strs.ollama_status,
    gateway_status: strs.gateway_status,
    error: src.ok === true ? "" : strs.error || "helper_failed",
  };
  return built;
}

export function publicKeysOf(data: Status): string[] {
  return Object.keys(data).sort();
}

export function parseStatus(stdout: string): Status {
  const text = stdout.trim();
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) {
    return fail("invalid_json");
  }
  try {
    return toPublicStatus(JSON.parse(text.slice(start, end + 1)));
  } catch {
    return fail("invalid_json");
  }
}

export type Runner = (
  command: string,
  args: string[],
  signal?: AbortSignal,
) => Promise<{ code: number; stdout: string; stderr: string }>;

export const defaultRunner: Runner = (command, args, signal) =>
  new Promise((resolve, reject) => {
    const child = spawn(command, args, { windowsHide: true });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      child.kill();
      resolve({ code: 124, stdout, stderr: stderr + "timeout" });
    }, STATUS_TIMEOUT_MS);
    const onAbort = () => {
      child.kill();
      clearTimeout(timer);
      reject(new Error("aborted"));
    };
    signal?.addEventListener("abort", onAbort, { once: true });
    child.stdout?.on("data", (chunk: Buffer | string) => {
      stdout += String(chunk);
    });
    child.stderr?.on("data", (chunk: Buffer | string) => {
      stderr += String(chunk);
    });
    child.on("error", (err) => {
      clearTimeout(timer);
      signal?.removeEventListener("abort", onAbort);
      reject(err);
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      signal?.removeEventListener("abort", onAbort);
      resolve({ code: code ?? 1, stdout, stderr });
    });
  });

export function helperPath(): string {
  return path.join(os.homedir(), ".openclaw", "workspace", "helper_system_status.py");
}

export async function collectStatus(
  signal?: AbortSignal,
  run: Runner = defaultRunner,
): Promise<Status> {
  try {
    signal?.throwIfAborted();
    const script = helperPath();
    const python = process.env.KEVIN_PYTHON || "python";
    const result = await run(python, [script, "--json"], signal);
    if (result.code === 124) {
      return fail("timeout");
    }
    if (!result.stdout.trim()) {
      return fail(result.code === 0 ? "empty_output" : "helper_failed");
    }
    const parsed = parseStatus(result.stdout);
    if (result.code !== 0 && parsed.ok) {
      return { ...parsed, ok: false, error: parsed.error || "helper_failed" };
    }
    return parsed;
  } catch {
    if (signal?.aborted) {
      return fail("aborted");
    }
    return fail("helper_failed");
  }
}
