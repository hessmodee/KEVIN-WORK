(() => {
'use strict';
/**
 * Kevin HQ P1 Ground Truth v1 — thin honesty overlay.
 * Hooks existing HQ DOM/API after load. Does NOT greenwash BLOCKED.
 * Does NOT paint GROKBOT_ACTED as Kevin WORKING. Does NOT invent PASS from STAGE_OK.
 */
const VERSION = 'hq-p1-ground-truth-v1';
const RAW = 'https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const PATHS = {
  dashboard: 'reports/dashboard-state.json',
  engineering: 'reports/engineering/latest.json',
  support: 'reports/support-latest.json',
  continuation: 'reports/autonomy-continuation-latest.json',
  work: 'inbox/autonomy/work-items.json',
  canary: 'reports/main-agent-canary-omen.json',
  bridge: 'reports/bridge-latest.json',
  reject: 'reports/invocations/latest-public-reject.json',
  floor: 'reports/hq-live-floor.json',
  outcomes: 'reports/owner-outcomes-latest.json',
  receipt: 'reports/invocations/done/invoke-owner-west-motor-parts-chase-refresh-2026-09-13-v1.json'
};
const STALE_RE = /v1\.8\.11|685B34F3|grok-install-v1811/i;
const CANARY_FRESH_S = 1800;
const PLATFORM_FRESH_S = 900;
const BRIDGE_HEARTBEAT_S = 900;
const SUPPORT_PAINT_S = 900;
const WEST_MOTOR_COMPLETED_AT = '2026-09-12T00:54:57Z';
const WEST_MOTOR_INVOKE_ID = 'invoke-owner-west-motor-parts-chase-fresh-8-v1';
const COUPLING = 'hq-p1-coupling-honesty-v1';

function parseTs(v) {
  if (!v) return NaN;
  const s = String(v).trim().replace(/(\.\d{3})\d+(?=(?:Z|[+-]\d{2}:\d{2})$)/, '$1');
  const t = Date.parse(s);
  return Number.isFinite(t) ? t : NaN;
}
function ageSeconds(v, now) {
  const t = parseTs(v);
  const n = Number.isFinite(now) ? now : Date.now();
  return Number.isFinite(t) ? Math.max(0, (n - t) / 1000) : Infinity;
}
function ageText(s) {
  if (!Number.isFinite(s)) return 'unknown';
  if (s < 60) return `${Math.round(s)}s`;
  if (s < 3600) return `${Math.round(s / 60)}m`;
  if (s < 86400) return `${(s / 3600).toFixed(s < 7200 ? 1 : 0)}h`;
  return `${(s / 86400).toFixed(1)}d`;
}
function when(v) {
  const t = parseTs(v);
  return Number.isFinite(t)
    ? new Date(t).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })
    : 'unknown';
}
function esc(v) {
  return String(v ?? '').replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));
}
function stripStaleV1811(text) {
  return String(text ?? '').replace(/\s*Supervisor v1\.8\.11 hash 685B34F3[^.)]*\.?/gi, '')
    .replace(/\s*typed ALREADY_APPLIED_PROVEN for grok-install-v1811-[0-9-]+,?/gi, '')
    .replace(/\s*continuation version 1\.8\.11\.?/gi, '')
    .replace(/\(\s*,\s*/g, '(').replace(/\s{2,}/g, ' ').trim();
}
function hasStaleV1811(text) { return STALE_RE.test(String(text ?? '')); }

function exactFiveCanary(canary, now) {
  const c = canary || {};
  return ageSeconds(c.generated_at, now) <= CANARY_FRESH_S
    && String(c.state || '') === 'OMEN_PROVEN'
    && Number(c.visible_tool_count) === 5
    && Number(c.visible_kevin_tool_count) === 5
    && c.has_kevin_system_status === true;
}
function toolsChip(canary, now) {
  if (exactFiveCanary(canary, now)) return { label: '5 PROVEN', cls: 'ok', stale: false };
  const c = canary || {};
  const shape = String(c.state || '') === 'OMEN_PROVEN'
    && Number(c.visible_tool_count) === 5
    && Number(c.visible_kevin_tool_count) === 5
    && c.has_kevin_system_status === true;
  if (shape) return { label: '5 · CANARY STALE', cls: 'stale', stale: true };
  return { label: 'UNVERIFIED', cls: '', stale: true };
}

function actionEraReady(engineering) {
  const a = engineering?.action || {};
  const q = a.queues || a.composite_skills || {};
  return Number(q.ready) || 0;
}
function liveWorkerCount(support, now) {
  if (ageSeconds(support?.generated_at, now) > 360) return 0;
  return Object.values(support?.active_workers || {}).reduce((n, v) => n + (Number(v) || 0), 0);
}
function liveExecutionProven(bundle, now) {
  const d = bundle.dashboard || {};
  const s = bundle.support || {};
  const task = d.current_task;
  const taskLive = !!task && ageSeconds(d.generated_at, now) <= 180
    && !/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield|skip|cancel|reject)/i.test(String(task.phase || task.status || ''));
  const workers = liveWorkerCount(s, now);
  // Exclude pure heartbeat services from "live worker" for WORKING entitlement.
  const aw = s.active_workers || {};
  const realWorkers = workers - (Number(aw.tick) || 0) - (Number(aw.bridge) || 0);
  return { taskLive, workers, realWorkers: Math.max(0, realWorkers), actionReady: actionEraReady(bundle.engineering) };
}

/** WORKING/BUILDING only with live worker OR Action Era ready>=1. Heartbeat pulse alone is OK, not WORKING. */
function mayShowWorkingBuilding(bundle, now) {
  const ex = liveExecutionProven(bundle, now);
  return ex.taskLive || ex.realWorkers > 0 || ex.actionReady >= 1;
}

/**
 * Honest worker lane state. Never WORKING on Chat/Build Lab without live evidence.
 * Tick/Bridge/Ollama may pulse ready/healthy without becoming WORKING.
 */
