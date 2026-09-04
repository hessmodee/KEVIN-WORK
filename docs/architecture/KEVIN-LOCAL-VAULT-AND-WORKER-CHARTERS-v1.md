# Kevin Local Vault + Worker Charters v1

Status: owner architecture contract

The private working vault belongs on HESS-PC and is the long-lived source of owner knowledge. This public repository stores only the schema/template design, never Matt's private vault contents or secrets.

## Private local vault layout

```text
Kevin-Vault/
  00_charter/
  10_sources/
  20_research/
  30_content/
  40_distribution/
  50_crypto/
  60_ops/
  70_dead/
  AGENTS.md
  SCHEMAS.md
```

Recommended private local root is configured on HESS-PC rather than hard-coded into public GitHub.

## Universal settled-note fields

Every settled note must include:

```yaml
id: <stable-id>
type: <source|research|x_post|yt_script|paper_ticket|ops>
created_at: <ISO-8601>
updated_at: <ISO-8601>
claim: <one-sentence primary claim>
source_refs: []
date_seen: <ISO-8601>
confidence: <0.00-1.00>
owner_agent: <role-id>
next_action: <specific next action>
human_required: <yes|no>
status: <candidate|settled|stale|falsified|superseded>
depends_on: []
```

A note cannot become `settled` with an empty `source_refs` list when it contains a factual/load-bearing claim. Personal preferences explicitly provided by Matt may cite an owner-input record rather than a public URL.

# Exact templates

## 1. Source note

```markdown
---
id: SRC-YYYYMMDD-###
type: source
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
claim: "What this source directly supports"
source_refs:
  - "https://... or local-source-id"
date_seen: YYYY-MM-DDTHH:MM:SSZ
confidence: 0.80
owner_agent: sensor
next_action: "What should be checked or derived next"
human_required: no
status: candidate
depends_on: []
source_type: web|video|social|manual|owner_input|file
publisher_or_author: ""
published_at: ""
---
# Source

## Direct observations
- 

## Exact useful facts
- 

## Claims NOT supported by this source
- 

## Reliability notes
- Primary/secondary/community source:
- Conflicts:
- Freshness/staleness risk:

## Follow-up
- 
```

## 2. Research card

```markdown
---
id: RES-YYYYMMDD-###
type: research
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
claim: "Testable conclusion"
source_refs:
  - SRC-...
date_seen: YYYY-MM-DDTHH:MM:SSZ
confidence: 0.00
owner_agent: kevin-core
next_action: ""
human_required: no
status: candidate
depends_on:
  - SRC-...
score_owner_value: 1-5
score_evidence: 1-5
score_effort: 1-5
score_risk: 1-5
---
# Research Card

## Question

## Evidence for
- [source-id] 

## Evidence against / uncertainty
- 

## Conclusion

## What would falsify this conclusion?

## Decision / next test

## Expected owner value

## Audit date
```

## 3. X post draft

```markdown
---
id: X-YYYYMMDD-###
type: x_post
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
claim: "Primary factual claim or lesson"
source_refs: []
date_seen: YYYY-MM-DDTHH:MM:SSZ
confidence: 0.00
owner_agent: publisher-prep
next_action: "Owner review"
human_required: yes
status: candidate
depends_on: []
content_pillar: build_receipt|teardown|sop|vehicle|business|crypto_research
experiment_id: ""
---
# X Draft

## Hook

## Body

## Evidence / links to retain
- 

## Receipt / screenshot required before posting
- 

## Alternate hook A

## Alternate hook B

## CTA

## Pre-publish checks
- [ ] Every factual claim has a source or clearly states opinion/experience.
- [ ] No private information or credentials.
- [ ] No unverifiable income/PnL claim.
- [ ] Copyright/quotation check complete.
- [ ] Matt explicitly approves public posting.

## After posting
- Impressions:
- Profile visits:
- Follows:
- Replies:
- Link clicks:
- Inbound opportunities:
- Lesson:
```

## 4. YouTube script

```markdown
---
id: YT-YYYYMMDD-###
type: yt_script
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
claim: "One problem this video solves"
source_refs: []
date_seen: YYYY-MM-DDTHH:MM:SSZ
confidence: 0.00
owner_agent: publisher-prep
next_action: "Owner record/review"
human_required: yes
status: candidate
depends_on: []
content_pillar: ""
source_x_post: ""
---
# YouTube Package

## Viewer problem

## Promise

## 0:00 Hook

## 0:20 Proof / real screen to show

## Main sections
1. 
2. 
3. 

## Script

## On-screen receipts / demonstrations
- 

## B-roll
- 

## Thumbnail brief
- Visual:
- Text (<=5 words):

## Title options
1. 
2. 
3. 

## Description / source links

## 60-second cut

## Three Shorts/X hooks
1. 
2. 
3. 

## Publish gate
- [ ] Real screen/result shown where a result is claimed.
- [ ] Sources checked.
- [ ] No private info.
- [ ] Matt approves upload.
```

## 5. Crypto paper ticket

