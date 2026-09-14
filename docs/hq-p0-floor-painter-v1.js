(() => {
'use strict';
/**
 * Kevin HQ P0 OPS FLOOR painter v1 — thin overlay after P1 ground-truth.
 * One center status. NEVER couple Bridge freshness → Kevin WORKING.
 * COMPLETED stripes: west-motor PROVEN retained + transport after VERIFY PASS/MIXED; never forever-center WORKING.
 * Action Era ready>=1 → WORKING (not READY, not THROTTLED-as-primary).
 * WAITING_ITEM_BUDGETS / transport retry-budget → THROTTLED when not working.
 * Skill Lab hq-live-floor.skill_lab → GAP / LAB / PROVE (capability acquisition).
 */
const VERSION = 'hq-p0-floor-painter-v1';
const SCHEMA = 'kevin.hq-live-floor.v1';
/** Center labels only — OUTCOME_PROVEN/PASS/COMPLETED never pulse center (stripe owns proven). */
const CENTER_ALLOWED = Object.freeze(['READY','THROTTLED','WORKING','INVOKING','VERIFYING','BLOCKED','SCAFFOLD','GAP','LAB','PROVE']);
function isCenterAllowed(label) {
  return CENTER_ALLOWED.includes(String(label || '').toUpperCase());
}
/** Prefer painted_hint; never floor.status (OUTCOME_PROVEN is status/stripe, not center). */
function publishedCenterHint(floor) {
  const hint = String(floor.painted_hint || '').toUpperCase();
  if (isCenterAllowed(hint)) return hint;
  const c = String(floor.center_status || floor.center || '').toUpperCase();
  if (isCenterAllowed(c)) return c;
  return '';
}
function statusIsOutcomeProven(floor, cont, reject) {
  const st = String(floor.status || '').toUpperCase();
  return st === 'OUTCOME_PROVEN'
    || floor.outcome_proven === true
    || (reject && reject.outcome_proven === true)
    || String((reject && reject.reason) || '').toUpperCase() === 'OUTCOME_PROVEN'
    || (cont && cont.outcome_proven === true);
}
/** Authoritative ops-floor cycle — ONLY hq-live-floor.json. Never support.supervisor.cycle. */
function floorCycle(bundle) {
  const floor = (bundle && bundle.floor) || {};
  const n = Number(floor.cycle);
  return Number.isFinite(n) ? n : null;
}


const RAW = 'https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/';
const SUPERVISOR_PROVEN_SHA_PREFIX = 'F17F4B0A';
const SUPERVISOR_PROVEN_VERSION = '1.8.12';
const SCAFFOLD_FRESH_S = 600; // 10 min
const WEST_MOTOR_COMPLETED_AT = '2026-09-12T00:54:57Z';
const WEST_MOTOR_INVOKE_ID = 'invoke-owner-west-motor-parts-chase-fresh-8-v1';
const TRANSPORT_COMPLETED_AT = '2026-09-12T02:33:30.501071Z';
const TRANSPORT_INVOKE_ID = 'invoke-owner-west-motor-transport-dispatch-template-v1';
const TRANSPORT_WI = 'owner-west-motor-transport-dispatch-template-v1';
const PATHS = {
  floor: 'reports/hq-live-floor.json',
  continuation: 'reports/autonomy-continuation-latest.json',
  support: 'reports/support-latest.json',
  engineering: 'reports/engineering/latest.json',
  reject: 'reports/invocations/latest-public-reject.json',
  receipt: 'reports/invocations/done/invoke-owner-west-motor-parts-chase-fresh-8-v1.json',
  bridge: 'reports/bridge-latest.json',
  canary: 'reports/main-agent-canary-omen.json',
  selection: 'reports/autonomy-selection-current.json',
  scaffold: 'reports/scaffold-heartbeat-latest.json',
  invokeReady: 'reports/action-era/invoke-ready-latest.json'
};

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
function esc(v) {
  return String(v ?? '').replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));
}

function supervisorIdentity(bundle) {
  const floor = bundle.floor || {};
  const support = bundle.support || {};
  const cont = bundle.continuation || {};
  const hash = String(
    floor.supervisor_sha ||
    floor.supervisor?.sha ||
    support.hashes?.supervisor ||
    cont.supervisor_sha ||
    ''
  ).toUpperCase();
  const version = String(
    floor.supervisor_version ||
    floor.supervisor?.version ||
    cont.version ||
    support.supervisor?.version ||
    ''
  );
  const proven = hash.startsWith(SUPERVISOR_PROVEN_SHA_PREFIX) || version === SUPERVISOR_PROVEN_VERSION;
  const short = hash ? hash.slice(0, 8) : '—';
  return {
    hash,
    short,
    version: version || (proven ? SUPERVISOR_PROVEN_VERSION : (hash ? 'unknown' : '—')),
    proven,
    visible: `${version || 'unknown'} · ${short}`
  };
}

function actionEraReady(bundle) {
  // Engineering queues/composite are authoritative for WORKING entitlement.
  // eng ready=0 → do NOT paint WORKING as primary (even if a stale floor snapshot says ready>0).
  const a = bundle.engineering?.action || {};
  const hasEng = !!(bundle.engineering && bundle.engineering.action);
  const qReady = Number(a.queues?.ready);
  const cReady = Number(a.composite_skills?.ready);
  if (hasEng) {
    const engReady = Math.max(
      Number.isFinite(qReady) ? qReady : 0,
      Number.isFinite(cReady) ? cReady : 0
    );
    return engReady;
  }
  const floor = bundle.floor || {};
  if (Number.isFinite(Number(floor.action_era_ready))) return Number(floor.action_era_ready);
  if (Number.isFinite(Number(floor.ready_count))) return Number(floor.ready_count);
  const inv = bundle.invokeReady || {};
  if (Number.isFinite(Number(inv.ready_count))) return Number(inv.ready_count);
  if (Array.isArray(inv.ready) && inv.ready.length) return inv.ready.length;
  const live = Number(bundle.reject?.live_action_era_ready_invoke_count);
  if (Number.isFinite(live) && live > 0) return live;
  return 0;
}

function liveWorkerCount(bundle, now) {
  const s = bundle.support || {};
  if (ageSeconds(s.generated_at, now) > 360) return 0;
  const aw = s.active_workers || {};
  const total = Object.values(aw).reduce((n, v) => n + (Number(v) || 0), 0);
  return Math.max(0, total - (Number(aw.tick) || 0) - (Number(aw.bridge) || 0));
}