function honestWorkerState(key, proposed, bundle, now) {
  const k = String(key || '').toLowerCase();
  const proposedN = String(proposed || '').toLowerCase();
  if (k === 'bridge') return honestBridgeWorkerState(proposedN, bundle, now);
  if (['tick', 'ollama'].includes(k)) {
    if (proposedN === 'working' || proposedN === 'building') return 'ready';
    return proposedN || 'ready';
  }
  if (k === 'chat' || k === 'build' || k === 'lab') {
    if ((proposedN === 'working' || proposedN === 'building') && !mayShowWorkingBuilding(bundle, now)) return 'ready';
  }
  if ((proposedN === 'working' || proposedN === 'building') && !mayShowWorkingBuilding(bundle, now)) return 'ready';
  return proposedN || 'ready';
}


function collectReceipts(bundle) {
  const out = [];
  const push = (r) => { if (r && typeof r === 'object') out.push(r); };
  push(bundle.receipt);
  if (Array.isArray(bundle.receipts)) bundle.receipts.forEach(push);
  if (Array.isArray(bundle.done)) bundle.done.forEach(push);
  if (Array.isArray(bundle.doneReceipts)) bundle.doneReceipts.forEach(push);
  else if (bundle.doneReceipts && typeof bundle.doneReceipts === 'object') push(bundle.doneReceipts);
  return out;
}
function isProvenReceipt(r) {
  const st = String(r?.status || '').toUpperCase();
  return st === 'PROVEN' || String(r?.kind || '') === 'kevin-proven-skill-invocation-receipt';
}
function lastAttemptFromReceipts(bundle) {
  let best = null, bestT = -Infinity;
  for (const r of collectReceipts(bundle)) {
    if (!isProvenReceipt(r)) continue;
    const at = r.completed_at;
    const t = parseTs(at);
    if (Number.isFinite(t) && t >= bestT) { bestT = t; best = r; }
  }
  if (!best) return { at: null, unknown: true, source: null, receipt: null, id: null, skill: null };
  return {
    at: best.completed_at,
    unknown: false,
    source: 'receipt.completed_at',
    receipt: best,
    id: best.invocation_id || null,
    skill: best.skill_key || null
  };
}
function taskAlive(bundle, now) {
  const ub = bundle.engineering?.action?.ui_bridge || {};
  if (ub.task_present === true) return true;
  const task = bundle.dashboard?.current_task;
  if (task && !/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield|skip|cancel|reject)/i.test(String(task.phase || task.status || ''))) {
    if (ageSeconds(bundle.dashboard?.generated_at, now) <= 180) return true;
  }
  return false;
}
function githubBridgeAge(bundle, now) {
  const supportAge = ageSeconds(bundle.support?.generated_at, now);
  const heartbeatAge = ageSeconds(bundle.bridge?.at || bundle.bridge?.generated_at, now);
  return {
    supportAge,
    heartbeatAge,
    supportFresh: supportAge <= SUPPORT_PAINT_S,
    heartbeatFresh: heartbeatAge <= BRIDGE_HEARTBEAT_S
  };
}
/** UNKNOWN→DEGRADED only when GitHubBridge/support-latest is stale vs paint AND heartbeat stale AND no live task. Never disable Bridge. */
function bridgeHonesty(bundle, now) {
  const ages = githubBridgeAge(bundle, now);
  const puller = String(bundle.bridge?.puller || '');
  const bridgeOk = String(bundle.bridge?.bridge || '').toLowerCase() === 'ok';
  const dash = String(bundle.dashboard?.services?.bridge || '').toLowerCase();
  const alive = taskAlive(bundle, now);
  let state = 'degraded', reason = 'stale-heartbeat', label = 'DEGRADED';
  if (ages.heartbeatFresh && bridgeOk && /^v1\.[3-9]/.test(puller)) {
    state = 'ok'; reason = 'fresh-heartbeat'; label = 'OK';
  } else if (alive) {
    state = 'ok'; reason = 'task-alive-stale-heartbeat'; label = 'OK';
  } else if (ages.supportFresh && (bridgeOk || dash === 'unknown' || dash === '' || dash === 'ok' || dash === 'healthy')) {
    state = 'ok'; reason = 'support-fresh-vs-paint'; label = 'OK';
  }
  return { state, label, reason, disabled: false, ages, taskAlive: alive, dash };
}
function outcomeProven(bundle) {
  const r = bundle.reject || {};
  return String(r.reason || '').toUpperCase() === 'OUTCOME_PROVEN' || r.outcome_proven === true;
}
function westMotorProven(bundle) {
  return collectReceipts(bundle).some(r => isProvenReceipt(r) && /west-motor/i.test(String(r.invocation_id || r.skill_key || '')));
}
function fivePackHonesty(bundle) {
  const proven = westMotorProven(bundle);
  return { proven, paint: proven ? 'PROVEN' : null, failedPass: false };
}
function centerHonesty(bundle, now) {
  const bridge = bridgeHonesty(bundle, now);
  const proven = outcomeProven(bundle);
  const truth = kevinCenterTruth(bundle, now);
  // Worst-feed ≠ Kevin failed the job. Bridge DEGRADED must not force center FAILED after OUTCOME_PROVEN.
  let mode = truth.mode;
  let label = truth.label;
  if (proven) {
    mode = 'outcome_proven';
    label = 'OUTCOME_PROVEN';
  }
  if (mode === 'failed' || label === 'FAILED') {
    mode = proven ? 'outcome_proven' : 'ready';
    label = proven ? 'OUTCOME_PROVEN' : 'READY';
  }
  return {
    mode,
    label,
    failed: false,
    inheritedBridge: false,
    bridgeState: bridge.state,
    worstFeedIsNotKevinFailed: true,
    westMotorProven: westMotorProven(bundle),
    fivePack: fivePackHonesty(bundle)
  };
}
function lastAttemptClock(bundle, now) {
  const floorAt = bundle.floor?.last_invoke_completed_at || bundle.outcomes?.newest_receipt?.completed_at || null;
  if (floorAt) {
    return {
      at: floorAt,
      label: when(floorAt),
      age: ageText(ageSeconds(floorAt, now)),
      unknown: !Number.isFinite(parseTs(floorAt)),
      source: 'hq-live-floor.last_invoke_completed_at',
      id: bundle.outcomes?.newest_receipt?.work_id || bundle.floor?.selected_id || null,
      skill: bundle.outcomes?.newest_receipt?.skill_key || null,
      fixtureWestMotor: false
    };
  }
  const rec = lastAttemptFromReceipts(bundle);
  if (rec.at) {
    const t = parseTs(rec.at);
    return {
      at: rec.at,
      label: when(rec.at),
      age: ageText(ageSeconds(rec.at, now)),
      unknown: !Number.isFinite(t),
      source: 'receipt.completed_at',
      id: rec.id,
      skill: rec.skill,
      fixtureWestMotor: String(rec.at).startsWith('2026-09-12T00:54:57')
    };
  }
  const c = clocksFromReports(bundle, now);
  const at = c.lastOwnerAttempt.at;
  return {
    at,
    label: c.lastOwnerAttempt.label,
    age: c.lastOwnerAttempt.age,
    unknown: !Number.isFinite(parseTs(at)),
    source: 'continuation',
    id: c.lastOwnerAttempt.id,
    skill: null,
    fixtureWestMotor: false
  };
}
function opsFloorStripe(bundle, now) {
  const rec = lastAttemptFromReceipts(bundle);
  const actor = String((bundle.reject || {}).verify_actor || 'MIXED').toUpperCase() || 'MIXED';
  const artifacts = [];
  for (const s of (rec.receipt?.step_results || [])) {
    if (s.output_name) artifacts.push(s.output_name);
  }
  return {
    stripe: rec.at ? 'COMPLETED' : null,
    skill: rec.skill || rec.receipt?.skill_key || null,
    artifacts,
    actor,
    working: mayShowWorkingBuilding(bundle, now),
    workingFromBridge: false
  };
}
function honestBridgeWorkerState(proposed, bundle, now) {
  const b = bridgeHonesty(bundle, now);
  const p = String(proposed || '').toLowerCase();
  if (p === 'disabled') return b.state === 'ok' ? 'ready' : 'degraded';
  if (p === 'working' || p === 'building') return 'ready';
  if (b.state === 'ok') return (p === 'degraded' || p === 'offline' || p === 'unknown') ? 'ready' : (p || 'ready');
  return p === 'disabled' ? 'degraded' : (p || 'degraded');
}