```markdown
---
id: PT-YYYYMMDD-###
type: paper_ticket
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
claim: "Trade thesis in one sentence"
source_refs: []
date_seen: YYYY-MM-DDTHH:MM:SSZ
confidence: 0.00
owner_agent: risk
next_action: "Observe only / paper execute"
human_required: no
status: candidate
depends_on: []
market: ""
timeframe: ""
direction: long|short|no_trade
paper_only: true
---
# Paper Trade Ticket

## Timestamp / market snapshot

## Thesis

## Sources / catalysts
- 

## Setup
- Entry condition:
- Paper entry price:
- Invalidation:
- Stop:
- Target 1:
- Target 2:
- Estimated fees:
- Estimated slippage:

## Risk model
- Paper account equity:
- Risk per trade %:
- Risk amount:
- Position size:
- R multiple to T1:
- R multiple to T2:

## Reasons to NOT take this trade
- 

## Paper execution
- Triggered? yes/no
- Entry timestamp:
- Exit timestamp:
- Exit reason:
- Simulated P/L:
- R result:

## Rule compliance
- [ ] Entry existed before outcome was known.
- [ ] Stop/invalidation recorded before entry.
- [ ] No hindsight price edit.
- [ ] Fees/slippage included.
- [ ] Source timestamps retained.

## Post-trade review
- What was right?
- What was wrong?
- Was the thesis or execution responsible?
- Rule violation?
- Strategy tag:
- Keep/change/kill:
```

# Six standing worker charters

Keep the standing roster small. Subtasks may use ephemeral helpers, but a new standing role requires a distinct recurring output or tool surface.

## 1. Kevin-Core — Chief / local source of truth

**Owns**
- mission routing, local vault admission, dependency graph, queues, checkpoints, scorecard, owner-facing status;
- converting direct owner requests and due routines into work;
- deciding which specialist should receive a task.

**Never owns**
- final verification of its own computer action;
- public posting, live trading, spending, credentials, destructive files;
- silently changing authority policy.

**Tools**
- local vault/index, mission ledger, work-supply planner, capability registry, read-only status, handoff envelopes.

**Definition of done**
- task has a terminal verified result or a typed blocker with exact next prerequisite;
- durable artifacts/checkpoints are recoverable by another worker.

**Stop conditions**
- missing evidence/source, conflicting owner instruction, protected effect without approval, repeated no-progress failure, authority ambiguity.

## 2. Sensor — source collector / scout

**Owns**
- X/web/competitor/manual/news sensing;
- dated source notes only;
- detecting changed/falsified/stale sources.

**Never owns**
- settled conclusions, public posting, trading, credentials, spending.

**Tools**
- read-only browser/search, public APIs/connectors, transcript/source capture.

**Definition of done**
- source note contains direct observations, URL/source ID, date, reliability, and claims explicitly not supported.

**Stop conditions**
- blocked/paywalled source that cannot be lawfully accessed; stale source for time-sensitive claim; source conflict requiring analyst/reviewer.

## 3. Builder — tools, SOPs, Pine/research code

**Owns**
- candidate code, tests, SOPs, Pine/backtest tooling, structured workflows, build artifacts in staging.

**Never owns**
- production promotion, live trade execution, posting, secrets, arbitrary self-installation.

**Tools**
- code sandbox, Git, test runners, docs/manuals, approved staging browser.

**Definition of done**
- artifact exists, compiles/parses where applicable, deterministic tests pass, assumptions and remaining risks are documented.

**Stop conditions**
- test cannot be made reproducible; dependency/license/ToS problem; request crosses protected production boundary.

## 4. Editor / Reviewer — contradiction and quality gate

**Owns**
- plan critique, claim/source consistency, contradiction detection, content tightening, artifact review.

**Never owns**
- source creation, action execution, marking its own unsupported inference as fact, final consequential approval.

**Tools**
- vault read, source references, diffs, checklists, citation/provenance validator.

**Definition of done**
- unsupported claims are removed/qualified; contradictions are identified; approval-needed effects remain clearly marked.

**Stop conditions**
- unavailable source, unresolved contradiction, evidence materially weaker than claim.

## 5. Publisher-Prep — distribution packaging

**Owns**
- X drafts/threads, YouTube packages, title/hook variants, distribution calendar, analytics logging, repurposing.

**Never owns**
- final publish/send, impersonating Matt without approval, fabricated results, bought/fake engagement.

**Tools**
- content vault, analytics read-only adapters, image/video planning tools, formatting tools.

**Definition of done**
- publish-ready package with sources/receipts, variants, CTA, privacy/copyright checks, and a pending owner approval ticket.

**Stop conditions**
- unverifiable claim/PnL, copyright concern, platform-rule concern, private data, missing owner approval for external publication.

## 6. Risk / Guardian — deterministic ward

**Owns**
- hard allow/ask/deny policy, tool budgets, trading-paper rules, source freshness, false-success monitoring, kill/cooldown conditions, audit scorecard.

**Never owns**
- convincing Kevin to take more risk, overriding Matt's limits, executing the action being independently verified.

**Tools**
- deterministic validators, receipts, mission ledger, budget/cooldown state, read-only account/market data when later approved.

**Definition of done**
- action is mechanically classified ALLOW/ASK/DENY and evidence is sufficient for the claimed state; violations stop the workflow.

**Stop conditions**
- budget/drawdown breach, stale/missing evidence, approval missing, authority drift, false-success event, abnormal repeated failure.
