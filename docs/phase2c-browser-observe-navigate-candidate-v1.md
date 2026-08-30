# Phase 2C Browser Observe + Navigate Candidate v1

Status: CANDIDATE ONLY — NOT PROVEN, NOT PROMOTED
Authority: no new production authority is granted by this document.

## Goal
Prepare the next primitive capability campaign around bounded browser observation and typed semantic navigation without arbitrary selectors, arbitrary script execution, credential access, external sends, purchasing, payments, or automatic authority expansion.

## Evidence basis
Current Playwright guidance recommends user-facing locators such as role, label, text, placeholder, alt text, and title; role locators are preferred for interactive elements. Playwright locators provide auto-waiting/retry behavior and strictness: single-target actions fail when multiple elements match. CSS/XPath chains are explicitly discouraged as brittle. Chromium DevTools Protocol exposes the browser accessibility tree and can query nodes by computed accessible name and role.

Authoritative references:
- https://playwright.dev/docs/locators
- https://playwright.dev/docs/best-practices
- https://chromedevtools.github.io/devtools-protocol/tot/Accessibility/

## Proposed primitive sequence

### 1. browser_observe
Read-only.
Returns a bounded sanitized snapshot containing:
- current URL and origin
- title
- page load/navigation state
- bounded accessibility-tree summary
- visible semantic targets expressed as role + accessible name/label
- optional screenshot evidence produced by an already-approved capture mechanism

Prohibited:
- DOM mutation
- clicks, typing, uploads, downloads
- arbitrary JavaScript evaluation
- arbitrary CSS/XPath from caller
- credential/cookie/token extraction
- raw page source export by default

### 2. browser_navigate
Typed navigation only.
Input contract:
- explicit URL string
- allow only http/https
- normalize URL before action
- block file:, javascript:, data:, chrome:, extension:, localhost/private-network destinations unless separately owner-approved for a specific test campaign
- pre-action record of source URL
- postcondition must verify final URL/origin and navigation result
- bounded timeout and bounded redirects

No arbitrary shell/code execution and no caller-supplied browser launch flags.

### 3. browser_semantic_interact (future candidate after observe+navigate prove out)
Target contract:
- role + accessible name is primary
- label for form fields
- visible text for non-interactive content
- placeholder/alt/title only as secondary fallbacks
- strict single-target requirement for actions
- ambiguous matches fail closed; do not use .first/.last/.nth to bypass ambiguity
- no caller-supplied raw CSS/XPath selectors
- actionability checks must pass before interaction

## Consequential-action boundary
The browser stack may eventually prepare forms, carts, uploads, or drafts using proven bounded primitives, but must stop before consequential commitment. Examples requiring an explicit owner checkpoint include:
- Submit / Send
- Buy / Pay / Place order
- Confirm booking
- Final account/security changes
- Uploading sensitive material externally

## Proof plan
Promotion requires isolated deterministic evidence for each primitive:
1. parser/static safety checks
2. negative tests for forbidden schemes and arbitrary script/selector injection
3. deterministic test pages with unique semantic targets
4. ambiguity test proves fail-closed behavior
5. timeout/retry bounds
6. navigation postcondition verification
7. replay/idempotency behavior where applicable
8. regression Benchmark PASS 30/30 critical=0 after candidate testing
9. rollback proof
10. no automatic production promotion

## Candidate test matrix
- observe simple static page: PASS expected
- observe accessibility role/name extraction: PASS expected
- navigate https URL: PASS expected
- navigate javascript: URL: BLOCK expected
- navigate file: URL: BLOCK expected
- ambiguous two-button role/name target: BLOCK expected
- raw CSS/XPath supplied by caller: BLOCK expected
- arbitrary JS/evaluate request: BLOCK expected
- external send/purchase terminal action: OWNER CHECKPOINT expected

## Governance invariant
This document prepares evidence and implementation constraints only. It does not authorize installation, browser control, new primitive promotion, credential access, external sending, purchases/payments, or safety weakening.