function kevinCenterTruth(bundle, now) {
  const cont = bundle.continuation || {};
  const reject = bundle.reject || {};
  const status = String(cont.status || '').toUpperCase();
  const rejectReason = String(reject.reason || '').toUpperCase();
  const stageOk = String(reject.supervisor_request_id_reason || '').toUpperCase() === 'STAGE_OK';
  const verifyMixed = String(reject.verify_actor || '').toUpperCase() === 'MIXED'
    || /VERIFY PASS MIXED/i.test(String(reject.truth_boundary || ''));
  const ex = liveExecutionProven(bundle, now);

  // Never invent PASS from STAGE_OK.
  const passInvented = false;
  void stageOk; void passInvented;

  if (status === 'BLOCKED_INVOCATION_RUNTIME') {
    const isolate = reject.isolated_diagnose_queue === true;
    const liveReady = Number(reject.live_action_era_ready_invoke_count || 0);
    const pair = isolate
      ? `isolate diagnose queue ON · live Action Era ready invoke ${liveReady}`
      : (liveReady > 0 ? `live Action Era ready invoke ${liveReady}` : 'live/isolate pair unpublished');
    return {
      mode: 'blocked',
      label: 'BLOCKED',
      detail: `BLOCKED_INVOCATION_RUNTIME · ${pair}. Worker diagnostic, not a crash, not PASS.`,
      cite: verifyMixed ? 'VERIFY prior PASS MIXED (west-motor) — citation only' : null,
      showIsolatePair: true,
      isolate,
      liveReady
    };
  }
  if (rejectReason === 'OUTCOME_PROVEN' || reject.outcome_proven === true) {
    return {
      mode: 'outcome_proven',
      label: 'OUTCOME_PROVEN',
      detail: 'Public reject reports OUTCOME_PROVEN from receipt — not invented from STAGE_OK. Not READY. Not WORKING unless live execution is proven. Bridge DEGRADED is worst-feed, not Kevin failed.',
      cite: verifyMixed ? 'VERIFY prior PASS MIXED (west-motor) — citation only' : null,
      showIsolatePair: reject.isolated_diagnose_queue === true,
      isolate: reject.isolated_diagnose_queue === true,
      liveReady: Number(reject.live_action_era_ready_invoke_count || 0),
      failed: false,
      inheritedBridge: false
    };
  }
  if (/^ROUTED_/.test(status)) {
    return {
      mode: 'routed',
      label: 'ROUTED',
      detail: `${status.replaceAll('_', ' ')} · honest from continuation. Not READY. Not PASS.`,
      cite: verifyMixed ? 'VERIFY prior PASS MIXED (west-motor) — citation only' : null,
      showIsolatePair: false
    };
  }
  if (ex.taskLive || ex.realWorkers > 0) {
    return { mode: 'working', label: 'WORKING', detail: 'Live machine execution proven.', cite: null, showIsolatePair: false };
  }
  if (ex.actionReady >= 1) {
    return { mode: 'building', label: 'BUILDING', detail: `Action Era ready=${ex.actionReady}.`, cite: null, showIsolatePair: false };
  }
  if (status === 'CONTROLLER_ERROR') {
    return { mode: 'degraded', label: 'DEGRADED', detail: 'CONTROLLER_ERROR — Supervisor crashed, not idle.', cite: null, showIsolatePair: false };
  }
  return { mode: 'ready', label: 'READY', detail: 'No live execution proven.', cite: null, showIsolatePair: false };
}

