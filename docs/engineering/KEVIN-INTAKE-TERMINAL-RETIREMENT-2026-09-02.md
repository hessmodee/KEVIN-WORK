# Expired terminal Maintenance request retirement

Date: September 2, 2026. Scope: retire one consumed queue entry, not a runtime
binary repair, canary retry, scheduler change or autonomy-transfer promotion.

## Correlated cause

At source checkpoint `ac432d1e576b1fbc3a5147b074140188cf37b7f6`, Support05:07
reports Maintenance ERROR `manifest expired`, while Benchmark passes30/30 critical0
and other core schedulers remain healthy. Intake has one error; Support05:10
subsequently reports two errors from the05:09 intake. The request
`main-canary-reaffirm-16k-20260902-2300` expired at11:01:17.9839979Z (05:01 MDT).
Its exact blob is `34e0c37f1be661c14ac1f7636ab6fa853f8c2233`.

This is the same already-consumed request observed ALREADY_APPLIED_PROVEN at04:19
in Support at `dde67b7be71a7ca732fd095de0ae5d71e8ac7d3e`. The exact-response canary
remains proven at23:02 September1, with zero calls in its correlated transcript.
No new Gateway outage, canary failure or useful tool-use proof is inferred.

Repository Maintenance v1.3.43 calls Assert-Common (including expiry) before
terminal-attempt reuse. It also explicitly maps a missing remote manifest to
NO_MANIFEST and exit0. Non-404 fetch failures still throw. Observed local runner
hash remains FF9C5FDF217B0ED5F38A8566BD54D8A654CB8DFEF0093654DDBC23DC9A1BF956;
its local source provenance is not inferred from the repository version label.
The independent Omen receipt below, not this source comparison alone, decides
whether the existing installed empty-queue path recovered.

## Bounded action and preserved evidence

The exact request was archived at
`inbox/maintenance/archive/main-canary-reaffirm-16k-20260902-2300.json`
in commit `4d2d87eba3af6f280fb61b6e8d6ee401590a0b53`. Archive bytes and Git blob
were read back and matched before deletion. Commit
`f46fce1fedeeb9a0d0fa6438ae664b04abb4b7c6` retired only the active manifest at
11:10:32Z, using expected-blob comparison. A concurrently changed request would
have failed that comparison instead of being overwritten. Recent PRs and commits
showed no fresh foreground replacement crossing. The scoped isolation hold remains.

No expiry extension, replacement request, canary rerun, model invocation, scheduler
reset, retry-budget reset, runtime binary edit or trust-anchor change was made.
The archive and Git history preserve exact reversal bytes; blindly restoring an
expired request would reproduce the fault and is not authorized as a new retry.
Any future request still requires fresh eligibility and its original acceptance.

## Omen verification

Queue recovery is OMEN-OBSERVED. In snapshot
`61ec1e48a9072b466a6948d949a3e58a561c1c9b`, Support05:16:58 carries a new
Maintenance receipt at05:15:07: NO_MANIFEST, no waiting proposal, and Intake
consecutive_errors=0. Independent Engineering05:18:45 confirms scheduler errors0,
UI heartbeat1.6s and Benchmark PASS30/30 critical0 at05:17:17, after retirement.
The installed runner and Supervisor hashes remain unchanged. This closes the
expired-terminal-queue fault, not the unresolved Supervisor history defect.
No new canary receipt or tool-use outcome was created. The main-agent canary's
prior proof remains intact; source qualification and T-levels remain unchanged.

## Migration-provenance research while awaiting the receipt

Consumer: the existing governed Supervisor history-preservation integration.
All eight published work-inventory revisions were inspected, from initial commit
`0e4c56aef6795b16c6900593303881e6e9abeec` through current closure commit
`3efe15f6c7f4e8f3e989c66e4a300a0f09eac71a`. Neither HQ chat nor staging trajectory
has an explicit failure_family in any revision where present. Program labels and
failure_attempts=0 do not establish a canonical family or erase runtime attempts.

The earliest retrieved continuation receipt, commit
`e107119c4afb836119c380ce405b894c66df4493`, already records an HQ attempt at21:32
September1; it is not an authenticated empty-history bootstrap. The next receipt,
`e98e636d209db4f6f83a1832b54ccc28183a7386`, includes staging's first observed turn.
These earlier receipts improve provenance but do not certify that no unpublished
or pre-publication attempts exist. No complete migration seed or family mapping
was manufactured. The existing journal candidate stays CI-PROVEN only, uninstalled.

Next: obtain authenticated complete history/family provenance, then integrate the
bounded fixed Supervisor and independent verifier. Preserve live closures, budgets
and isolation prerequisites. Work-selection responsibility remains T2.
