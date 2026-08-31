# Kevin HQ Truth Architecture v1

Date: 2026-08-31
Status: OWNER-DIRECTED / PUBLIC-SAFE OBSERVABILITY CONTRACT

## Purpose

Kevin HQ exists to help Matt answer, in seconds:

1. Is Kevin actually healthy?
2. Is Kevin actually doing useful work right now?
3. What is the exact current owner objective and proof boundary?
4. What has Kevin genuinely proven recently?
5. What is blocked, stale, failing, cooled, or contradictory?
6. How autonomous is Kevin becoming, and what Bess responsibility is being retired next?
7. Can every important statement on the screen be traced to a named source with a timestamp and freshness rule?

The HQ must reduce cognitive load. It must never make activity look like accomplishment or old evidence look current.

## Public HQ vs private control surface

The GitHub Pages HQ is a **sanitized public-safe observability mirror**. It is not the long-term privileged admin/control surface.

Public HQ may show:
- metadata-only health;
- current/sanitized task identity;
- source freshness;
- proof levels;
- transfer levels;
- resource load;
- queue counts;
- sanitized failure families;
- benchmark/eval results;
- public-safe recent milestones.

Public HQ must not show:
- credentials/tokens;
- private message bodies;
- private host paths/config dumps;
- raw prompts/evaluator text;
- unrestricted admin controls;
- arbitrary command input;
- sensitive recipient/account identifiers beyond explicitly public-safe metadata.

The future private owner HQ should use the authenticated local/OpenClaw control surface or a similarly authenticated private transport (for example a locally paired/Tailscale-style path), not turn GitHub Pages into an admin console.

## Information hierarchy

HQ should progress from **decision -> evidence -> detail**, similar to mature SRE/GitOps/agent-observability systems.

### Level 1 — Command summary
Always visible:
- Platform health
- Autonomy health
- Work now
- Benchmark/domain proof
- Proven skill count
- T4/T5 ownership count
- Data quality/freshness

### Level 2 — Attention and proof
Immediately below:
- active blockers/contradictions;
- stale/expired/duplicate slots;
- cooled failure families;
- recent meaningful proof transitions;
- exact next production boundary.

### Level 3 — Source ledger / drilldown
Operator detail:
- source file/feed;
- source class;
- generated timestamp;
- evidence age;
- expected cadence;
- freshness classification;
- what claims the source is allowed to support.

### Level 4 — topology/resources/history
Useful deeper diagnostics:
- worker topology;
- CPU/RAM/GPU;
- task/event history;
- detailed capability/transfer ledger;
- raw sanitized receipts.

Decorative/evolution elements must never outrank command truth.

## Source classes

### LIVE / PERIODIC
Expected to refresh on a cadence. Age is health-significant.

- `reports/dashboard-state.json` — live operational mirror; expected around the HQ live-pulse cadence.
- `reports/support-latest.json` — platform/governance/cron/benchmark/supervisor support snapshot.
- `reports/engineering/latest.json` — engineering relay, Skill Lab, UI Bridge and Benchmark engineering snapshot.
- `reports/autonomy-latest.json` — autonomy/work-conservation state when the autonomy collector is refreshing correctly.

These sources must visibly become DELAYED/STALE instead of silently retaining the last good label.

### EVENT-DRIVEN
Age is informative but not automatically a failure.

- `reports/control-plane-latest.json` — most recent typed work-order acknowledgement.
- maintenance latest receipt — most recent maintenance outcome.

A terminal old event may be historical rather than stale. A pending/current slot must be evaluated against its expiry/idempotency semantics.

### CHECKPOINT / DOCTRINE
Not a live health signal. Age must be shown, but these remain valid until superseded by fresher evidence.

- `reports/responsibility-transfer-latest.json`
- `reports/autonomy-master-scorecard.json`
- `AI-HANDOVER.md`
- `inbox/CURRENT_TASK.md`
- owner authorization/doctrine files

A checkpoint is never allowed to override fresher runtime evidence.

## Freshness rules

Use source-specific cadence, not one global OFFLINE threshold.

Suggested public-HQ windows:

- Dashboard live mirror: FRESH <= 2 min; DELAYED <= 6 min; STALE > 6 min.
- Support snapshot: FRESH <= 6 min; DELAYED <= 15 min; STALE > 15 min.
- Engineering snapshot: FRESH <= 5 min; DELAYED <= 12 min; STALE > 12 min.
- Autonomy snapshot: FRESH <= 15 min; DELAYED <= 30 min; STALE > 30 min.
- Event-driven receipts: RECENT/HISTORICAL, with timestamp visible.
- Checkpoints: CHECKPOINT, with timestamp visible; never present as live telemetry.

Browser parsing must normalize PowerShell/.NET timestamps with more than three fractional digits before `Date.parse`.

## Claim-support contract

### Platform health
May be supported by fresh Support + dashboard service health + Benchmark. It must **not** imply autonomy is healthy.

### Autonomy health
Must come from `autonomy-latest.json` plus fresh work-conservation evidence. Platform 30/30 cannot turn `NEEDS_REVIEW` into HEALTHY.

### Work now
Must be supported by an active task/worker with fresh timestamp. `last_mission`, a scheduled task, or an enabled cron does not equal current work.

### Proven skill count
Must come from Skill Lab/Engineering proven records, not a hard-coded capability array.

