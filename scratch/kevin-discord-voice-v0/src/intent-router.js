"use strict";

const INTENT = {
  FOLLOW: "follow",
  STOP: "stop",
  GUARD: "guard",
  COME: "come",
  STATUS: "status",
  SAY: "say",
  JOIN_VC: "join_vc",
  LEAVE_VC: "leave_vc",
  UNKNOWN: "unknown",
};

const PATTERNS = [
  { name: INTENT.FOLLOW, re: /\b(follow|stay\s*close|with\s*me)\b/i },
  { name: INTENT.STOP, re: /\b(stop|halt|stand\s*down|cancel|afk)\b/i },
  { name: INTENT.GUARD, re: /\b(guard|protect|defend|watch\s*(my)?\s*back)\b/i },
  { name: INTENT.COME, re: /\b(come|come\s*here|to\s*me|here)\b/i },
  { name: INTENT.STATUS, re: /\b(status|where\s*are\s*you|ping|health)\b/i },
  { name: INTENT.JOIN_VC, re: /\b(join\s*(vc|voice)|enter\s*voice)\b/i },
  { name: INTENT.LEAVE_VC, re: /\b(leave\s*(vc|voice)|disconnect\s*voice)\b/i },
];

function stripPrefix(text, prefix) {
  const t = String(text || "").trim();
  const p = String(prefix || "!k").trim();
  if (!p) return t;
  if (t.toLowerCase().startsWith(p.toLowerCase())) {
    return t.slice(p.length).trim().replace(/^[:\-,]+/, "").trim();
  }
  return t;
}

function parseIntent(text, opts = {}) {
  const prefix = opts.prefix != null ? opts.prefix : "!k";
  const raw = String(text || "").trim();
  const body = stripPrefix(raw, prefix);
  const lower = body.toLowerCase();

  if (/^say\b/i.test(body) || /^chat\b/i.test(body)) {
    const msg = body.replace(/^(say|chat)\s+/i, "").trim();
    return { name: INTENT.SAY, raw, body, args: { message: msg } };
  }

  for (const p of PATTERNS) {
    if (p.re.test(body)) {
      return { name: p.name, raw, body, args: {} };
    }
  }

  // Bare "kevin ..." without known verb stays unknown (wake later)
  if (/^kevin\b/i.test(lower) && body.split(/\s+/).length <= 1) {
    return { name: INTENT.UNKNOWN, raw, body, args: {}, note: "wake_only" };
  }

  return { name: INTENT.UNKNOWN, raw, body, args: {} };
}

module.exports = { INTENT, parseIntent, stripPrefix };
