# Kevin Self-Reliance Bootstrap v1.1 Runtime Fix

Date: 2026-08-30 MDT

## Incident

Owner-local bootstrap v1 failed immediately after confirming the live Maintenance v1.2 root. The visible exception was:

`return$s : The term 'return$s' is not recognized...`

The v1 catch/sanitization helper itself contained the token-adjacency bug `return$s`, so the error-reporting path masked the original first-stage exception. The old CI proved parsing and top-level `-SelfTest`, but did not execute that helper or the real component-fetch path. This was a test-design gap.

The failed run did not cross the mutation boundary. Fresh support telemetry after the incident still reported Maintenance v1.2 hash `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`, healthy governance/crons, and Benchmark PASS 30/30 critical=0.

## Repair

New package:

`inbox/maintenance/packages/bootstrap-self-reliance-v1.1.ps1`

Canonical SHA256:

`DAA0046E9E9AC38AB03608EBF4D0A625D7FC783401259FE8D0D401F53161256C`

Immutable proof commit containing the package and its runtime gate:

`e619759dc896b5607720047c0fa72fd230bc2183`

Changes:

- replaced risky return-variable token adjacency with normal PowerShell syntax (`return $s`, `return $b`);
- made helper functions readable/non-minified to reduce lexical hazards;
- added a runtime sanitizer probe to `-SelfTest`;
- added `-Preflight`, which performs the real GitHub API fetch of all three pinned components, exact SHA256 verification, PowerShell parsing, and each component's fixed self-test;
- added construction and validation of the Limited scheduled-task contract without registering it during CI;
- added a regression gate rejecting `return$` token adjacency and forbidden broad execution primitives.

## CI proof

Workflow `Self-Reliance Bootstrap v1.1 Proof`, run `33345329694`, Windows job `99348238452` completed SUCCESS.

It proved:

- canonical bootstrap SHA256 `DAA0046E9E9AC38AB03608EBF4D0A625D7FC783401259FE8D0D401F53161256C`;
- parser/token regression gate PASS;
- runtime self-test PASS;
- real GitHub API fetch + exact component identities:
  - Maintenance v1.3 `97F3FAE54C72F97D3634A6C070FD2E2C7E31B516FEB318CD3D1AECC4A17910C7`;
  - Work Order Intake v1.2.2 `55942149C892AD988E1AEE5A6FF7983D71D891ECA5B71FA20CC3FB9E7D03E903`;
  - Self-Reliance Watchdog v1.1 `4A6ACA6EC40E027B29CCC4C34C50EDAE9EAE90E0C8FEB41B92ACEE44CCB53D93`;
- all three component fixed self-tests PASS;
- scheduled-task contract PASS with Limited privilege.

## Production state

Repository source and deep preflight are PROVEN. Omen production remains Maintenance v1.2 until the corrected v1.1 bootstrap is executed locally and writes `reports/self-reliance/bootstrap-self-reliance-v1.1-proven.json` after watchdog evidence and Benchmark 30/30.

Do not call self-reliance production-PROVEN before that receipt and fresh live telemetry are verified.
