import { gate, type GateResult } from "./refuse.js";

export type UiResult =
  | GateResult
  | { ok: false; error: "candidate_no_live_uia"; note?: string };

export function focusApp(app: string): UiResult {
  const g = gate({ app });
  if (!g.ok) return g;
  return {
    ok: false,
    error: "candidate_no_live_uia",
    note: "use scratch prove or ENABLE+harness; not Chat",
  };
}

export function clickControl(app: string, control_id: string): UiResult {
  const g = gate({ app, control_id });
  if (!g.ok) return g;
  return { ok: false, error: "candidate_no_live_uia" };
}

export function typeText(app: string, text: string): UiResult {
  const g = gate({ app, text });
  if (!g.ok) return g;
  return { ok: false, error: "candidate_no_live_uia" };
}
