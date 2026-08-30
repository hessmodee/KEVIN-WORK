# Phase 2C Browser Primitive Research Notes — 2026-08-30

Status: CANDIDATE RESEARCH ONLY — NO AUTHORITY PROMOTION

## Current evidence

Official Playwright guidance treats locators as the core of auto-waiting/retry behavior and recommends resilient, user-facing targeting. Preferred targeting is role + accessible name for interactive controls, label for form controls, and text for non-interactive content. Playwright locators are strict for single-target actions: ambiguous multiple matches throw rather than silently selecting one. CSS/XPath are explicitly discouraged as brittle implementation-detail selectors.

Primary sources:
- https://playwright.dev/docs/locators
- https://playwright.dev/docs/best-practices

Chromium DevTools Protocol exposes the Accessibility domain, including `getRootAXNode`, `getPartialAXTree`, `getFullAXTree`, and `queryAXTree`. `queryAXTree` can filter by computed accessible name and role. CDP notes that enabling Accessibility can affect performance, supporting Kevin's bounded-observation design rather than a continuously materialized full tree.

Primary source:
- https://chromedevtools.github.io/devtools-protocol/tot/Accessibility/

CDP `Page.navigate` returns `frameId`, optional `loaderId`, optional `errorText`, and an `isDownload` signal. `loaderId` is omitted on same-document navigation. These details should become explicit postcondition checks instead of treating a successful API call as proof of navigation.

Primary source:
- https://chromedevtools.github.io/devtools-protocol/tot/Page/

## Candidate contract refinements

### browser_observe
- Default to bounded accessibility queries (`getRootAXNode`, `getPartialAXTree`, `queryAXTree`) rather than `getFullAXTree`.
- Record AX node/depth/byte budgets and explicit truncation.
- Disable the Accessibility domain after a bounded read when persistent AX identities are not required.
- Return only sanitized role/name/state summaries and governed screenshot evidence, not unrestricted DOM/source/storage/cookies.

### browser_navigate
- Accept typed absolute HTTPS URL only, except a separately declared local-test HTTP fixture.
- Reject embedded credentials and `javascript:`, `data:`, `file:`, and custom protocols.
- Revalidate every redirect destination against the same scheme/domain policy.
- Treat non-empty `errorText` as hard failure.
- Treat `isDownload=true` as non-GREEN navigation failure unless a separately approved typed download primitive exists.
- Do not require a new `loaderId` for same-document navigation; verify final URL/title/load state independently.
- Record pre/post normalized URL, frame identity, redirect count, timeout, and evidence hash.

### browser_semantic_interact
- Caller supplies semantic target fields only: role, accessible name, optional label/text scope, expected_count=1.
- Preserve strict uniqueness; never auto-resolve ambiguity with first/last/nth.
- Require visible/enabled/actionable checks and bounded auto-wait.
- No caller-supplied CSS/XPath, arbitrary JavaScript, coordinates, or raw CDP method names.
- Re-observe post-action state independently.
- GREEN interactions must exclude Submit/Send/Buy/Pay/Confirm/Publish/account-security changes.

## Proof additions

In addition to the existing Phase 2C proof bar:
1. same-document navigation test where `loaderId` is absent but post-state is verified;
2. navigation-result download test proving `isDownload=true` is blocked under GREEN;
3. non-empty `errorText` hard-failure test;
4. ambiguous semantic role/name target test proving no first/last/nth bypass;
5. Accessibility-domain budget/performance test proving bounded enable/query/disable behavior;
6. redirect-to-forbidden-scheme/domain test;
7. caller-supplied CSS/XPath/JavaScript/CDP-method rejection static and runtime tests.

No browser primitive is authorized for production by this research note.
