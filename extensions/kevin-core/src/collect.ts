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

export const STATUS_TIMEOUT_MS = 12_000;

const FORBIDDEN = [
  /C:\\Users/i,
  /hessm/i,
  /:18789\b/,
  /127\.0\.0\.1/,
  /xai-[A-Za-z0-9]{8,}/,
  /ghp_[A-Za-z0-9]{8,}/,
];

function isoNow(): string {
  return new Date().toISOString();
}

function fail(error: string): Status {
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

export function sanitizeStatus(data: Status): Status {
  const next = { ...data };
  if (FORBIDDEN.some((re) => re.test(next.gpu_name))) {
    next.gpu_name = "gpu";
  }
  if (FORBIDDEN.some((re) => re.test(next.error))) {
    next.error = "redacted";
  }
  return next;
}

export function parseStatus(stdout: string): Status {
  const text = stdout.trim();
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) {
    return fail("invalid_json");
  }
  let raw: unknown;
  try {
    raw = JSON.parse(text.slice(start, end + 1));
  } catch {
    return fail("invalid_json");
  }
  if (!raw || typeof raw !== "object") {
    return fail("invalid_json");
  }
  const o = raw as Record<string, unknown>;
  const num = (key: string): number => {
    const v = o[key];
    return typeof v === "number" && Number.isFinite(v) ? v : 0;
  };
  const str = (key: string): string => (typeof o[key] === "string" ? (o[key] as string) : "");
  return sanitizeStatus({
    ok: o.ok === true,
    collected_at: str("collected_at") || isoNow(),
    ram_used_gb: num("ram_used_gb"),
    ram_total_gb: num("ram_total_gb"),
    ram_load_percent: num("ram_load_percent"),
    cpu_percent: num("cpu_percent"),
    gpu_name: str("gpu_name") || "unavailable",
    gpu_percent: num("gpu_percent"),
    vram_used_mb: num("vram_used_mb"),
    vram_total_mb: num("vram_total_mb"),
    disk_free_gb: num("disk_free_gb"),
    ollama_status: str("ollama_status") || "unknown",
    gateway_status: str("gateway_status") || "unknown",
    error: str("error"),
  });
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
      parsed.ok = false;
      parsed.error = parsed.error || "helper_failed";
    }
    return parsed;
  } catch {
    if (signal?.aborted) {
      return fail("aborted");
    }
    return fail("helper_failed");
  }
}