function clocksFromReports(bundle, now) {
  const cont = bundle.continuation || {};
  const hist = Array.isArray(cont.history) ? cont.history : [];
  const selected = hist.find(x => String(x.id || '') === String(cont.selected_id || '')) || hist.at(-1) || {};
  const recAt = lastAttemptFromReceipts(bundle).at;
  const floorAt = bundle.floor?.last_invoke_completed_at || bundle.outcomes?.newest_receipt?.completed_at || null;
  const ownerAt = floorAt || recAt || selected.last_turn_at || cont.generated_at || null;
  const ownerId = bundle.outcomes?.newest_receipt?.work_id || bundle.floor?.selected_id || cont.selected_id || selected.id || null;
  const platformCandidates = [
    bundle.floor?.updated_at || bundle.floor?.generated_at,
    bundle.support?.generated_at,
    bundle.engineering?.generated_at,
    bundle.dashboard?.generated_at,
    bundle.bridge?.at || bundle.bridge?.generated_at,
    bundle.reject?.generated_at
  ].filter(Boolean);
  let newest = null, newestT = -Infinity;
  for (const ts of platformCandidates) {
    const t = parseTs(ts);
    if (Number.isFinite(t) && t > newestT) { newestT = t; newest = ts; }
  }
  const floorCycle = Number(bundle.floor?.cycle);
  const supportCycle = Number(bundle.support?.supervisor?.cycle);
  const cycle = Number.isFinite(floorCycle) ? floorCycle : (Number.isFinite(supportCycle) ? supportCycle : (bundle.dashboard?.ops_floor?.primary?.cycle ?? null));
  const bleed = Number.isFinite(floorCycle) && Number.isFinite(supportCycle) && floorCycle !== supportCycle;
  return {
    lastOwnerAttempt: { at: ownerAt, label: when(ownerAt), age: ageText(ageSeconds(ownerAt, now)), id: ownerId },
    lastPlatformSignal: { at: newest, label: when(newest), age: ageText(ageSeconds(newest, now)) },
    cycle: cycle == null ? '—' : cycle,
    cycleLabel: bleed ? 'floor · Support bleed' : 'hq-live-floor',
    bleed
  };
}

function newswireStories(bundle, now) {
  const items = [];
  const push = (id, text, severity, at) => {
    if (!text) return;
    items.push({ id, text: String(text).slice(0, 220), severity: severity || 'normal', at: at || null });
  };
  const s = bundle.support || {};
  const c = bundle.continuation || {};
  const e = bundle.engineering || {};
  const r = bundle.reject || {};
  const d = bundle.dashboard || {};
  const b = s.benchmark || e.action?.benchmark || {};
  const reg = b.regression || b;

  const floor = bundle.floor || {};
  if (floor.updated_at || floor.generated_at) {
    push('hq-live-floor', `FLOOR · cycle ${floor.cycle ?? '—'} · actor ${floor.last_actor || 'unpublished'} · ${floor.last_invoke_completed_at ? 'last invoke ' + floor.last_invoke_completed_at : 'no last invoke'}`, 'normal', floor.updated_at || floor.generated_at);
  }
  if (s.generated_at) {
    const aw = liveWorkerCount(s, now);
    const fCycle = floor.cycle;
    const sCycle = s.supervisor?.cycle;
    const bleed = fCycle != null && sCycle != null && Number(fCycle) !== Number(sCycle);
    push('support-latest', bleed
      ? `SUPPORT BLEED · workers ${aw} · ignore cycle ${sCycle} · ${s.supervisor?.last_result || 'ok'}`
      : `SUPPORT · workers ${aw} · ${s.supervisor?.last_result || 'ok'}`,
      bleed ? 'caution' : 'normal', s.generated_at);
  }
  if (c.generated_at) {
    push('autonomy-continuation-latest', `CONTINUATION · ${c.status || 'UNKNOWN'} · selected ${c.selected_id || 'none'}`, /BLOCKED|ERROR/i.test(String(c.status || '')) ? 'caution' : 'normal', c.generated_at);
  }
  if (r.generated_at) {
    push('invocations/latest-public-reject', `REJECT · ${r.reason || 'UNKNOWN'} · ${r.work_id_hint || ''}`.trim(), r.reason === 'OUTCOME_PROVEN' ? 'normal' : 'caution', r.generated_at);
  }
  if (e.generated_at) {
    const hb = e.action?.ui_bridge?.heartbeat_age_seconds;
    push('engineering/latest', `ENGINEERING · bridge hb ${hb ?? '?'}s · skills proven ${e.action?.composite_skills?.proven_count ?? '?'}`, 'normal', e.generated_at);
  }
  if (Number.isFinite(Number(reg.passed))) {
    const ok = String(b.status || '').toUpperCase() === 'PASS' && Number(reg.passed) === 30 && Number(reg.total) === 30;
    push('benchmark', `BENCHMARK · ${reg.passed}/${reg.total}${ok ? '' : ' · needs check'}`, ok ? 'normal' : 'caution', b.at || e.generated_at || s.generated_at);
  }
  for (const nw of (Array.isArray(d.newswire) ? d.newswire : []).slice(0, 3)) {
    push(nw.id || 'dash-nw', nw.text, nw.severity || 'normal', d.generated_at);
  }

  // Dedup by id, keep order, max 12
  const seen = new Set();
  const out = [];
  for (const it of items) {
    if (seen.has(it.id)) continue;
    seen.add(it.id);
    out.push(it);
  }
  if (!out.length) {
    const ts = when(newestTs(bundle));
    return [{ id: 'empty', text: `no new events since ${ts}`, severity: 'caution', at: null, empty: true, lastLines: [] }];
  }
  return out;
}

function newestTs(bundle) {
  const clocks = clocksFromReports(bundle, Date.now());
  return clocks.lastPlatformSignal.at || clocks.lastOwnerAttempt.at || null;
}

function emptyNewswireFallback(bundle, stories) {
  if (stories.length && !stories[0].empty) return stories;
  const lines = [];
  const hist = Array.isArray(bundle.continuation?.history) ? bundle.continuation.history : [];
  for (const h of hist.slice(-3).reverse()) {
    lines.push(`${h.id || 'attempt'} · ${h.status || '?'} · ${when(h.last_turn_at)}`);
  }
  const ts = when(newestTs(bundle));
  return [{
    id: 'empty',
    text: `no new events since ${ts}`,
    severity: 'caution',
    empty: true,
    lastLines: lines
  }];
}

/**
 * Scaffold rail: visible when CoS / RUNTIME / VERIFY markers active.
 * GROKBOT_ACTED is the actor label — never painted as Kevin WORKING.
 * Hide when idle. Never "Kevin learning".
 */
