# Fixed-main self-repair candidate safety — 2026-09-02

## Outcome and exact evidence

The existing [PR37](https://github.com/hessmodee/KEVIN-WORK/pull/37) candidate was hardened in place, without merging or installing it. Baseline f092c891a68b3c943c03aa4b1276ace823fa35a8 passed its original10 tests, but independent local Python3.12 testing reproduced9 safety failures. Commit 481d1ac3f4ea4df0265b1bea2de40e985d9014cb passes23 tests on Linux and Windows, Python3.12 and3.13; all four [CI jobs](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33678048287) were checked for actual test output and the unchanged authority-boundary gate.

Contract SHA256: 60792F346FA15ECAF89A7CEB25A0D6E9B45A88EE567DD3C0CB846D4449D016AE. Test module SHA256:53EF71C23BF534B882D5800CD2AE9DA74D235AA99181439A46842D251461DAF4.

## Defects, detector and teach-back

Family: fixed_main_candidate_semantic_identity_loss. The downstream consumer is PR37's exact-diff verifier for the fixed_main_context_overflow_compaction_budget repair, not a new runtime worker.

- Fractional2048.5 and string2048 were coerced to the expected reserve; explicit null was interpreted as missing. Exact integer checks and independent presence flags now reject these states.
- Boolean true versus integer1 disappeared under Python equality. Typed leaf values now distinguish them.
- Empty arrays/objects collided with user-supplied sentinel strings. Typed container markers remove this ambiguity.
- Dotted and index-like object keys collided with nested/list paths. Typed path segments plus escaped display paths now preserve identity, including literal names resembling allowed repair paths.

The original10 tests remain. Thirteen new tests include the9 reproduced failures plus exact context/other-token types, non-finite numbers and forged allowed-path names. CI now discovers both modules. These are synthetic safety fixtures; no private configuration or owner message bodies were used.

Preconditions for future use: installed schema and exact current configuration must be qualified; candidate fixtures alone do not establish actual OpenClaw field locations. The candidate has no filesystem, subprocess, network, config write, baseline mutation or tool grant. Rollback for this source-only change is the prior PR commit; no live rollback was needed. An eventual live wrapper still requires an exact backup, hash-CAS, dry-run, full validation, semantic diff, fail-closed rollback, real fixed:main turn/compaction proof, negative tool-policy tests and fresh Benchmark30/30.

## Current runtime and owner boundary

Owner-reported fixed:main compaction repair preserves model/context16384, reserveTokensFloor2048, reserveTokens2048 and keepRecentTokens4000 at config SHA23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5; fresh text reply and manual compaction passed. The 09:00 rejected canary predates this repair and is not a post-repair failure. Benchmark14:02 MDT remains29/30 critical1, solely R04; Support14:09 corroborates NO_MANIFEST. Engineering14:13 reports stale UI heartbeat7579.5s and four proven composites. The13:45 capability audit completed but records policy-path presence, not effective inventory; owner reports an empty fresh /context inventory. No tool grant, baseline change, runtime repair or T-level promotion occurred in this review.

Snapshot: [0a252bfcfcdf1eb390e927609b1f74c2b49064f5](https://github.com/hessmodee/KEVIN-WORK/tree/0a252bfcfcdf1eb390e927609b1f74c2b49064f5). Owner terminal observations are distinct from independently retrieved receipts. The09:00 transcript's null total calls remain unknown for that historical turn; do not reinterpret them as zero or as a current post-repair failure.

The13:39 runtime-capability manifest is no longer in flight:13:45 audit/terminal control-plane evidence exists and it was removed at commit b65909b61b38b26db44c4b6157921fc00a2cfd47. Do not enqueue it again merely to refresh a label.

## R04 path audit and tool visibility

The inspected published Maintenancev1.3.44 and Intakev1.2.6 do not expose a general production-config baseline-reconciliation operation. Existing fixed baseline mutations belong to historical Supervisor/Forge migrations; their preconditions do not authorize updating R04 after this repair. Installed Maintenance3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E is not proven equivalent to the published source. This is a qualified-path/provenance gap, not evidence that a hidden local operation exists or permission to bless a baseline. Do not misuse an old migration or replace the unknown runner. The next production prerequisite is an exact-current baseline/runner contract with the owner-approved config identity, bounded semantic scope, rollback and independent regression verification.

Current official [tool guidance](https://docs.openclaw.ai/tools) says effective exposure is filtered before model invocation by profile, allow/deny, provider, agent/channel/sandbox and plugin state; authored policy presence is not effective inventory. [Tool configuration reference](https://docs.openclaw.ai/gateway/config-tools) is supporting current documentation, not proof that each diagnostic API exists in installed2026.7.1-2. The13:45 audit establishes root-tools presence but no main/default tools path and no effective policy values. Thus no specific deny/profile/model root cause is proven and no broad tool grant is justified.

## Desired state, WIP and transfer

Repository desired-state pins remain historical and must not be silently replaced with observed hashes. The compact checkpoint records observed identities separately; local desired-state drift2 remains unresolved. The observed live Supervisor/Benchmark/Maintenance hashes differ from repository desired pins, while exact installed Maintenance provenance remains open. Five runtime policy files were not replaced.

One existing staging item(PR37) was reviewed and returned to CI-proven candidate state; no production crossing or second scheduler was created. Other PRs/candidates remain queued, not promoted. All completed inventory statuses and retry/family history were preserved. The prior write-proof/global-stop instruction is superseded by the continuous-autonomy directive, but unmet effect-specific prerequisites are not waived.

P0 qualify an exact-current bounded R04 baseline contract and fresh30/30 without reverting compaction; obtain installed-version-qualified effective tool policy/inventory before any narrow grant. Preserve unknown Maintenance source and runtime policy bytes. PR37 candidate hardening is CI-proven, not installable: qualify actual installed config schema, fixed wrapper/hash-CAS/backup/rollback and semantic real-turn/compaction/negative proof. Continue independent authorized work within WIP; do not reset history or repeat satisfied work.

Work-selection staysT2. This source repair and continuity reconciliation were outside-engineer interventions; no recurring Bess responsibility was retired. Preserve this negative-test lesson for Kevin-owned future qualification.