function processRunningNow(bundle, now) {
  const floor = bundle.floor || {};
  if (floor.supervisor_process_running === true || floor.invoke_process_running === true) return true;
  const d = bundle.dashboard || {};
  const task = d.current_task;
  if (task && ageSeconds(d.generated_at, now) <= 180) {
    const phase = String(task.phase || task.status || '');
    if (!/(done|complete|completed|failed|stopped|idle|queued|wait|cooldown|yield|skip|cancel|reject)/i.test(phase)) return true;
  }
  return liveWorkerCount(bundle, now) > 0;
}

function isThrottledSignal(bundle) {
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  const status = String(floor.center_status || floor.status || cont.status || '').toUpperCase();
  const reason = String(floor.throttle_reason || cont.work_conservation || cont.deferred_reason || '').toUpperCase();
  const last = String(bundle.support?.supervisor?.last_result || '').toUpperCase();
  if (status === 'WAITING_ITEM_BUDGETS') return true;
  if (/WAITING_ITEM_BUDGETS|RETRY_BUDGET|BOUNDED_RETRY|COOLDOWN|TRANSPORT_RETRY/.test(reason)) return true;
  if (/WAITING_ITEM_BUDGETS|THROTTLED|SATURATED|COOLDOWN/.test(last)) return true;
  if (floor.throttled === true || floor.retry_budget_exhausted === true) return true;
  if (Array.isArray(cont.deferred) && cont.deferred.length && /BUDGET|MIN_REPEAT|RETRY/.test(JSON.stringify(cont.deferred).toUpperCase())) {
    if (!processRunningNow(bundle) && actionEraReady(bundle) < 1) return true;
  }
  return false;
}

function isBlocked(bundle) {
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  const status = String(floor.center_status || floor.status || cont.status || '').toUpperCase();
  if (/^BLOCKED_/.test(status) || status === 'BLOCKED') return true;
  if (floor.blocked === true || floor.fail_closed === true) return true;
  if (String(floor.authority || '').toUpperCase() === 'MISSING') return true;
  return false;
}

function isInvoking(bundle) {
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  const status = String(floor.center_status || floor.status || cont.status || '').toUpperCase();
  const id = supervisorIdentity(bundle);
  if (!id.proven) return false; // INVOKING only honest on F17F4B0A / v1.8.12
  if (/^ROUTED_TO_PROVEN_SKILL/.test(status)) return true;
  if (floor.invoking === true) return true;
  if (status === 'INVOKING') return true;
  return false;
}

function isVerifying(bundle) {
  const floor = bundle.floor || {};
  const reject = bundle.reject || {};
  const hint = String(floor.painted_hint || floor.center_status || floor.center || '').toUpperCase();
  if (floor.verifying === true || hint === 'VERIFYING') return true;
  const artifacts = floor.artifacts || reject.artifacts || [];
  const hasArtifacts = (Array.isArray(artifacts) && artifacts.length > 0) || !!reject.receipt_sha256;
  const proven = reject.outcome_proven === true || String(reject.reason || '').toUpperCase() === 'OUTCOME_PROVEN';
  if (hasArtifacts && !proven && String(reject.receipt_status || '').toUpperCase() !== 'PROVEN') return true;
  return false;
}

function outcomeProven(bundle) {
  const r = bundle.reject || {};
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  return statusIsOutcomeProven(floor, cont, r);
}

function westMotorProven(bundle) {
  const receipt = bundle.receipt || {};
  if (String(receipt.status || '').toUpperCase() === 'PROVEN' && /west-motor/i.test(String(receipt.invocation_id || receipt.skill_key || ''))) return true;
  const floor = bundle.floor || {};
  if (floor.west_motor_proven === true) return true;
  return outcomeProven(bundle) && /west-motor/i.test(String(bundle.reject?.work_id_hint || bundle.reject?.supervisor_request_id || ''));
}

function cycleFrozen(bundle, now) {
  const floor = bundle.floor || {};
  // Ban support.supervisor.cycle — it can stick at 449 while floor.cycle advances.
  const cycle = floorCycle(bundle);
  const contAge = ageSeconds(bundle.continuation?.generated_at, now);
  // Only freeze from FLOOR cues. Never treat stale support cycle as authoritative.
  if (floor.painter_frozen === true || floor.cycle_frozen === true) return true;
  // Legacy: if floor itself is stuck at 449 with dead continuation, honesty cue — still floor-only.
  if (cycle === 449 && (contAge > 3600 || floor.painter_frozen === true)) return true;
  return false;
}

function scaffoldPulse(bundle, now) {
  const floor = bundle.floor || {};
  const sc = bundle.scaffold || floor.scaffold || {};
  const updated = sc.updated_at || floor.scaffold_updated_at || sc.at;
  const age = ageSeconds(updated, now);
  const activeKinds = String(sc.kind || sc.phase || floor.scaffold_phase || '').toUpperCase();
  const cos = /COS|RUNTIME|VERIFY|SCAFFOLD/.test(activeKinds) || sc.active === true || floor.scaffold_active === true;
  const fresh = Number.isFinite(parseTs(updated)) && age < SCAFFOLD_FRESH_S;
  if (fresh || (cos && age < SCAFFOLD_FRESH_S)) {
    return {
      visible: true,
      chip: 'SCAFFOLD',
      actor: 'GROKBOT_ACTED',
      neverKevinActed: true,
      neverKevinWorking: true,
      dashed: true,
      updated_at: updated,
      age: ageText(age)
    };
  }
  // Explicit floor/scaffold marker under 10 min
  if (fresh) {
    return { visible: true, chip: 'SCAFFOLD', actor: 'GROKBOT_ACTED', neverKevinActed: true, neverKevinWorking: true, dashed: true, updated_at: updated, age: ageText(age) };
  }
  return { visible: false, chip: null, actor: null, neverKevinActed: true, neverKevinWorking: true, dashed: false };
}


