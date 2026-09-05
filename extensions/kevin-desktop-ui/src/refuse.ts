import { catalogControlIds } from "./catalog.js";

export const ENABLE_ENV = "KEVIN_DESKTOP_UI_ENABLE";
export const ALLOWED_APPS = new Set(["calculator"]);
export const MAX_TYPE_LEN = 64;

/** password/passwd/secret/api_key/token/bearer/AKIA patterns */
export const SECRET_RE =
  /(password|passwd|secret|api[_-]?key|token|bearer\s+[A-Za-z0-9._\-]{8,}|AKIA[0-9A-Z]{16})/i;

export type GateResult =
  | { ok: true; enabled: true }
  | {
      ok: false;
      error:
        | "disabled_by_default"
        | "invalid_app"
        | "invalid_control"
        | "secret_deny"
        | "text_too_long";
      hint?: string;
      app?: string;
      control_id?: string;
      length?: number;
      max?: number;
    };

export function isEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
  return (env[ENABLE_ENV] ?? "").trim() === "1";
}

export function gate(opts: {
  app?: string;
  control_id?: string;
  text?: string | null;
  env?: NodeJS.ProcessEnv;
}): GateResult {
  const env = opts.env ?? process.env;
  if (!isEnabled(env)) {
    return {
      ok: false,
      error: "disabled_by_default",
      hint: `set ${ENABLE_ENV}=1 for isolated candidate only`,
    };
  }
  const app = opts.app ?? "";
  if (app && !ALLOWED_APPS.has(app)) {
    return { ok: false, error: "invalid_app", app };
  }
  const controlId = opts.control_id ?? "";
  if (controlId && !catalogControlIds().has(controlId)) {
    return { ok: false, error: "invalid_control", app, control_id: controlId };
  }
  if (opts.text !== undefined && opts.text !== null) {
    const text = opts.text;
    if (SECRET_RE.test(text)) {
      return { ok: false, error: "secret_deny", length: text.length };
    }
    if (text.length > MAX_TYPE_LEN) {
      return {
        ok: false,
        error: "text_too_long",
        length: text.length,
        max: MAX_TYPE_LEN,
      };
    }
  }
  return { ok: true, enabled: true };
}