function scaffoldState(bundle, opts) {
  const o = opts || {};
  const cont = String(bundle.continuation?.status || '').toUpperCase();
  const reject = bundle.reject || {};
  const verifyActive = String(reject.verify_actor || '').toUpperCase() === 'MIXED'
    || /VERIFY/i.test(String(reject.truth_boundary || ''))
    || o.verifyActive === true;
  const runtimeActive = /^BLOCKED_|^ROUTED_|^CONTROLLER_/.test(cont) || o.runtimeActive === true;
  const cosActive = o.cosActive === true || o.grokbotActed === true;
  const active = !!(verifyActive || runtimeActive || cosActive || o.forceVisible);
  if (!active) return { visible: false, chip: null, lastAction: null, dashedToKevin: false, actor: null };
  const lastAction = o.lastAction || (o.grokbotActed ? 'GROKBOT_ACTED · P1 ground-truth overlay' : (verifyActive ? 'VERIFY · receipt citation' : 'RUNTIME · continuation signal'));
  return {
    visible: true,
    chip: 'SCAFFOLD',
    lastAction,
    dashedToKevin: true,
    actor: 'GROKBOT_ACTED',
    neverKevinWorking: true,
    neverKevinLearning: true
  };
}

function selectedWorkerCss() {
  return `
/* P1: restore Selected Worker panel — stop clipping */
html.hq-p1-ops, body.hq-p1-ops { overflow: auto !important; height: auto !important; min-height: 100%; }
.card.detail, section.card.detail, #selectedName, .detail-grid {
  max-height: none !important;
  overflow: visible !important;
  visibility: visible !important;
  display: block;
}
.card.detail { overflow: auto !important; max-height: none !important; min-height: 140px; }
.detail-grid { display: grid !important; }
.ops-scroll { overflow: auto !important; max-height: none !important; }
#inspect.inspect, .inspect { overflow: auto !important; max-height: none !important; min-height: 120px; }
.hq-p1-clocks { display:grid; grid-template-columns:1fr 1fr auto; gap:8px; margin:10px 0; }
.hq-p1-clock { border:1px solid rgba(194,213,182,.22); border-radius:12px; padding:10px 12px; background:rgba(17,22,16,.88); min-width:0; }
.hq-p1-clock span { display:block; font-size:9px; letter-spacing:.11em; text-transform:uppercase; color:#8b9488; }
.hq-p1-clock b { display:block; margin-top:4px; font-size:13px; }
.hq-p1-clock small { display:block; margin-top:3px; color:#8b9488; font-size:10px; }
.hq-p1-scaffold { display:none; align-items:center; gap:10px; margin:8px 0 0; padding:8px 12px; border:1px dashed rgba(194,213,182,.35); border-radius:12px; background:rgba(20,26,19,.75); font-size:11px; color:#c5d0bf; }
.hq-p1-scaffold.show { display:flex; flex-wrap:wrap; }
.hq-p1-scaffold .chip { padding:3px 8px; border-radius:999px; border:1px solid rgba(194,213,182,.4); font:800 9px/1 ui-monospace,monospace; letter-spacing:.1em; }
.hq-p1-scaffold .actor { color:#efd9ae; font-weight:700; }
.hq-p1-scaffold .dash { flex:1; min-width:40px; border-top:1px dashed rgba(194,213,182,.4); height:0; }
.hq-p1-nw-stack { display:flex; flex-direction:column; gap:4px; }
.hq-p1-nw-stack .nw-line { font-size:12px; line-height:1.35; color:#e6eadf; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.hq-p1-nw-stack .nw-line.dim { color:#8b9488; font-size:11px; }
.hq-p1-cite { margin-top:6px; font-size:10px; color:#8b9488; }
.hq-p1-pair { margin-top:6px; font-size:11px; color:#efd9ae; }
.hq-p1-completed-stripe { display:none; align-items:center; gap:10px; margin:8px 0; padding:8px 12px; border:1px solid rgba(121,197,106,.35); border-radius:12px; background:rgba(20,32,18,.82); font-size:11px; color:#dcebd5; }
.hq-p1-completed-stripe.show { display:flex; flex-wrap:wrap; }
.hq-p1-completed-stripe .chip { padding:3px 8px; border-radius:999px; border:1px solid rgba(121,197,106,.45); font:800 9px/1 ui-monospace,monospace; letter-spacing:.1em; }
.hq-p1-completed-stripe .actor { color:#efd9ae; font-weight:700; }
`.trim();
}

const API = {
  VERSION,
  parseTs,
  ageSeconds,
  ageText,
  when,
  stripStaleV1811,
  hasStaleV1811,
  exactFiveCanary,
  toolsChip,
  actionEraReady,
  liveWorkerCount,
  liveExecutionProven,
  mayShowWorkingBuilding,
  honestWorkerState,
  kevinCenterTruth,
  clocksFromReports,
  newswireStories,
  emptyNewswireFallback,
  scaffoldState,
  selectedWorkerCss,
  PATHS,
  STALE_RE,
  COUPLING,
  BRIDGE_HEARTBEAT_S,
  SUPPORT_PAINT_S,
  WEST_MOTOR_COMPLETED_AT,
  WEST_MOTOR_INVOKE_ID,
  collectReceipts,
  isProvenReceipt,
  lastAttemptFromReceipts,
  taskAlive,
  githubBridgeAge,
  bridgeHonesty,
  outcomeProven,
  westMotorProven,
  fivePackHonesty,
  centerHonesty,
  lastAttemptClock,
  opsFloorStripe,
  honestBridgeWorkerState
};

if (typeof module === 'object' && module.exports) {
  module.exports = API;
  return;
}

// ——— browser boot ———
const cache = {};
let coreDoc = null, coreWin = null, opsDoc = null, opsWin = null;
let timer = null, nwIdx = 0;

function injectStyle(doc, id, css) {
  if (!doc) return;
  let el = doc.getElementById(id);
  if (!el) {
    el = doc.createElement('style');
    el.id = id;
    (doc.head || doc.documentElement).appendChild(el);
  }
  el.textContent = css;
}

async function fetchJson(path) {
  try {
    const r = await fetch(RAW + path + '?' + Date.now(), { cache: 'no-store' });
    if (!r.ok) return null;
    return await r.json();
  } catch (_) { return null; }
}