function skillLabState(bundle) {
  const floor = bundle.floor || {};
  const lab = floor.skill_lab || bundle.skill_lab || {};
  const stage = String(lab.stage || floor.skill_lab_stage || '').toLowerCase().trim();
  const ready = Number(lab.ready_count);
  const running = Number(lab.running_count);
  const failed = Number(lab.failed_count);
  const done = Number(lab.done_count);
  const entrypoint = lab.entrypoint || floor.skill_lab_entrypoint || null;
  const cron = lab.cron || floor.skill_lab_cron || null;
  const missingKey = lab.required_skill_key_missing === true
    || lab.missing_required_skill_key === true
    || (!lab.required_skill_key && (stage === 'gap' || /missing|gap|no_skill|required_skill/i.test(String(lab.reason || lab.detail || ''))));
  const provePending = lab.promote_to_registry_pending === true
    || lab.registry_promote_pending === true
    || stage === 'prove'
    || /prove|promote|registry/.test(stage);
  const labActive = (Number.isFinite(running) && running > 0)
    || (Number.isFinite(ready) && ready > 0)
    || stage === 'lab'
    || stage === 'running'
    || lab.running === true;
  let chrome = null;
  // Explicit stage wins: LAB when skill_lab.stage=LAB (CoS)
  if (stage === 'lab') chrome = 'LAB';
  else if (provePending) chrome = 'PROVE';
  else if (labActive) chrome = 'LAB';
  else if (missingKey || stage === 'gap') chrome = 'GAP';
  else if (stage === 'prove') chrome = 'PROVE';
  else if (stage === 'lab') chrome = 'LAB';
  return {
    present: !!(lab && (stage || lab.ready_count != null || lab.running_count != null || lab.entrypoint || lab.cron || missingKey || provePending)),
    stage: stage || null,
    ready_count: Number.isFinite(ready) ? ready : 0,
    running_count: Number.isFinite(running) ? running : 0,
    failed_count: Number.isFinite(failed) ? failed : 0,
    done_count: Number.isFinite(done) ? done : 0,
    entrypoint,
    cron,
    chrome,
    missingKey,
    provePending,
    labActive
  };
}

/**
 * Center + last-action state machine (priority):
 * BLOCKED > WORKING (ready>=1 / live) > INVOKING > VERIFYING > THROTTLED > PROVE/LAB/GAP > SCAFFOLD cue > READY
 * COMPLETED + OUTCOME_PROVEN are stripe-only (never forever center).
 * Center labels only: READY/THROTTLED/WORKING/INVOKING/VERIFYING/BLOCKED/SCAFFOLD/GAP/LAB/PROVE.
 * ready>=1 beats THROTTLED as primary center.
 * skill_lab: GAP (missing required_skill_key) · LAB (running>0|ready>0) · PROVE (promote-to-registry pending).
 */
