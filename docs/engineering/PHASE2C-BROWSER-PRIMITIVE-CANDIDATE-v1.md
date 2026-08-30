# Phase 2C Browser Primitive Candidate v1

Status: DESIGN CANDIDATE ONLY — NO AUTHORITY PROMOTION
Date: 2026-08-30

## Goal

Add browser observation and typed semantic navigation without introducing arbitrary code execution, arbitrary selector execution, coordinate clicking, external submission, purchases, credential access, or silent consequential actions.

## Evidence basis

Playwright recommends user-facing locators, especially role + accessible name, labels, and text; locators provide auto-waiting/retry behavior and strictness when an action would match multiple elements. Chromium DevTools Protocol exposes an Accessibility domain that can retrieve/query the accessibility tree by accessible name and role.

## Candidate primitive order

### 1. `browser_observe`

Read-only.

Returns only sanitized metadata/evidence:

- current URL origin/path (redacted query/fragment policy where needed)
- page title
- navigation/load state
- bounded accessibility-tree summary (role, accessible name, state)
- viewport screenshot hash/path under governed evidence storage
- count of interactive semantic targets

Forbidden:

- DOM mutation
- JavaScript evaluation supplied by caller
- credentials/cookies/storage dumps
- arbitrary file reads
- form submission

### 2. `browser_navigate`

Typed navigation only.

Input:

- absolute HTTPS URL
- optional explicit allowlisted HTTP exception for local test harness only

Checks:

- scheme policy
- normalized URL
- host/domain policy
- pre/post URL evidence
- timeout and bounded redirects
- no `javascript:`, `data:`, `file:`, custom protocols, or embedded credentials

### 3. `browser_semantic_interact`

Not eligible for production promotion until observation/navigation are independently proven.

Target contract uses semantic fields only:

- role
- accessible_name
- optional label/text scope
- expected target count = 1

Rules:

- strict uniqueness required
- visible/enabled/actionable checks
- no coordinate clicking
- no arbitrary CSS/XPath passed by caller
- no `first()/nth()` ambiguity bypass
- no submit/send/buy/pay/confirm operations under GREEN authority

## Consequential-action boundary

The browser may eventually prepare reversible state such as a draft form or cart, but GREEN authority stops before actions that create external commitments, including:

- Submit
- Send
- Purchase / Buy / Pay
- Confirm order
- publish/post
- account/security changes

Those require an explicit owner checkpoint and a separately typed consequential action.

## Proof bar

Before any new browser primitive is promoted:

1. isolated local test site with deterministic fixtures
2. positive tests for unique role/name targeting
3. negative ambiguity test (2 matching targets => hard fail)
4. scheme/domain rejection tests
5. credential/query redaction tests
6. no arbitrary selector/code path static review
7. timeout/retry boundedness
8. browser crash/restart recovery
9. screenshot/accessibility evidence hashes
10. fresh Benchmark PASS 30/30 critical=0
11. explicit primitive-authority review

## Design principle

Browser capability should track how a user perceives the page rather than DOM implementation details. Prefer role/accessibility-name/label/text semantics with strict uniqueness and auto-waiting. DOM/CSS/XPath internals may exist inside a fixed implementation, but must never become caller-supplied arbitrary selector authority.