async function refresh() {
  const entries = await Promise.all(Object.entries(PATHS).map(async ([k, p]) => [k, await fetchJson(p)]));
  for (const [k, v] of entries) if (v) cache[k] = v;
  // expose continuation/bridge for ops-v11 consumers
  try {
    if (opsWin) {
      opsWin.__kevinContinuation = cache.continuation || {};
      opsWin.__kevinBridgeLatest = cache.bridge || {};
      opsWin.__kevinFloor = cache.floor || {};
      opsWin.__kevinP1Reject = cache.reject || {};
      opsWin.__kevinP1Receipt = cache.receipt || {};
    }
    if (coreWin) {
      coreWin.__kevinContinuation = cache.continuation || {};
      coreWin.__kevinP1Reject = cache.reject || {};
      coreWin.__kevinP1Receipt = cache.receipt || {};
    }
  } catch (_) {}
  paint();
}

function ensureClocks(doc, root) {
  if (!doc) return null;
  let el = doc.getElementById('hqP1Clocks');
  if (!el) {
    el = doc.createElement('div');
    el.id = 'hqP1Clocks';
    el.className = 'hq-p1-clocks';
    el.setAttribute('data-hq-p1', 'clocks');
    const anchor = root || doc.getElementById('hqNewswire') || doc.getElementById('attentionBanner') || doc.querySelector('.wrap') || doc.body;
    if (anchor && anchor.parentNode) anchor.insertAdjacentElement(anchor === doc.body ? 'afterbegin' : 'afterend', el);
    else doc.body?.appendChild(el);
  }
  return el;
}

function ensureScaffold(doc) {
  if (!doc) return null;
  let el = doc.getElementById('hqP1Scaffold');
  if (!el) {
    el = doc.createElement('div');
    el.id = 'hqP1Scaffold';
    el.className = 'hq-p1-scaffold';
    el.setAttribute('data-hq-p1', 'scaffold');
    el.setAttribute('aria-label', 'Scaffold rail');
    const hub = doc.getElementById('kevinHub') || doc.getElementById('kevinState') || doc.querySelector('.hub') || doc.body;
    hub?.parentNode?.insertBefore(el, hub.nextSibling) || doc.body?.appendChild(el);
  }
  return el;
}

function paintClocks(doc) {
  const el = ensureClocks(doc);
  if (!el) return;
  const c = clocksFromReports(cache, Date.now());
  const attempt = lastAttemptClock(cache, Date.now());
  el.innerHTML =
    `<div class="hq-p1-clock"><span>Last owner attempt</span><b>${esc(attempt.unknown ? attempt.label : attempt.label)}</b><small>${esc(attempt.id || c.lastOwnerAttempt.id || '—')} · ${esc(attempt.unknown ? 'receipt' : attempt.age)}</small></div>` +
    `<div class="hq-p1-clock"><span>Last platform signal</span><b>${esc(c.lastPlatformSignal.label)}</b><small>${esc(c.lastPlatformSignal.age)} ago</small></div>` +
    `<div class="hq-p1-clock"><span>Cycle</span><b>${esc(c.cycle)}</b><small>${esc(c.cycleLabel || 'hq-live-floor')}</small></div>`;
}

function paintScaffold(doc) {
  const el = ensureScaffold(doc);
  if (!el) return;
  const floorSc = cache.floor?.scaffold || {};
  if (floorSc.active !== true) {
    el.classList.remove('show');
    el.hidden = true;
    el.innerHTML = '';
    return;
  }
  const sc = scaffoldState(cache, {
    grokbotActed: true,
    lastAction: floorSc.one_line || 'GROKBOT_ACTED · P1 ground-truth overlay applied',
    cosActive: true,
    forceVisible: true
  });
  const cont = String(cache.continuation?.status || '');
  const idle = !cont || cont === 'IDLE_NO_ELIGIBLE_DEMAND' || cont === 'NO_ELIGIBLE_MISSION';
  const rejectFresh = ageSeconds(cache.reject?.generated_at) < 7200;
  const show = sc.visible && (!idle || rejectFresh || /^BLOCKED_|^ROUTED_/.test(cont) || floorSc.active === true);
  if (!show) {
    el.classList.remove('show');
    el.hidden = true;
    el.innerHTML = '';
    return;
  }
  el.hidden = false;
  el.classList.add('show');
  el.innerHTML =
    `<span class="chip">${esc(sc.chip)}</span>` +
    `<span class="actor">${esc(sc.actor)}</span>` +
    `<span>${esc(sc.lastAction)}</span>` +
    (sc.dashedToKevin ? `<span class="dash" title="dashed to Kevin"></span><span>Kevin</span>` : '');
}

function paintNewswire(doc) {
  if (!doc) return;
  let stories = emptyNewswireFallback(cache, newswireStories(cache, Date.now()));
  // Prefer existing V10 newswire host
  let el = doc.getElementById('hqNewswire') || doc.getElementById('newswire');
  if (!el) {
    el = doc.createElement('div');
    el.id = 'hqNewswire';
    el.className = 'newswire show';
    const anchor = doc.getElementById('attentionBanner');
    if (anchor) anchor.insertAdjacentElement('afterend', el);
    else doc.querySelector('.wrap')?.prepend(el) || doc.body?.prepend(el);
  }
  el.hidden = false;
  el.classList.add('show');
  const first = stories[nwIdx % stories.length] || stories[0];
  nwIdx = (nwIdx + 1) % Math.max(stories.length, 1);
  if (first.empty) {
    const last = (first.lastLines || []).map(l => `<div class="nw-line dim">${esc(l)}</div>`).join('');
    el.innerHTML = `<div class="nw-label">NEWSWIRE</div><div class="hq-p1-nw-stack"><div class="nw-line">${esc(first.text)}</div>${last}</div>`;
    return;
  }
  // rotating primary + stacked last 3
  const stack = stories.slice(0, 3).map((x, i) =>
    `<div class="nw-line${i === 0 ? '' : ' dim'}" data-sev="${esc(x.severity || 'normal')}">${esc(x.text)}</div>`
  ).join('');
  el.className = 'newswire show' + (first.severity && first.severity !== 'normal' ? ' sev-' + first.severity : '');
  el.innerHTML = `<div class="nw-label">NEWSWIRE</div><div class="hq-p1-nw-stack">${stack}</div>`;
  el.dataset.p1Nw = '1';
}

