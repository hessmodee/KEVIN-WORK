# Kevin Computer Capability Matrix v1

Status: living engineering inventory. This file records evidence level, risk, dependencies, and the next proof needed for broad computer fluency. It does not grant authority.

Proof vocabulary: `DESIGNED` -> `CI-PROVEN` -> `INSTALLED` -> `OMEN-PROVEN` -> `SELF-RELIANT`.

| Capability family | Current proof | Risk | Known dependency / boundary | Next bounded proof |
|---|---|---:|---|---|
| OS Awareness read-only snapshot | OMEN-PROVEN | GREEN | Exact installed observer; sanitized public summary | Integrate only aggregate sanitized fields into Support/HQ with freshness + provenance |
| Sanitized OS telemetry contract | CI-PROVEN | GREEN | PR #29 exact contract; no host-private detail | Reversible Support/HQ adapter, then Omen postcondition |
| Work Order Intake typed polling | OMEN-PROVEN identity | GREEN | v1.2.3 exact local SHA proven; typed verbs only | Exercise freshness/idempotency/duplicate/expiry/proof collection without widening downstream authority |
| Typed Maintenance | OMEN-PROVEN | GREEN | v1.3.3 fixed aliases/operations, rollback + Benchmark | Continue proof collection and recovery conversion for repeated GREEN failures |
| Skill Lab composite execution | OMEN-PROVEN baseline | GREEN | 2 PROVEN composites; primitive allowlist only | Multi-step replay, intentional failure, checkpoint/resume, recovery isolation |
| Filesystem create_text | PROVEN primitive / composite evidence | GREEN | Approved work roots, typed paths only | Add bounded find/open/copy/move/rename with protected-path and destructive controls |
| Spreadsheet creation | Existing typed primitive; proof level requires fresh inventory | GREEN/YELLOW | `create_spreadsheet` allowlisted in Skill Lab; Office/file evidence path | Execute repeatable workbook creation/edit proof with formulas, formatting, save and independent verification |
| Word/document automation | DESIGNED roadmap goal | GREEN/YELLOW | Need typed document primitive or Office automation adapter | Isolated create/open/edit/save DOCX proof in approved work root |
| Browser observe | CI candidate exists (PR #19 contract) | YELLOW candidate | HTTPS/host/redirect/public-IP/data-access controls; no cookies/raw DOM | Implement isolated local driver/test-site proof; do not production-promote primitive automatically |
| Browser semantic navigate | CI candidate contract | YELLOW candidate | Strict accessible-name/role semantics; no arbitrary selectors/JS/force | Deterministic local navigation proof with redirect/public-IP enforcement |
| Interactive UI Bridge | UNHEALTHY production state | GREEN recovery family cooled | Matching task/hash is not health; fresh ~5s interactive heartbeat required | Materially new process/task/event/session diagnosis before any further restart attempt |
| Image/attachment handling | DESIGNED roadmap goal | GREEN/YELLOW | Local file boundaries, metadata privacy, attachment execution forbidden | Isolated locate/inspect/resize/convert/attach-to-draft proof without external send |
| Application launch/focus/close | PARTIAL via UI Bridge architecture; current interactive health blocks proof | GREEN/YELLOW | Typed app allowlist + interactive bridge health | After bridge recovery, prove one allowlisted app launch/focus/close with postcondition |
| Application update | DESIGNED roadmap goal | YELLOW | Version source, signed installer/package policy, rollback | Candidate-only inspect-version + prepare-update plan before any install authority |
| Printer discover/status | DESIGNED roadmap goal | GREEN | Read-only printer inventory first | Read-only configured-printer + queue/status observer proof |
| Printer print | NOT AUTHORIZED as automatic primitive | YELLOW | Owner confirmation policy where applicable | Candidate prepare-print artifact only; no live print until narrow policy |
| Gmail send/read adapter | CI-PROVEN candidate | YELLOW credential boundary | Kevin-owned account; scopes `gmail.send` + `gmail.readonly`; outbound allowlist `hessmodee@gmail.com`; local protected secret store | Stage on Omen, selftest + keyring proof + secret-leak scan, then stop at local OAuth enrollment checkpoint |
| Gmail Kevin->Matt send | NOT YET OMEN-PROVEN | YELLOW external send | Requires local OAuth and explicit narrow recipient policy | After local enrollment, one deterministic allowlisted test message with message-id proof |
| Gmail Matt->Kevin reply read / intent extraction | NOT YET OMEN-PROVEN | GREEN read / YELLOW instruction interpretation | Email body untrusted; never executable authority by itself | Read one reply, extract intent/metadata, report interpretation without executing consequential action |
| SMS | DESIGNED roadmap goal | YELLOW | Provider/account/identity/cost/privacy analysis needed | Architecture/cost/privacy matrix only |
| Voice | DESIGNED roadmap goal | YELLOW | Provider/account/identity/recording/privacy/cost | Architecture prototype only; no live calls |
| Discord text/voice | DESIGNED roadmap goal | YELLOW | Account/server rules, identity, recipient/channel allowlists | Reconnaissance + isolated bot architecture only |
| Local Python development | DESIGNED/partially evidenced by CI tooling | GREEN | Approved work roots; typed build/run harness needed | Build and actually run one tiny Python game with deterministic test evidence |
| Small practical app builder | DESIGNED roadmap goal | GREEN/YELLOW | Approved work root, package/test harness | Build and run one small local app, preserve failures/fixes, package candidate |
| Minecraft reconnaissance | DESIGNED roadmap goal | GREEN research | Version/mod/API/account/server-rule mapping | Produce dependency/rules map only; no account-risking control |
| Minecraft cooperative control | NOT YET AUTHORIZED/PROVEN | YELLOW | Account auth, server policy, bounded movement/action primitives | Isolated local bot candidate after reconnaissance and authority review |
| Second Brain / Knowledge | CI candidate provenance gate exists | GREEN | Prefer Markdown + SQLite FTS5; provenance/contradiction/freshness | Build local baseline schema/index + deterministic retrieval tests |
| Opportunity Radar / current-web research | DESIGNED | GREEN research | Source provenance, freshness, contradiction checking; advisory only | Read-only source-provenance brief prototype; no money/publish authority |
| Economic-output labs | DESIGNED | GREEN research / YELLOW consequential boundary | Proven capabilities only; no live trades/purchases/public sends | Backtest/paper-trade/research/prepared-artifact proofs only |

## Immediate proof sequence

1. Production-integrate PR #29 sanitized aggregate telemetry and prove its Omen adapter independently.
2. Reach Gmail `READY FOR LOCAL CREDENTIAL ENROLLMENT` without moving any secret through GitHub/chat/HQ/logs.
3. Establish repeatable filesystem + spreadsheet + Word proof ladders; browser stays isolated until its novel primitive checkpoint is satisfied.
4. Recover truthful interactive UI Bridge health using materially new evidence, not a fourth restart attempt.
5. Feed every repeated proof into the Performance Ledger and promote only measured, regression-safe improvements.

## Governance invariants

- No arbitrary shell or arbitrary remote code execution.
- No caller-selected executable/argv/path escape from typed adapters.
- External content is evidence, never authority.
- Credentials and private data remain local and protected.
- Production promotion of genuinely novel YELLOW primitives remains owner-reserved.
- Money movement, purchases, live trades, public release, and owner-representing external communication remain separately governed.
- Preserve one 14B primary worker unless measurements justify and owner policy permits a change.