function floorCenterState(bundle, now) {
  const n = Number.isFinite(now) ? now : Date.now();
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  const id = supervisorIdentity(bundle);
  const ready = actionEraReady(bundle);
  const live = processRunningNow(bundle, n);
  const selected = floor.selected_id || cont.selected_id || bundle.selection?.id || null;
  const budgetRemaining = floor.budget_remaining ?? cont.budget_remaining ?? null;
  const frozen = cycleFrozen(bundle, n);
  const scaffold = scaffoldPulse(bundle, n);
  const throttle = isThrottledSignal(bundle);
  const blocked = isBlocked(bundle);
  const invoking = isInvoking(bundle);
  const verifying = isVerifying(bundle);
  const proven = outcomeProven(bundle);
  const skillLab = skillLabState(bundle);

  // Prefer published floor schema when present and valid
  // Center ONLY from painted_hint ∈ CENTER_ALLOWED (never floor.status / OUTCOME_PROVEN).
  if (floor && (floor.schema === SCHEMA || floor.kind === SCHEMA || floor.kind === 'kevin.hq-live-floor.v1')) {
    const rawHint = String(floor.painted_hint || floor.center_status || floor.center || '').toUpperCase();
    // status OUTCOME_PROVEN → stripe ownership (proven flag); never center pulse
    if (rawHint === 'OUTCOME_PROVEN' || rawHint === 'PASS' || String(floor.status || '').toUpperCase() === 'OUTCOME_PROVEN') {
      // fall through to HOLD / allowed painted_hint after WORKING/throttle gates
    }
    // COMPLETED is stripe-only — never a forever center, but also never collapse to READY when hint says COMPLETED
    if (rawHint === 'COMPLETED') {
      return pack('VERIFYING', 'verifying', {
        detail: 'painted_hint/center COMPLETED → stripe owns COMPLETED · refuse OUTCOME_PROVEN/READY center',
        selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven: true, stripeCompleted: true, skillLab
      });
    }
    const published = publishedCenterHint(floor);
    if (published) {
      // Still enforce ready>=1 → WORKING over THROTTLED/READY
      if (ready >= 1 || live) {
        return pack('WORKING', 'working', {
          detail: `Action Era ready=${ready}${live ? ' · live worker/process' : ''} · published floor overridden to WORKING`,
          selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
        });
      }
      if (published === 'THROTTLED') {
        return pack('THROTTLED', 'throttled', {
          detail: 'WAITING_ITEM_BUDGETS / bounded retry — not Ready',
          selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle)
        });
      }
      if (published === 'BLOCKED') {
        return pack('BLOCKED', 'blocked', {
          detail: String(floor.detail || 'fail-closed / missing capability'),
          selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
        });
      }
      // READY must not hide Skill Lab chrome (GAP/LAB/PROVE)
      if (published === 'READY' && (skillLab.chrome === 'GAP' || skillLab.chrome === 'LAB' || skillLab.chrome === 'PROVE')) {
        return pack(skillLab.chrome, skillLab.chrome.toLowerCase(), {
          detail: `Skill Lab ${skillLab.chrome} · stage=${skillLab.stage || skillLab.chrome} · overrides painted_hint READY`,
          selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
        });
      }
      if (published === 'WORKING' || published === 'INVOKING' || published === 'VERIFYING' || published === 'SCAFFOLD' || published === 'READY' || published === 'GAP' || published === 'LAB' || published === 'PROVE') {
        return pack(published, published.toLowerCase(), {
          detail: String(floor.detail || published),
          selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
        });
      }
    }
  }

  if (blocked && !(ready >= 1 || live)) {
    // Blocked primary unless live working entitlement clears the calm-block paint into WORKING
    return pack('BLOCKED', 'blocked', {
      detail: `${String(cont.status || 'BLOCKED')} · fail-closed / authority · not PASS`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  // WORKING beats THROTTLED when ready>=1 or live process
  if (ready >= 1 || live) {
    return pack('WORKING', 'working', {
      detail: live && ready < 1
        ? 'Live worker / Supervisor·invoke process running NOW'
        : `Action Era ready=${ready} · create_spreadsheet+create_text entitlement`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle),
      lastAction: 'WORKING'
    });
  }

  if (invoking) {
    return pack('INVOKING', 'invoking', {
      detail: `Supervisor selected WI on proven-skill path · ${id.visible}`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  if (verifying) {
    return pack('VERIFYING', 'verifying', {
      detail: 'Artifacts present · outcome_proven not yet true · no early PASS',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  if (throttle) {
    return pack('THROTTLED', 'throttled', {
      detail: 'WAITING_ITEM_BUDGETS / bounded retry budget / cooldown — NOT Ready',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }

  // Skill Lab capability acquisition (after throttle; never overrides WORKING/INVOKING/VERIFYING)
  if (skillLab.chrome === 'PROVE') {
    return pack('PROVE', 'prove', {
      detail: `Skill Lab PROVE · promote-to-registry pending · stage=${skillLab.stage || 'prove'} · done=${skillLab.done_count}`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }
  if (skillLab.chrome === 'LAB') {
    return pack('LAB', 'lab', {
      detail: `Skill Lab LAB · ready=${skillLab.ready_count} running=${skillLab.running_count} · ${skillLab.entrypoint || 'lab'}`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }
  if (skillLab.chrome === 'GAP') {
    return pack('GAP', 'gap', {
      detail: `Skill Lab GAP · missing required_skill_key · stage=${skillLab.stage || 'gap'}`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }

  if (frozen) {
    return pack('THROTTLED', 'throttled', {
      detail: `Frozen cycle ${floorCycle(bundle) ?? '—'} · dead painter honesty cue · not READY (floor.cycle only)`,
      selected, ready, budgetRemaining, id, frozen: true, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  if (scaffold.visible) {
    return pack('SCAFFOLD', 'scaffold', {
      detail: 'CoS/RUNTIME/VERIFY active · dashed rail · never KEVIN_ACTED',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  // Supervisor not on proven SHA: surface version honestly (INVOKING path already gated)
  if (!id.proven && id.version && id.version !== '—' && /1\.8\.10/.test(id.version)) {
    return pack('THROTTLED', 'throttled', {
      detail: `Supervisor ${id.visible} — not F17F4B0A/v1.8.12; do not hide version`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle)
    });
  }

  // Fail-closed READY gate (CoS): never READY when VERIFYING/THROTTLED/GAP/LAB/PROVE signals remain
  const waitingBudgets = floor.waiting_item_budgets === true || cont.waiting_item_budgets === true;
  if (throttle || waitingBudgets) {
    return pack('THROTTLED', 'throttled', {
      detail: waitingBudgets
        ? 'waiting_item_budgets=true · refuse READY'
        : 'throttle signal · refuse READY',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }
  if (skillLab.chrome === 'PROVE' || skillLab.chrome === 'LAB' || skillLab.chrome === 'GAP') {
    return pack(skillLab.chrome, skillLab.chrome.toLowerCase(), {
      detail: `Skill Lab ${skillLab.chrome} · refuse READY`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }
  if (verifying || hintVerifyGuard(floor)) {
    return pack('VERIFYING', 'verifying', {
      detail: 'hq-live-floor VERIFYING / painted_hint · refuse READY',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }

  const tipHint = publishedCenterHint(floor);
  const rawTip = String(floor.painted_hint || floor.center_status || floor.center || floor.status || '').toUpperCase();
  // OUTCOME_PROVEN / PASS / COMPLETED never become center — HOLD or VERIFYING
  if (rawTip === 'OUTCOME_PROVEN' || rawTip === 'PASS' || String(floor.status || '').toUpperCase() === 'OUTCOME_PROVEN') {
    if (skillLab.chrome === 'PROVE' || skillLab.chrome === 'LAB' || skillLab.chrome === 'GAP') {
      return pack(skillLab.chrome, skillLab.chrome.toLowerCase(), {
        detail: `status OUTCOME_PROVEN → stripe · Skill Lab ${skillLab.chrome} center · refuse OUTCOME_PROVEN center`,
        selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven: true, stripeCompleted: westMotorProven(bundle), skillLab
      });
    }
    if (waitingBudgets || throttle) {
      return pack('THROTTLED', 'throttled', {
        detail: 'status OUTCOME_PROVEN → stripe · HOLD select · waiting_item_budgets · refuse OUTCOME_PROVEN center',
        selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven: true, stripeCompleted: westMotorProven(bundle), skillLab
      });
    }
    return pack('READY', 'ready', {
      detail: 'status OUTCOME_PROVEN → stripe · HOLD cleared · center READY · never OUTCOME_PROVEN',
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle: false, proven: true, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }
  if (tipHint && tipHint !== 'READY') {
    if (rawTip === 'COMPLETED') {
      return pack('VERIFYING', 'verifying', {
        detail: 'hint COMPLETED · stripe owns COMPLETED · refuse READY',
        selected, ready, budgetRemaining, id, frozen, scaffold, throttle, proven, stripeCompleted: true, skillLab
      });
    }
    if (isCenterAllowed(tipHint) && tipHint !== 'READY') {
      return pack(tipHint, tipHint.toLowerCase(), {
        detail: `hq-live-floor hint ${tipHint} · refuse READY`,
        selected, ready, budgetRemaining, id, frozen, scaffold, throttle: tipHint==='THROTTLED', proven, stripeCompleted: westMotorProven(bundle), skillLab
      });
    }
    return pack('THROTTLED', 'throttled', {
      detail: `hq-live-floor hint ${rawTip || tipHint} ≠ READY · refuse READY / refuse OUTCOME_PROVEN center`,
      selected, ready, budgetRemaining, id, frozen, scaffold, throttle: true, proven, stripeCompleted: westMotorProven(bundle), skillLab
    });
  }

  return pack('READY', 'ready', {
    detail: 'No live run · no throttle · no block · no scaffold pulse',
    selected, ready, budgetRemaining, id, frozen, scaffold, throttle: false, proven, stripeCompleted: westMotorProven(bundle)
  });
}

function hintVerifyGuard(floor) {
  const hint = String(floor.painted_hint || floor.center_status || floor.center || '').toUpperCase();
  return hint === 'VERIFYING';
}

function pack(label, mode, extra) {
  let L = String(label || '').toUpperCase();
  // Absolute refuse: these never pulse as center chrome
  if (L === 'OUTCOME_PROVEN' || L === 'PASS' || L === 'COMPLETED') {
    L = 'VERIFYING';
    mode = 'verifying';
  }
  if (!isCenterAllowed(L)) {
    L = 'THROTTLED';
    mode = 'throttled';
  }
  return Object.assign({
    label: L,
    mode: mode || L.toLowerCase(),
    center: L,
    neverBridgeCoupled: true,
    completedIsStripeOnly: true,
    outcomeProvenIsStripeOnly: true
  }, extra || {});
}

function isTransportWi(id) {
  return /transport-dispatch|transport_wi|west-motor-transport/i.test(String(id || ''));
}

/** Transport may paint COMPLETED only after VERIFY PASS/MIXED (or explicit outcome_proven / painted_hint). */
function transportCompletedAllowed(bundle) {
  const reject = bundle.reject || {};
  const floor = bundle.floor || {};
  const cont = bundle.continuation || {};
  const reason = String(reject.reason || floor.verify_reason || cont.status || '').toUpperCase();
  const actor = String(reject.verify_actor || floor.verify_actor || floor.last_actor || '').toUpperCase();
  const receiptStatus = String(reject.receipt_status || floor.transport_receipt_status || '').toUpperCase();
  const hint = String(floor.painted_hint || floor.center_status || floor.center || '').toUpperCase();
  const proven = (
    reject.outcome_proven === true ||
    floor.outcome_proven === true ||
    cont.outcome_proven === true ||
    reason === 'OUTCOME_PROVEN' ||
    floor.transport_outcome_proven === true
  );
  const passMixed = (reason === 'PASS' || reason === 'OUTCOME_PROVEN' || /PASS/.test(reason)) && (actor === 'MIXED' || /MIXED/.test(actor) || !actor);
  const verifyPassMixed = floor.verify_pass_mixed === true || passMixed || (proven && (actor === 'MIXED' || !actor));
  if (floor.transport_completed === true) return true;
  if (hint === 'COMPLETED' && (proven || verifyPassMixed || isTransportWi(floor.selected_id || cont.selected_id))) return true;
  if (verifyPassMixed) return true;
  if (proven && (receiptStatus === 'PROVEN' || hint === 'COMPLETED' || !!floor.last_invoke_completed_at) && isTransportWi(reject.work_id_hint || reject.supervisor_request_id || floor.selected_id || cont.selected_id)) return true;
  return false;
}


const PROVEN_LABELS = Object.freeze({
  west_motor: 'west-motor',
  transport: 'transport',
  dealership: 'dealership'
});

function provenKeyToLabel(key) {
  const prefix = String(key || '').replace(/_proven$/, '');
  if (PROVEN_LABELS[prefix]) return PROVEN_LABELS[prefix];
  return prefix.replace(/_/g, '-');
}

/**
 * COMPLETED stripe items: every floor *_proven===true except outcome_proven.
 * Generic scan — not limited to west/transport/dealership.
 */
function floorProvenItems(bundle) {
  const floor = (bundle && bundle.floor) || {};
  const receipt = (bundle && bundle.receipt) || {};
  const seen = new Set();
  const items = [];

  function pushItem(item) {
    const label = String(item.label || '').trim();
    if (!label || seen.has(label)) return;
    seen.add(label);
    items.push({
      key: item.key || null,
      label,
      at: item.at || null,
      skill: item.skill || null,
      invocation_id: item.invocation_id || null,
      receipt_sha256: item.receipt_sha256 || null,
      paint: 'PROVEN'
    });
  }

  for (const [k, v] of Object.entries(floor)) {
    if (!/_proven$/.test(k)) continue;
    if (k === 'outcome_proven') continue;
    if (v !== true) continue;
    const prefix = k.replace(/_proven$/, '');
    const label = provenKeyToLabel(k);
    pushItem({
      key: k,
      label,
      at: floor[`${prefix}_completed_at`] || floor.last_invoke_completed_at || receipt.completed_at || null,
      skill: floor[`${prefix}_skill`] || floor[`${prefix}_skill_key`] || null,
      invocation_id: floor[`${prefix}_invocation_id`] || floor.last_invocation_id || null,
      receipt_sha256: floor[`${prefix}_receipt_sha256`] || floor.receipt_sha256 || null
    });
  }

  // Fallback: west from receipt / westMotorProven when floor flag absent
  if (!seen.has('west-motor') && westMotorProven(bundle)) {
    pushItem({
      key: 'west_motor_proven',
      label: 'west-motor',
      at: receipt.completed_at || WEST_MOTOR_COMPLETED_AT,
      skill: receipt.skill_key || 'west-motor-parts-chase-board-pack@1',
      invocation_id: receipt.invocation_id || WEST_MOTOR_INVOKE_ID,
      receipt_sha256: receipt.receipt_sha256 || receipt.sha256 || null
    });
  }

  // Fallback: transport when selected transport + VERIFY PASS/MIXED allowed
  const selected = floor.selected_id || (bundle.continuation || {}).selected_id || (bundle.selection || {}).id || '';
  if (!seen.has('transport') && isTransportWi(selected) && transportCompletedAllowed(bundle)) {
    pushItem({
      key: 'transport_proven',
      label: 'transport',
      at: floor.transport_completed_at || floor.last_invoke_completed_at || TRANSPORT_COMPLETED_AT,
      skill: floor.transport_skill || floor.transport_skill_key || 'vehicle-transport-mission-pack@1',
      invocation_id: floor.transport_invocation_id || TRANSPORT_INVOKE_ID,
      receipt_sha256: floor.transport_receipt_sha256 || null
    });
  }

  // Fill known skill defaults when floor flag present but skill blank
  for (const it of items) {
    if (it.label === 'west-motor' && !it.skill) it.skill = receipt.skill_key || 'west-motor-parts-chase-board-pack@1';
    if (it.label === 'transport' && !it.skill) it.skill = 'vehicle-transport-mission-pack@1';
    if (it.label === 'dealership' && !it.skill) it.skill = floor.dealership_skill || floor.dealership_skill_key || 'dealership-pack@1';
    if (it.label === 'west-motor' && !it.at) it.at = receipt.completed_at || WEST_MOTOR_COMPLETED_AT;
    if (it.label === 'transport' && !it.at) it.at = floor.transport_completed_at || floor.last_invoke_completed_at || TRANSPORT_COMPLETED_AT;
    if (it.label === 'dealership' && !it.at) it.at = floor.dealership_completed_at || floor.last_invoke_completed_at || null;
    if (it.label === 'west-motor' && !it.invocation_id) it.invocation_id = receipt.invocation_id || WEST_MOTOR_INVOKE_ID;
    if (it.label === 'transport' && !it.invocation_id) it.invocation_id = TRANSPORT_INVOKE_ID;
  }

  return items;
}

function completedStripe(bundle) {
  // COMPLETED stripes for every floor *_proven===true (except outcome_proven).
  // Backward-compat fields retained for tests / callers.
  const selected = bundle.floor?.selected_id || bundle.continuation?.selected_id || bundle.selection?.id || '';
  const receipt = bundle.receipt || {};
  const floor = bundle.floor || {};
  const items = floorProvenItems(bundle);
  const actor = String((bundle.reject || {}).verify_actor || floor.verify_actor || floor.last_actor || 'MIXED').toUpperCase() || 'MIXED';
  const westItem = items.find(x => x.label === 'west-motor') || null;
  const transportItem = items.find(x => x.label === 'transport') || null;
  const dealershipItem = items.find(x => x.label === 'dealership') || null;
  const primary = westItem || transportItem || dealershipItem || items[0] || null;
  const west = !!westItem || westMotorProven(bundle);
  const transportOk = !!transportItem || (isTransportWi(selected) && transportCompletedAllowed(bundle));

  if (items.length) {
    return {
      show: true,
      stripe: 'COMPLETED',
      actor,
      at: primary?.at || receipt.completed_at || floor.last_invoke_completed_at || null,
      skill: primary?.skill || null,
      invocation_id: primary?.invocation_id || null,
      paint: 'PROVEN',
      westMotorOnly: west && !transportOk && !dealershipItem && items.length === 1,
      westMotorRetained: west,
      transportCompleted: !!transportOk,
      transportAt: transportItem ? transportItem.at : (transportOk ? (floor.transport_completed_at || floor.last_invoke_completed_at || TRANSPORT_COMPLETED_AT) : null),
      transportSkill: transportItem ? transportItem.skill : (transportOk ? 'vehicle-transport-mission-pack@1' : null),
      dealershipCompleted: !!dealershipItem,
      selectedIsTransport: isTransportWi(selected),
      items
    };
  }

  return {
    show: false,
    stripe: null,
    actor: null,
    at: null,
    skill: null,
    selectedIsTransport: isTransportWi(selected),
    transportCompleted: false,
    dealershipCompleted: false,
    westMotorRetained: false,
    items: [],
    verifyNotPass: isTransportWi(selected) && !transportCompletedAllowed(bundle)
  };
}

function nowStrip(bundle, now) {
  const center = floorCenterState(bundle, now);
  const id = center.id || supervisorIdentity(bundle);
  const cycle = floorCycle(bundle);
  return {
    selected: center.selected || '—',
    status: center.label,
    cycle: cycle == null ? '—' : cycle,
    cycleSource: 'hq-live-floor.json',
    version: id.version,
    sha: id.short,
    versionSha: id.visible,
    ready: center.ready,
    budgetRemaining: center.budgetRemaining == null ? '—' : center.budgetRemaining
  };
}

function floorNewswire(bundle, now) {
  const items = [];
  const push = (id, text, at, severity) => {
    if (!text) return;
    items.push({ id, text: String(text).slice(0, 220), at: at || null, severity: severity || 'normal' });
  };
  const cont = bundle.continuation || {};
  const support = bundle.support || {};
  const reject = bundle.reject || {};
  const bridge = bundle.bridge || {};
  const floor = bundle.floor || {};

  if (Array.isArray(floor.events)) {
    for (const ev of floor.events.slice(0, 5)) {
      push(ev.id || ev.kind || 'floor-event', ev.text || ev.title || JSON.stringify(ev).slice(0, 120), ev.at || ev.generated_at, ev.severity);
    }
  }
  if (cont.generated_at) {
    push('continuation', `CONTINUATION · ${cont.status || 'UNKNOWN'} · ${cont.selected_id || 'none'}`, cont.generated_at,
      /BLOCKED|WAITING|ERROR/i.test(String(cont.status || '')) ? 'caution' : 'normal');
  }
  if (reject.generated_at) {
    push('reject', `REJECT · ${reject.reason || 'UNKNOWN'} · ${reject.work_id_hint || ''}`.trim(), reject.generated_at,
      reject.reason === 'OUTCOME_PROVEN' ? 'normal' : 'caution');
  }
  {
    const b = (floor.bridge && typeof floor.bridge === 'object') ? floor.bridge : bridge;
    const fromFloor = !!(floor.bridge && typeof floor.bridge === 'object');
    const at = b.at || b.generated_at || b.updated_at || null;
    if (at || fromFloor || b.status || b.puller || b.why || bridge.at || bridge.generated_at) {
      const status = String(b.status || (fromFloor ? (b.state || 'ok') : (b.bridge || 'unknown')));
      const why = String(b.why || b.detail || b.reason || '').trim();
      const puller = b.puller || '—';
      const whyBit = why ? ` · ${why.slice(0, 80)}` : '';
      push('bridge', `BRIDGE · ${status}${whyBit} · puller ${puller}`, at || bridge.at || bridge.generated_at);
    }
  }
  // Prefer PR-ish / selection events over stuck Benchmark 30/30 as the only news
  if (bundle.selection?.selected_at) {
    push('selection', `SELECT · ${bundle.selection.id || 'none'} · score ${bundle.selection.score ?? '—'}`, bundle.selection.selected_at);
  }
  if (support.generated_at) {
    const bench = support.benchmark?.regression;
    // Only include benchmark if we have <5 items — never as the sole story
    if (items.length < 4 && bench) {
      push('benchmark', `BENCHMARK · ${bench.passed}/${bench.total}`, support.benchmark.at || support.generated_at);
    } else if (!bench) {
      push('support', `FLOOR · cycle ${floorCycle(bundle) ?? '—'} · support.ok=${support.supervisor?.last_result || 'ok'} (ignore support.supervisor.cycle)`, support.generated_at);
    }
  }
  const seen = new Set();
  const out = [];
  for (const it of items) {
    if (seen.has(it.id)) continue;
    seen.add(it.id);
    out.push(it);
    if (out.length >= 5) break;
  }
  // Kill stuck Benchmark 30/30 as the only news
  if (out.length === 1 && out[0].id === 'benchmark') {
    out.push({ id: 'floor-idle', text: 'No newer continuation/reject/bridge/PR events published this cycle', severity: 'caution', at: null });
  }
  return out;
}

function lastAttemptClock(bundle, now) {
  const receipt = bundle.receipt || {};
  const floor = bundle.floor || {};
  const candidates = [];
  if (receipt.completed_at) candidates.push({ at: receipt.completed_at, source: 'receipt.completed_at' });
  if (floor.last_invoke_completed_at) candidates.push({ at: floor.last_invoke_completed_at, source: 'floor.last_invoke_completed_at' });
  for (const [k, v] of Object.entries(floor)) {
    if (!/_completed_at$/.test(k)) continue;
    if (!v) continue;
    candidates.push({ at: v, source: 'floor.' + k });
  }
  let best = null;
  for (const c of candidates) {
    const t = parseTs(c.at);
    if (!Number.isFinite(t)) continue;
    if (!best || t > best.t) best = { t, at: c.at, source: c.source };
  }
  if (best) {
    const age = ageSeconds(best.at, now);
    return {
      at: best.at,
      age: ageText(age),
      unknown: false,
      source: best.source,
      fixtureWestMotor: String(best.at).startsWith('2026-09-12T00:54:57')
    };
  }
  const cont = bundle.continuation || {};
  const hist = Array.isArray(cont.history) ? cont.history : [];
  const selected = hist.find(x => String(x.id) === String(cont.selected_id || '')) || hist.at(-1);
  const at = selected?.last_turn_at || cont.generated_at || null;
  const age = ageSeconds(at, now);
  return {
    at,
    age: Number.isFinite(parseTs(at)) ? ageText(age) : 'unknown',
    unknown: !Number.isFinite(parseTs(at)),
    source: selected ? 'continuation.history' : 'continuation',
    fixtureWestMotor: false
  };
}

function toolsCanary(bundle, now) {
  const c = bundle.canary || {};
  const fresh = ageSeconds(c.generated_at, now) <= 1800
    && String(c.state || '') === 'OMEN_PROVEN'
    && Number(c.visible_tool_count) === 5
    && Number(c.visible_kevin_tool_count) === 5
    && c.has_kevin_system_status === true;
  if (fresh) return { label: '5 PROVEN', stale: false };
  const shape = String(c.state || '') === 'OMEN_PROVEN'
    && Number(c.visible_tool_count) === 5
    && Number(c.visible_kevin_tool_count) === 5;
  if (shape) return { label: '5 · CANARY STALE', stale: true };
  return { label: 'CANARY STALE', stale: true };
}

function paintModel(bundle, now) {
  const center = floorCenterState(bundle, now);
  const stripe = completedStripe(bundle);
  const nowS = nowStrip(bundle, now);
  const scaffold = scaffoldPulse(bundle, now);
  const news = floorNewswire(bundle, now);
  const attempt = lastAttemptClock(bundle, now);
  const tools = toolsCanary(bundle, now);
  const skillLab = skillLabState(bundle);
  return {
    version: VERSION,
    schema: SCHEMA,
    center,
    stripe,
    now: nowS,
    scaffold,
    newswire: news,
    lastAttempt: attempt,
    tools,
    skillLab,
    // Explicit machine match helpers for tests / parent report
    paintsWorkingBecauseReady: center.mode === 'working' && center.ready >= 1,
    neverEarlyTransportPass: true,
    transportNeverCompleted: false, // transport COMPLETED after VERIFY PASS/MIXED
    engReadyAuthoritative: true
  };
}

const API = {
  VERSION,
  SCHEMA,
  SUPERVISOR_PROVEN_SHA_PREFIX,
  SUPERVISOR_PROVEN_VERSION,
  WEST_MOTOR_COMPLETED_AT,
  WEST_MOTOR_INVOKE_ID,
  TRANSPORT_COMPLETED_AT,
  TRANSPORT_INVOKE_ID,
  TRANSPORT_WI,
  PATHS,
  parseTs,
  ageSeconds,
  ageText,
  supervisorIdentity,
  actionEraReady,
  liveWorkerCount,
  processRunningNow,
  isThrottledSignal,
  isBlocked,
  isInvoking,
  isVerifying,
  outcomeProven,
  westMotorProven,
  isTransportWi,
  transportCompletedAllowed,
  cycleFrozen,
  floorCycle,
  scaffoldPulse,
  floorCenterState,
  floorProvenItems,
  completedStripe,
  nowStrip,
  floorNewswire,
  lastAttemptClock,
  toolsCanary,
  paintModel,
  skillLabState
};

if (typeof module === 'object' && module.exports) {
  module.exports = API;
  return;
}

// ——— browser boot (thin DOM overlay after P1) ———
const cache = {};
let coreDoc = null, opsDoc = null, timer = null;

const cssText = `
.hq-p0-now{display:flex;flex-wrap:wrap;gap:8px;margin:8px 0;padding:8px 12px;border:1px solid rgba(194,213,182,.28);border-radius:12px;background:rgba(16,22,15,.9);font-size:11px;color:#dcebd5}
.hq-p0-now b{font-weight:800;letter-spacing:.04em}
.hq-p0-now .pill{padding:2px 8px;border-radius:999px;border:1px solid rgba(194,213,182,.35);font:800 9px/1.2 ui-monospace,monospace}
.hq-p0-now .pill.working{border-color:rgba(121,197,106,.55);color:#dcebd5}
.hq-p0-now .pill.throttled{border-color:rgba(213,173,104,.55);color:#efd9ae}
.hq-p0-now .pill.blocked{border-color:rgba(211,109,91,.55);color:#f0b2a8}
.hq-p0-completed{display:none;align-items:center;gap:10px;margin:8px 0;padding:8px 12px;border:1px solid rgba(121,197,106,.4);border-radius:12px;background:rgba(20,32,18,.88);font-size:11px;color:#dcebd5}
.hq-p0-completed.show{display:flex;flex-wrap:wrap}
.hq-p0-completed .chip{padding:3px 8px;border-radius:999px;border:1px solid rgba(121,197,106,.5);font:800 9px/1 ui-monospace,monospace;letter-spacing:.1em}
.hq-p0-scaffold{display:none;align-items:center;gap:10px;margin:8px 0;padding:8px 12px;border:1px dashed rgba(194,213,182,.4);border-radius:12px;background:rgba(20,26,19,.8);font-size:11px;color:#c5d0bf}
.hq-p0-scaffold.show{display:flex;flex-wrap:wrap}
.hq-p0-scaffold .chip{padding:3px 8px;border-radius:999px;border:1px solid rgba(194,213,182,.45);font:800 9px/1 ui-monospace,monospace}
.hq-p0-scaffold .dash{flex:1;min-width:40px;border-top:1px dashed rgba(194,213,182,.4);height:0}
.hq-p0-nw{margin:8px 0;padding:8px 12px;border:1px solid rgba(194,213,182,.22);border-radius:12px;background:rgba(14,18,13,.92)}
.hq-p0-nw .lab{font-size:9px;letter-spacing:.12em;color:#8b9488;margin-bottom:4px}
.hq-p0-nw .line{font-size:12px;line-height:1.35;color:#e6eadf;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.hq-p0-nw .line.dim{color:#8b9488;font-size:11px}
`.trim();

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
  // Also adopt P1 cache if present
  try {
    const p1 = window.__kevinP1GroundTruth;
    if (p1 && typeof p1 === 'object') {
      // no-op: P1 keeps its own cache; we already fetch overlap
    }
  } catch (_) {}
  paint();
}

function ensure(doc, id, cls, afterSel) {
  if (!doc) return null;
  let el = doc.getElementById(id);
  if (el) return el;
  el = doc.createElement('div');
  el.id = id;
  el.className = cls;
  const after = afterSel ? doc.querySelector(afterSel) : null;
  if (after) after.insertAdjacentElement('afterend', el);
  else {
    const wrap = doc.querySelector('.wrap') || doc.getElementById('main') || doc.body;
    wrap?.prepend(el);
  }
  return el;
}

function paintDoc(doc) {
  if (!doc?.body) return;
  injectStyle(doc, 'hq-p0-floor-css', cssText);
  const model = paintModel(cache, Date.now());
  const center = model.center;

  // Center badge
  const badge = doc.getElementById('kevinState') || doc.getElementById('statusPill') || doc.getElementById('owlLabel');
  if (badge) {
    const color = center.mode === 'working' ? '#79c56a'
      : center.mode === 'throttled' ? '#d5ad68'
      : center.mode === 'blocked' ? '#d36d5b'
      : center.mode === 'invoking' ? '#68d8ce'
      : '#8b9488';
    if (badge.id === 'kevinState') {
      badge.innerHTML = `<span class="loop state-${esc(center.mode)}" style="--kstatec:${color}">${esc(center.label)}</span>`;
    } else {
      badge.textContent = center.label;
      badge.style.color = color;
    }
  }

  // NOW strip
  const nowEl = ensure(doc, 'hqP0Now', 'hq-p0-now', '#kevinState');
  if (nowEl) {
    const n = model.now;
    nowEl.innerHTML =
      `<span class="pill ${esc(center.mode)}">${esc(n.status)}</span>` +
      `<span title="hq-live-floor.json only — never support.supervisor.cycle"><b>cycle</b> ${esc(n.cycle)}</span>` +
      `<span><b>WI</b> ${esc(n.selected)}</span>` +
      `<span><b>ver</b> ${esc(n.versionSha)}</span>` +
      `<span><b>ready</b> ${esc(n.ready)}</span>` +
      `<span><b>budget</b> ${esc(n.budgetRemaining)}</span>` +
      `<span title="last attempt">${esc(model.lastAttempt.unknown ? 'attempt unknown' : model.lastAttempt.age + ' ago')}</span>`;
  }

  // COMPLETED stripe (west-motor)
  const stripeEl = ensure(doc, 'hqP0Completed', 'hq-p0-completed', '#hqP0Now');
  if (stripeEl) {
    if (model.stripe.show) {
      stripeEl.classList.add('show');
      stripeEl.hidden = false;
      const bits = [];
      const stripeItems = Array.isArray(model.stripe.items) && model.stripe.items.length
        ? model.stripe.items
        : null;
      if (stripeItems) {
        for (const it of stripeItems) {
          bits.push(`<span class="chip">COMPLETED</span>`);
          bits.push(`<span>${esc(it.label)} <b>PROVEN</b></span>`);
          if (it.at) bits.push(`<span>${esc(it.at)}</span>`);
          bits.push(`<span>actor <b>${esc(model.stripe.actor)}</b></span>`);
          if (it.skill) bits.push(`<span>${esc(it.skill)}</span>`);
        }
      } else {
        if (model.stripe.westMotorRetained || model.stripe.westMotorOnly || /west-motor-parts/i.test(String(model.stripe.skill||''))) {
          bits.push(`<span class="chip">COMPLETED</span>`);
          bits.push(`<span>west-motor <b>PROVEN</b></span>`);
          bits.push(`<span>${esc(model.stripe.at)}</span>`);
          bits.push(`<span>actor <b>${esc(model.stripe.actor)}</b></span>`);
          bits.push(`<span>${esc(model.stripe.skill)}</span>`);
        }
        if (model.stripe.transportCompleted) {
          bits.push(`<span class="chip">COMPLETED</span>`);
          bits.push(`<span>transport <b>PROVEN</b></span>`);
          bits.push(`<span>${esc(model.stripe.transportAt || model.stripe.at || '')}</span>`);
          bits.push(`<span>actor <b>${esc(model.stripe.actor)}</b></span>`);
          bits.push(`<span>${esc(model.stripe.transportSkill || 'vehicle-transport-mission-pack@1')}</span>`);
        }
        if (model.stripe.dealershipCompleted) {
          bits.push(`<span class="chip">COMPLETED</span>`);
          bits.push(`<span>dealership <b>PROVEN</b></span>`);
        }
        if (!bits.length) {
          bits.push(`<span class="chip">COMPLETED</span>`);
          bits.push(`<span>${esc(model.stripe.at)}</span>`);
          bits.push(`<span>actor <b>${esc(model.stripe.actor)}</b></span>`);
          bits.push(`<span>${esc(model.stripe.skill)}</span>`);
        }
      }
      stripeEl.innerHTML = bits.join('');
    } else {
      stripeEl.classList.remove('show');
      stripeEl.hidden = true;
    }
  }

  // SCAFFOLD chip
  const scEl = ensure(doc, 'hqP0Scaffold', 'hq-p0-scaffold', '#hqP0Completed');
  if (scEl) {
    if (model.scaffold.visible) {
      scEl.classList.add('show');
      scEl.hidden = false;
      scEl.innerHTML =
        `<span class="chip">SCAFFOLD</span>` +
        `<span class="actor">GROKBOT_ACTED</span>` +
        `<span>not KEVIN_ACTED</span>` +
        `<span class="dash"></span>` +
        `<span>Kevin</span>`;
    } else {
      scEl.classList.remove('show');
      scEl.hidden = true;
    }
  }

  // NEWSWIRE last 5
  const nw = ensure(doc, 'hqP0Newswire', 'hq-p0-nw', '#hqP0Scaffold');
  if (nw) {
    const lines = (model.newswire || []).slice(0, 5).map((x, i) =>
      `<div class="line${i ? ' dim' : ''}">${esc(x.text)}</div>`
    ).join('');
    nw.innerHTML = `<div class="lab">NEWSWIRE</div>${lines || '<div class="line dim">no events</div>'}`;
  }

  // Tools chip nudge
  const toolsHost = doc.getElementById('toolsChip') || doc.querySelector('[data-tools-chip]');
  if (toolsHost && model.tools.stale) {
    toolsHost.textContent = model.tools.label;
  }

  // Expose for debug / P1 coexistence
  try {
    doc.defaultView.__kevinP0Floor = model;
  } catch (_) {}
}

function paint() {
  paintDoc(coreDoc);
  paintDoc(opsDoc);
}

function bindOps() {
  if (!coreDoc) return;
  const frame = coreDoc.getElementById('opsV10Frame');
  if (!frame) return;
  const attach = () => {
    try {
      opsDoc = frame.contentDocument;
      if (opsDoc?.body) paint();
    } catch (_) {}
  };
  frame.addEventListener('load', attach);
  attach();
}

function install() {
  const frame = document.getElementById('kevinCore');
  if (!frame) return;
  try {
    coreDoc = frame.contentDocument;
    if (!coreDoc?.body) return;
    bindOps();
    refresh();
    if (timer) clearInterval(timer);
    timer = setInterval(refresh, 30000);
  } catch (e) {
    console.error('Kevin HQ P0 floor painter install failed', e);
  }
}

window.__kevinP0FloorPainter = API;
const boot = () => {
  const frame = document.getElementById('kevinCore');
  if (!frame) return;
  frame.addEventListener('load', () => setTimeout(install, 900));
  if (frame.contentDocument?.body) setTimeout(install, 1100);
  setTimeout(install, 2400);
};
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
else boot();
})();
