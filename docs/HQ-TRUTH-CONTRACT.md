# Kevin HQ Truth Contract

Kevin HQ is an **operations console**, not a narrative dashboard. Every live claim must be derived from a named authoritative source with a freshness rule. Historical or checkpoint data must never masquerade as current runtime state.

## Owner questions the default view must answer

1. What is Kevin doing right now?
2. Is the platform healthy enough to trust?
3. What actually needs attention?
4. What useful capability is proven, learning, blocked, or unavailable?
5. What changed recently?
6. Can Matt talk to Kevin immediately?
7. Where is the one canonical handover?

Anything that does not materially help answer one of those questions belongs in System/Diagnostics, History, or the repository—not the default Command view.

## Authoritative live sources

| Claim | Source | Freshness expectation | HQ behavior when stale |
|---|---|---:|---|
| current task / services / load | `reports/dashboard-state.json` | 120 s fresh, 360 s delayed | never infer WORKING from stale task text |
| platform / benchmark / core schedulers | `reports/support-latest.json` | 360 s fresh, 900 s delayed | show UNVERIFIED/STALE rather than HEALTHY |
| Relay / Skill Lab / UI Bridge | `reports/engineering/latest.json` | 180 s fresh, 360 s delayed | show delayed liveness; do not reuse old heartbeat as current |
| scheduled autonomy selection | `reports/autonomy-continuation-latest.json` | 900 s fresh, 1800 s delayed | distinguish selection from outcome proof |
| full autonomy reconciliation | `reports/autonomy-latest.json` | event/checkpoint | label RECENT/HISTORICAL; never pollute current WORKING state |
| governed work backlog | `inbox/autonomy/work-items.json` | checkpoint/input | expose eligible vs blocked; never convert blocked work to idle |
| responsibility-transfer proof | `reports/responsibility-transfer-latest.json` | checkpoint | proof/History/System only |
| public newswire | `reports/newswire-latest.json` | 6 h | warn when stale; never fabricate headlines |
| canonical handover | `AI-HANDOVER.md` | semantic checkpoint | current runtime reports outrank its snapshot timestamps |

## Truth states

HQ must use these semantics:

- **WORKING** — fresh evidence shows an active evidence-producing task/worker. A schedule, old task string, animation, or model turn is not work.
- **ELIGIBLE WORK** — governed work exists and required capability/prerequisites are available.
- **BLOCKED WORK** — owner-valued work exists but a prerequisite/tool/proof is missing. Show the top blocker and next safe prerequisite.
- **TRUE IDLE** — no active execution, no eligible owner work, no blocked owner backlog, and no due guardian/maintenance/growth obligation.
- **UNVERIFIED / STALE** — required evidence is outside its freshness contract. Do not downgrade this to a reassuring READY/HEALTHY label.

## Capability language

HQ must distinguish:

- **PROVEN** — replayable semantic proof exists.
- **AVAILABLE** — typed production path is currently installed/usable under existing authority.
- **LEARNING** — staged/candidate work exists but proof is incomplete.
- **BLOCKED** — required prerequisite/authority/tool is absent.
- **RETIRED / HISTORY** — preserved evidence, not a current capability claim.

Do not label a capability learned or available merely because source code, CI, a model response, or a scheduler exists.

## UI architecture

The owner-facing information architecture is intentionally small:

1. **Command** — current truth, high-signal attention, next priorities, verified outcomes.
2. **Ops Floor** — active/recent meaningful work and mission detail.
3. **Work Log** — meaningful outcomes and receipts, not telemetry spam.
4. **Skills** — competency ledger with proof status.
5. **System** — deeper services, freshness, diagnostics, and technical evidence.

Direct **Talk to Kevin** and **Handover** actions remain persistent outside the iframe.

## Overlay ownership

The production wrapper should keep the overlay stack minimal and non-overlapping:

- `hq-overrides-v1.js` — integration/hash + Newswire only.
- `hq-truth-v2.js` — authoritative source collection, contradiction detection, deep truth console.
- `hq-owner-refinement-v3.js` — owner-facing five-tab information architecture and concise rendering.
- `hq-growth-v1.js` — continuous-growth source/runtime distinction.

Retired from the production wrapper because they duplicate or decorate newer behavior:

- `hq-owner-refinement-v2.js`
- `hq-fun-v2.js`

Retired files may remain temporarily as historical source until repository cleanup proves there are no consumers, but they are not production dependencies.

## Performance rules

- Prefer one fetch per authoritative source per refresh window; avoid independent overlays fetching the same evidence unless their cadence/contract differs materially.
- No decorative polling loops.
- No hidden cards that continue to fetch/update behind newer UI.
- Cap history payloads and rendered rows.
- Mobile layout is the acceptance baseline, not an afterthought.

## Change acceptance

Any HQ change is complete only when:

1. retained live claims map to this contract;
2. JavaScript parses and static invariants pass;
3. default view contains no obsolete current-state claims;
4. mobile controls remain reachable;
5. fresh Support/Engineering evidence still reports the runtime baseline without authority drift;
6. Benchmark remains 30/30 critical 0 after any change that crosses onto HESS-PC runtime code.

HQ source-only cleanup does not by itself prove HESS-PC runtime health. Runtime claims always come from fresh machine-published evidence.