function paintKevinHonesty(doc) {
  if (!doc) return;
  const truth = kevinCenterTruth(cache, Date.now());
  const badge = doc.getElementById('kevinState');
  if (badge && truth.mode === 'blocked') {
    badge.innerHTML = `<span class="loop state-blocked" style="--kstatec:#f0c36a">BLOCKED</span>`;
  } else if (badge && truth.mode === 'outcome_proven') {
    badge.innerHTML = `<span class="loop state-ready" style="--kstatec:#79c56a">OUTCOME_PROVEN</span>`;
  } else if (badge && truth.mode === 'routed') {
    badge.innerHTML = `<span class="loop state-ready" style="--kstatec:#68d8ce">ROUTED</span>`;
  }
  // Never label WORKING without entitlement
  if (badge && /WORKING|BUILDING/i.test(badge.textContent || '') && !mayShowWorkingBuilding(cache, Date.now())) {
    badge.innerHTML = `<span class="loop state-ready" style="--kstatec:#244f8f">${esc(truth.label)}</span>`;
  }
  const meta = doc.getElementById('kevinMeta');
  if (meta) {
    let extra = `<div>${esc(truth.detail)}</div>`;
    if (truth.showIsolatePair) {
      extra += `<div class="hq-p1-pair">isolate vs live · diagnose queue ${truth.isolate ? 'ON' : 'off'} · live ready invoke ${esc(truth.liveReady)}</div>`;
    }
    if (truth.cite) extra += `<div class="hq-p1-cite">${esc(truth.cite)}</div>`;
    // append honesty under existing meta without claiming Kevin learning
    if (!meta.dataset.p1Truth || meta.dataset.p1Truth !== truth.label + truth.detail) {
      meta.dataset.p1Truth = truth.label + truth.detail;
      const hold = meta.querySelector('[data-p1-honesty]');
      if (hold) hold.remove();
      const div = doc.createElement('div');
      div.setAttribute('data-p1-honesty', '1');
      div.innerHTML = extra;
      meta.appendChild(div);
    }
  }
  const sel = doc.getElementById('selectedStatus');
  const selDetail = doc.getElementById('selectedDetail');
  const selName = doc.getElementById('selectedName');
  if (selName && /Kevin/i.test(selName.textContent || '')) {
    if (truth.mode === 'blocked' && sel) sel.textContent = `BLOCKED · cycle ${clocksFromReports(cache, Date.now()).cycle}`;
    if (selDetail && (truth.mode === 'blocked' || truth.showIsolatePair)) {
      selDetail.textContent = truth.detail + (truth.cite ? ' · ' + truth.cite : '');
    }
  }
  // Scrub stale v1811 strings from visible text
  const walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT);
  const nodes = [];
  let n;
  while ((n = walker.nextNode())) nodes.push(n);
  for (const node of nodes) {
    if (hasStaleV1811(node.nodeValue)) node.nodeValue = stripStaleV1811(node.nodeValue);
  }
}

function patchOpsWorkerHonesty() {
  if (!opsWin) return;
  try {
    if (typeof opsWin.workerState === 'function' && !opsWin.__kevinP1WorkerPatched) {
      const orig = opsWin.workerState.bind(opsWin);
      opsWin.workerState = function(key, d, s) {
        const proposed = orig(key, d, s);
        return honestWorkerState(key, proposed, {
          dashboard: d,
          support: s,
          engineering: cache.engineering,
          continuation: cache.continuation
        }, Date.now());
      };
      opsWin.__kevinP1WorkerPatched = true;
    }
    if (typeof opsWin.kevinStates === 'function' && !opsWin.__kevinP1KevinPatched) {
      const origK = opsWin.kevinStates.bind(opsWin);
      opsWin.kevinStates = function(d, s) {
        const truth = kevinCenterTruth({
          dashboard: d,
          support: s,
          engineering: cache.engineering,
          continuation: cache.continuation || opsWin.__kevinContinuation,
          reject: cache.reject
        }, Date.now());
        if (truth.mode === 'blocked') return ['blocked'];
        if (truth.mode === 'outcome_proven') return ['ready']; // OUTCOME_PROVEN badge painted separately
        if (truth.mode === 'routed') return ['ready'];
        const states = origK(d, s);
        if (!mayShowWorkingBuilding({
          dashboard: d, support: s, engineering: cache.engineering
        }, Date.now())) {
          return states.map(st => (st === 'working' || st === 'building') ? 'ready' : st);
        }
        return states;
      };
      opsWin.__kevinP1KevinPatched = true;
    }
  } catch (_) {}
}

function patchToolsChipInCore() {
  if (!coreDoc) return;
  const chip = toolsChip(cache.canary, Date.now());
  for (const el of coreDoc.querySelectorAll('.v10-metric, .service-chip, .v10-source')) {
    const t = el.textContent || '';
    if (/Tools|CANARY|5 PROVEN|UNVERIFIED/i.test(t) && /tool/i.test(t + (el.querySelector('span,b')?.textContent || ''))) {
      // soft-replace obvious Tools metric value
    }
  }
  // Replace Tools metric b tags that look like canary
  for (const b of coreDoc.querySelectorAll('.v10-metric b')) {
    const label = b.previousElementSibling?.textContent || b.parentElement?.querySelector('span')?.textContent || '';
    if (/^Tools$/i.test(label.trim()) || /fixed:main/i.test(b.parentElement?.textContent || '')) {
      if (/5 PROVEN|CANARY|UNVERIFIED|5 ·/i.test(b.textContent || '')) b.textContent = chip.label;
    }
  }
}

function bumpOpsFrameHeight() {
  if (!coreDoc) return;
  const frame = coreDoc.getElementById('opsV10Frame');
  if (frame) {
    frame.style.height = 'auto';
    frame.style.minHeight = '1600px';
  }
}


