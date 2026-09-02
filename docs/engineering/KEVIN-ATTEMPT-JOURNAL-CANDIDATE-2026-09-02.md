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

Local Python 3.12 evaluation passed 28/28. Cross-platform CI is pending at this
draft. The prior recovery tests and exact public-receipt replay remain mandatory;
the strict 14-case v1.8.8 gate is unchanged and still rejects installed source.

## Next acceptance boundary

Obtain complete, authenticated migration evidence and canonical family provenance;
bind this storage contract to the existing selector/typed verifier and fixed
Supervisor path; prove existing controller behavior and no new authority. Validate
actual installed Python/SQLite, filesystem durability and old/new source hashes.
Require exact typed migration/install/rollback, privacy, original runtime negative
cases, fresh Benchmark30/30 critical0 and correlated Omen postconditions. Never
install the library merely because these synthetic storage fixtures pass.