### Capability proof
Must preserve:
`DESIGNED -> CI-PROVEN -> INSTALLABLE -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

### Responsibility ownership
Must preserve T0-T5 separately from technical proof.

### Current blocker
Must identify a current failure family, stale source, expired slot, drift, or exact owner checkpoint. Old failures remain history, not current blocker, unless still reproduced/freshly evidenced.

## No-spin presentation rules

Do not use the following as headline accomplishment metrics:
- raw Supervisor/Forge cycle count;
- heartbeat/pulse count;
- PONG/model smoke tests;
- number of commits;
- task/hash presence;
- CI-only candidates;
- repeated duplicate/expired acknowledgements;
- "READY" lane availability as proof that the capability is learned.

Forge iteration numbers may appear only in diagnostic context, especially to expose repeated failure/churn.

## Current HQ audit findings (2026-08-31)

### Keep
- Ops Floor topology as a visual live-activity model, with truth labels.
- CPU/RAM/GPU and 24h trend when timestamps are real and sample semantics are clear.
- Benchmark 30/30 / critical count as platform regression evidence.
- exact worker/task freshness and active-worker counts.
- recent meaningful events after repetitive heartbeat/tick collapse.

### Consolidate/relabel
- "Health" -> **Platform health**, separate from **Autonomy health**.
- "Current operation" / "Active mission" / "Current action" -> one **Work now** claim plus drilldown.
- "Evidence age" -> **Data quality** with per-source ledger.
- service chips -> runtime availability only; never capability proof.

### Remove/de-emphasize from owner decision view
- hard-coded roadmap completion based on static capability arrays;
- hard-coded Chat QA/proven claims that are not coming from the newest proof ledger;
- decorative "Kevin evolution level" as an operational KPI;
- fixed execution roadmap that can diverge from `CURRENT_TASK.md` / autonomy master scorecard;
- repeated cycle counts as progress;
- promotion="blocked" cards that add little decision value without the actual candidate/proof context.

### Known current contradictions that HQ must expose
At the time of this audit:
- Platform Benchmark can be 30/30 while autonomy is `NEEDS_REVIEW`.
- Forge can be actively generating/recovering while the autonomy/work-selection layer still has semantic defects.
- Engineering Relay may be healthy as a scheduler while its current request slot is expired/rejected.
- UI Bridge task/hash presence can coexist with a heartbeat that is many hours stale.

HQ must show these as separate dimensions instead of collapsing them to one green/red status.

## Design influences / research crosswalk

- **Grafana:** dashboard must answer a question, reduce cognitive load, avoid dashboard sprawl, use meaningful thresholds, and refresh according to source cadence rather than faster than data changes.
- **Argo CD:** top status should summarize health, conditions/severity, and age; topology/resource tree is useful after the status summary.
- **OpenClaw Tasks:** tasks are an activity ledger (`queued -> running -> terminal`), not the scheduler itself; stale queued/running conditions belong in audit findings; completion is push-driven rather than status-poll theater.
- **OpenClaw Audit:** metadata-only provenance/status/outcome records are a strong model for public-safe traceability without exposing message contents.
- **OpenClaw Control UI/Dashboards:** privileged dashboards belong behind authenticated gateway/device access. Public Kevin HQ should stay read-only/sanitized.
- **Langfuse:** one agent run should be traceable as a unit of work, with stable operation names, nested tool steps, latency/errors/quality scores, and low-noise observations. Aggregate metrics should link back to the triggering trace.
- **OpenTelemetry:** include only telemetry fields with clear user value; use stable low-cardinality names, timestamps, error types, and state-change events rather than dumping every possible attribute.

## Implementation direction

### v1 — Truth Console (now)
Add a persistent Truth Console to Kevin HQ which directly reads the latest public-safe report sources and shows:
- Platform health
- Autonomy health
- Work now
- Benchmark
- proven skills
- T4/T5 ownership
- data-quality/freshness
- attention items
- recent real proof
- per-source ledger

It must refresh independently of legacy Overview rendering and visibly label checkpoint vs periodic/event evidence.

### v2 — Canonical HQ truth model
Move aggregation from browser inference to a local sanitized `hq-truth-latest.json` generated on the Omen from the same contracts. Browser remains a renderer. Add a schema and deterministic tests for freshness/contradictions/claim support.

### v3 — Trace/task drilldown
Where locally supported, derive public-safe task/audit summaries from OpenClaw Tasks/Audit:
- trace/task ID pseudonym;
- operation family;
- queued/start/end times;
- outcome;
- bounded progress;
- tool/eval count;
- retry/failure family;
- proof/transfer impact.

### v4 — private live owner HQ
Use authenticated local/private Gateway access for chat, task control, approvals, detailed traces and device/admin actions. Keep the public Pages mirror sanitized and read-only.

## Success criteria

HQ is successful when Matt can look at it and correctly answer within ~10 seconds:
- what Kevin is doing now;
- whether that work is useful or spinning;
- platform vs autonomy health;
- the freshest trustworthy evidence;
- what changed/proved recently;
- the exact blocker/next boundary;
- whether Kevin is becoming less dependent on Bess.

If the dashboard cannot support a displayed claim with a named source and timestamp, the claim must be removed or visibly labeled as a checkpoint/estimate/legacy view.