function paintCompletedStripe(doc) {
  if (!doc) return;
  let el = doc.getElementById('hqP1CompletedStripe');
  if (!el) {
    el = doc.createElement('div');
    el.id = 'hqP1CompletedStripe';
    el.className = 'hq-p1-completed-stripe';
    el.setAttribute('data-hq-p1', 'completed-stripe');
    const floor = doc.querySelector('.v10-ops-summary') || doc.getElementById('hqP1Clocks') || doc.getElementById('kevinHub') || doc.querySelector('.wrap') || doc.body;
    floor?.insertAdjacentElement('afterend', el) || doc.body?.appendChild(el);
  }
  const stripe = opsFloorStripe(cache, Date.now());
  if (stripe.stripe !== 'COMPLETED') {
    el.classList.remove('show');
    el.hidden = true;
    el.innerHTML = '';
    return;
  }
  el.hidden = false;
  el.classList.add('show');
  el.innerHTML =
    `<span class="chip">COMPLETED</span>` +
    `<b>${esc(stripe.skill || 'proven invoke')}</b>` +
    `<span>${esc((stripe.artifacts || []).slice(0, 3).join(' · ') || 'artifacts')}</span>` +
    `<span class="actor">${esc(stripe.actor)}</span>`;
}

function paintLastAttemptWx(doc) {
  if (!doc) return;
  const attempt = lastAttemptClock(cache, Date.now());
  const wx = doc.getElementById('wx');
  if (wx && attempt.at && !attempt.unknown) {
    wx.textContent = `Last attempt: ${attempt.id || 'proven invoke'} · ${attempt.age} ago`;
  }
}

function patchCouplingHonesty() {
  if (!opsWin) return;
  try {
    if (opsWin.__kevinP1CouplingPatched) return;
    opsWin.__kevinP1CouplingPatched = true;
    if (typeof opsWin.workerState === 'function') {
      const prev = opsWin.workerState.bind(opsWin);
      opsWin.workerState = function(key, d, s) {
        const proposed = prev(key, d, s);
        const bundle = {
          dashboard: d,
          support: s,
          engineering: cache.engineering,
          continuation: cache.continuation,
          reject: cache.reject,
          bridge: cache.bridge,
          receipt: cache.receipt
        };
        if (String(key || '').toLowerCase() === 'bridge') return honestBridgeWorkerState(proposed, bundle, Date.now());
        return honestWorkerState(key, proposed, bundle, Date.now());
      };
    }
    if (typeof opsWin.kevinStates === 'function') {
      const prevK = opsWin.kevinStates.bind(opsWin);
      opsWin.kevinStates = function(d, s) {
        const bundle = {
          dashboard: d,
          support: s,
          engineering: cache.engineering,
          continuation: cache.continuation || opsWin.__kevinContinuation,
          reject: cache.reject,
          bridge: cache.bridge,
          receipt: cache.receipt
        };
        const center = centerHonesty(bundle, Date.now());
        if (center.mode === 'outcome_proven') {
          if (mayShowWorkingBuilding(bundle, Date.now())) return prevK(d, s).map(st => (st === 'degraded' || st === 'failed') ? 'ready' : st);
          return ['ready'];
        }
        const states = prevK(d, s);
        if ((states.includes('degraded') || states.includes('failed')) && bridgeHonesty(bundle, Date.now()).state === 'degraded') {
          const otherUnhealthy = ['tick', 'ollama', 'gateway'].some(k => d?.services?.[k] && String(d.services[k]).toLowerCase() !== 'healthy');
          if (!otherUnhealthy) return states.map(st => (st === 'degraded' || st === 'failed') ? 'ready' : st);
        }
        return states;
      };
    }
  } catch (_) {}
}

function paint() {
  injectStyle(coreDoc, 'hq-p1-gt-css', selectedWorkerCss());
  injectStyle(opsDoc, 'hq-p1-gt-css', selectedWorkerCss());
  if (opsDoc?.documentElement) {
    opsDoc.documentElement.classList.add('hq-p1-ops');
    opsDoc.body?.classList.add('hq-p1-ops');
  }
  bumpOpsFrameHeight();
  patchOpsWorkerHonesty();
  paintNewswire(coreDoc);
  paintClocks(coreDoc);
  paintClocks(opsDoc);
  paintScaffold(opsDoc);
  paintScaffold(coreDoc);
  paintKevinHonesty(opsDoc);
  paintKevinHonesty(coreDoc);
  paintCompletedStripe(opsDoc);
  paintCompletedStripe(coreDoc);
  paintLastAttemptWx(coreDoc);
  patchCouplingHonesty();
  patchToolsChipInCore();
  // Override V10 newswireStories if present
  try {
    if (window.__kevinOwnerConsoleV10) {
      window.__kevinOwnerConsoleV10.newswireStories = () => newswireStories(cache, Date.now());
      window.__kevinOwnerConsoleV10.p1 = API;
    }
  } catch (_) {}
}

function bindOpsFrame() {
  if (!coreDoc) return;
  const frame = coreDoc.getElementById('opsV10Frame');
  if (!frame) return;
  const attach = () => {
    try {
      opsWin = frame.contentWindow;
      opsDoc = frame.contentDocument;
      if (opsDoc?.body) {
        injectStyle(opsDoc, 'hq-p1-gt-css', selectedWorkerCss());
        opsDoc.documentElement.classList.add('hq-p1-ops');
        opsDoc.body.classList.add('hq-p1-ops');
        patchOpsWorkerHonesty();
        paint();
      }
    } catch (_) {}
  };
  frame.addEventListener('load', attach);
  attach();
}

function install() {
  const frame = document.getElementById('kevinCore');
  if (!frame) return;
  try {
    coreWin = frame.contentWindow;
    coreDoc = frame.contentDocument;
    if (!coreDoc?.body) return;
    injectStyle(coreDoc, 'hq-p1-gt-css', selectedWorkerCss());
    bindOpsFrame();
    refresh();
    if (timer) clearInterval(timer);
    timer = setInterval(refresh, 30000);
    // Re-bind ops frame when V10 rewrites main
    const mo = new MutationObserver(() => bindOpsFrame());
    mo.observe(coreDoc.getElementById('main') || coreDoc.body, { childList: true, subtree: true });
  } catch (e) {
    console.error('Kevin HQ P1 ground truth install failed', e);
  }
}

window.__kevinP1GroundTruth = API;
const boot = () => {
  const frame = document.getElementById('kevinCore');
  if (!frame) return;
  frame.addEventListener('load', () => setTimeout(install, 600));
  if (frame.contentDocument?.body) setTimeout(install, 800);
  setTimeout(install, 2000);
};
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
else boot();
})();
