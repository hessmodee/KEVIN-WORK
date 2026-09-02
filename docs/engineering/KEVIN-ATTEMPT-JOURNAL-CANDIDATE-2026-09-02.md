# Attempt journal — isolated durability candidate

Consumer: next governed Supervisor history-preservation integration. This extends
the existing history-recovery candidate lane, not a second staging lane. No Omen
code, manifest, budget, work-item closure, isolation hold or trust anchor changes.
Work-selection responsibility remains T2.

## Contract and implementation

The candidate library `control-plane/autonomy/candidates/attempt_journal.py`
reserves attempts in an existing SQLite journal before returning, preserving
append-only reservation and terminal events. Its API has no bootstrap, migration,
effect executor, shell transport, network, scheduler, production path or CLI.
It is not wired into Supervisor and cannot authorize a tool call by itself.

Budgets aggregate all retained fingerprints per item and mapped canonical family;
changing fingerprint, alternating work or reopening a process never clears them.
Three reservations exhaust the budget conservatively, including attempts with
unknown outcome. The library intentionally has no automatic reopening API.
Missing, empty, corrupt, incomplete, wrong-anchor or wrong-schema state fails
closed. Unknown item/family mappings fail closed. A pending reservation blocks
another reservation globally. Completed items cannot reopen. Duplicate reservation
and terminal records replay without a new reservation; conflicting identities fail.
Only bounded identifiers, timestamps and digests are stored, not private bodies.

SQLite `BEGIN IMMEDIATE` serializes reservation decisions, with rollback-journal
mode and `synchronous=EXTRA` checked before use. Updates/deletions are rejected by
schema guards. These are application integrity controls, not authentication or
protection from an actor able to replace the database. The future typed adapter
must authenticate migration provenance and bind protected paths/current authority.
The expected migration digest is supplied by that adapter, never trusted merely
because the database repeats it. The current recovered proposal is incomplete and
cannot seed this journal; all executable seeds in this evaluation are synthetic
test-only histories. Summed opening counts require validated disjoint provenance.

Implementation choices were checked September 2 against official
[SQLite transactions](https://www.sqlite.org/lang_transaction.html),
[SQLite durability pragmas](https://www.sqlite.org/pragma.html#pragma_synchronous)
and [Python sqlite3](https://docs.python.org/3/library/sqlite3.html).
Those sources establish transaction semantics, not Omen-specific qualification.

## Evaluation and limits

The 28 candidate tests cover A->B->A, prose-equivalent fingerprint changes, family
aliases, alternating items, opening budgets, missing/corrupt/incomplete state,
clock regression, cooldown, replay, completed work, schema tampering, metadata-only
inputs, and competing real child processes. Three real process-death boundaries
cover uncommitted reservation rollback, committed reservation preservation, and
effect committed before terminal evidence. The latter uses a fixed temporary
SQLite effect fixture and an independent query to reconcile its one committed
row. No actual Kevin tool or owner task is invoked. Unknown effects remain pending
and cannot silently replay. This is not universal exactly-once external execution,
power-loss durability, authenticated verification or an installed runtime repair.

Local Python 3.12 evaluation passed 28/28 (59/59 including selector/recovery).
[CI33619080134](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33619080134)
passed all28 journal tests plus18 recovery tests and exact public-receipt replay
on Linux and Windows at [b52d825649af9fbe8d3d7273d8ebdbdbbbe658be](https://github.com/hessmodee/KEVIN-WORK/tree/b52d825649af9fbe8d3d7273d8ebdbdbbbe658be).
Independently inspected jobs100211668149 and100211668353 report all492 tracked
files byte-identical before/after evaluation at10:22 UTC September2. Both used
CPython3.13.15; SQLite was3.45.1 on Linux and3.50.4 on Windows. No installed Omen
interpreter identity is inferred. Library SHA256 is
`461E2C6C524FFC4CDF460367FAF82D441914392F840159E9E9E0D89B99D929A2`;
test SHA256 is `7806FE222AC707A75032A4C13302ED857CB77A5C44F2170DD2D435D4DFF9F9FF`.
This is CI-PROVEN candidate storage behavior, not an integrated runtime repair.
The strict14-case v1.8.8 gate is unchanged and still rejects installed source.

Evaluation history is preserved: first run33618960623 at850d471b89e93d4f5ddb3e92ced3892d5bd6f2f0
passed Linux but failed Windows with WinError32 on temporary database cleanup.
The test fixtures used SQLite's transaction context without closing connections.
The corrected fixture explicitly closes in a finally block, as required by the
Python connection contract; it does not ignore cleanup errors or remove tests.
Production candidate connection handling already closed its handles and was
unchanged by that correction. The corrected second run passed on both platforms.

Fresh source checkpoint 9f70f7ff8b0db21b6cee21fcf1850e775fa4ef1a and a later
Support04:19/Engineering04:20 review confirm unchanged runtime hashes, all listed
scheduler errors0, Benchmark30/30 critical0 at04:17, and UI heartbeat2.1s.
The manifest remains main-canary-reaffirm-16k-20260902-2300 with a matching
ALREADY_APPLIED_PROVEN receipt. Inventory closures and scoped isolation hold are
unchanged. No new production request or main-agent turn was submitted.

## Next acceptance boundary

Obtain complete, authenticated migration evidence and canonical family provenance;
bind this storage contract to the existing selector/typed verifier and fixed
Supervisor path; prove existing controller behavior and no new authority. Validate
actual installed Python/SQLite, filesystem durability, journal size/operation
bounds, authenticated verifier receipts, and old/new source hashes.
Require exact typed migration/install/rollback, privacy, original runtime negative
cases, fresh Benchmark30/30 critical0 and correlated Omen postconditions. Never
install the library merely because these synthetic storage fixtures pass.
