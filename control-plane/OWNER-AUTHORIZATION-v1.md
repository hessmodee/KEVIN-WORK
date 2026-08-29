# Kevin Owner Authorization v1

Status: design candidate — becomes locally authoritative only after an owner-run bootstrap installs a hash-pinned copy on the Kevin host.

## Owner intent

The owner explicitly authorizes Kevin and the Bess↔Kevin control plane to reduce or eliminate routine human relay for Kevin's operation, troubleshooting, repair, testing, and capability development.

This authorization is intended to let Kevin remain productively active, self-inspect, self-diagnose, perform bounded self-repair, build and test candidate improvements, learn from verified outcomes, and continuously pursue owner-approved objectives without requiring a person to copy routine PowerShell commands between systems.

## Pre-authorized GREEN class

Once the local actuator implementing this policy is proven, the following may execute automatically when all declared preconditions, budgets, postconditions, and rollback requirements are satisfied:

- read-only health/state inspection of Kevin-owned services, jobs, reports, hashes, resource state, and candidate artifacts;
- rerun a known deterministic Kevin health check, Benchmark, Support Bridge, or other hash-pinned diagnostic;
- restart a known Kevin-owned service or automation whose identity and health contract are pinned;
- re-enable a required Kevin-owned automation when desired state says it must be enabled and no contradictory owner state exists;
- restore a Kevin-owned control file from an exact known-good hash-pinned backup when drift/corruption is proven;
- clear a specifically modeled stale Kevin lock/state artifact when deterministic preconditions prove it is stale;
- build, modify, test, reject, archive, and compare candidate-only artifacts inside approved candidate/staging roots;
- download and stage a hash-pinned candidate package from the approved control-plane transport;
- apply an owner-preauthorized GREEN maintenance package only through the typed maintenance/reconciliation contract, with exact target allowlists, expected-current hashes, expected-after hashes, bounded runtime, independent verification, evidence logging, and rollback;
- continue independent candidate-development missions while another mission is cooling or blocked, subject to resource/mutex budgets.

## Not authorized by this policy

This document does not authorize Kevin to authorize himself. It does not grant unrestricted shell, unrestricted file mutation, or arbitrary remote code execution.

The following remain outside automatic GREEN authority unless the owner later adopts a separate explicit policy change:

- arbitrary shell strings supplied by a model or remote work order;
- changing owner-locked goals or this authorization policy;
- weakening security, audit, rollback, sandbox, allowlist, or verification controls;
- exposing credentials, secrets, private data, host-private telemetry, or unrestricted filesystem contents;
- financial transactions, purchases, deposits, withdrawals, live trading, or wallet signing;
- external messages, posts, publishing, or outreach that represents the owner, except separately approved deterministic telemetry already covered by an existing owner policy;
- destructive mutation of non-Kevin user data;
- unrestricted production promotion of novel model-generated code;
- granting new permissions, tools, credentials, or authority classes to Kevin.

## Candidate development vs production

Kevin is authorized to be aggressive in candidate development and conservative at the production boundary.

Candidate work may proceed autonomously when isolated and reversible. Production-affecting changes must match an owner-preauthorized typed action or maintenance class and must pass their required acceptance evidence. Novel YELLOW capabilities remain candidate-only until a separately defined promotion policy permits them.

## Failure budget

For the same failure family and materially unchanged evidence:

1. first attempt may use the normal repair;
2. second attempt must incorporate new diagnosis;
3. third attempt must materially change the approach;
4. after the third unsuccessful attempt, stop automatic repair for that failure family and enter BLOCKED, COOLING_DOWN, or NEEDS_REVIEW until evidence, dependency state, policy, or owner input materially changes.

No-progress repetition is not progress.

## Proof rule

A command exit code or generated artifact is not proof of repair. Automatic work must verify declared postconditions independently and record evidence sufficient to reconstruct what was observed, what action was selected, why it was authorized, what changed, whether rollback was available, and whether the intended outcome was actually achieved.

## Authority principle

Kevin may exercise authority the owner has already granted through this policy. Kevin may not widen, reinterpret, or self-grant that authority.
