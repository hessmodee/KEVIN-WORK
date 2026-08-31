# Kevin Runtime Convergence Plan — 2026-08-31

Status: P0 EXECUTION PLAN

## Why this exists

Repository doctrine has converged faster than the Omen runtime. Fresh public-safe evidence at 10:18 local still showed:

- Design Forge actively launching `forge-v4` after repeated rejected iterations;
- latest Forge evaluation at iteration 259, REJECT, failure_count 6, security finding 1;
- Supervisor recovery throttling while the same design family continues to recur;
- Engineering Relay repeatedly seeing an expired request;
- Work Order Intake repeatedly seeing an already-processed idempotency key;
- autonomy `NEEDS_REVIEW`, drift_count 3, with advisory work-conservation not yet integrated.

Therefore the immediate problem is not lack of doctrine. It is **policy/runtime convergence**.

## P0 objective

Prove that the Omen runtime is consuming and enforcing the new autonomy architecture rather than merely having newer source in GitHub.

## Required convergence sequence

1. **Observe exact local identities** for the active Supervisor, Design Forge, workspace bootstrap files, Work Order Intake, Engineering Relay, Maintenance, Skill Lab and OpenClaw runtime/version.
2. **Map each identity to source/proof lineage.** Do not assume repository main equals installed Omen bytes.
3. **Install only through existing typed/reversible paths.** If the current Maintenance runner cannot safely replace a target, create the smallest new fixed alias/operation through candidate -> CI -> owner-authorized typed self-upgrade -> Omen proof. Never use arbitrary path/shell authority as a shortcut.
4. **Converge workspace bootstrap doctrine** (`AGENTS.md`, `SOUL.md`, `MEMORY.md`, `TOOLS.md`, `HEARTBEAT.md`) to the reviewed repository versions and verify exact hashes on Omen.
5. **Converge work selection:** replace/suppress demandless Forge rotation and require objective + acceptance criteria + downstream consumer + WIP slot + non-cooled family before design execution.
6. **Retire stale queue artifacts:** an expired Engineering Relay request or already-processed work-order slot must transition to a terminal/retired state and stop generating repeated activity/commits.
7. **Verify native OpenClaw primitives locally** before building replacements: Standing Orders/bootstrap injection, Automations, Background Tasks/audit, Task Flow availability, Heartbeat semantics, memory/compaction behavior, Skill Workshop availability.
8. **Run a convergence proof window** long enough to show behavior rather than one instant snapshot.

## Acceptance criteria

Runtime convergence is not proven until all applicable checks pass:

- exact Omen hashes for the five bootstrap files match the intended reviewed versions;
- the next several Supervisor/Forge cycles do **not** generate a demandless round-robin Forge mission;
- a cooled failure family is not relaunched without materially new evidence/hypothesis;
- expired Engineering Relay work does not keep producing fresh repeated response churn;
- duplicate Work Order Intake acknowledgement does not represent an active slot and the system can move to another useful lane;
- with zero active workers and explicit useful backlog, Kevin either selects authorized useful work or records a specific blocker/owner checkpoint — never unexplained `NO_DISPATCH_NEEDED`;
- Kevin completes at least one useful GREEN task chosen from an unblocked owner objective without Bess creating the immediate task request;
- semantic domain proof is recorded for that work;
- global Benchmark remains 30/30 critical=0 when applicable;
- no authority expansion, arbitrary shell, secret exposure or silent trust-anchor adoption occurs.

## Native OpenClaw verification matrix

Verify installed-version support before adoption:

- Standing Orders / workspace bootstrap injection: REQUIRED
- Automations: REQUIRED
- Heartbeat as ambient monitor only: REQUIRED
- Background Tasks + `tasks audit`: HIGH VALUE
- Task Flow: HIGH VALUE for durable owner goals
- Lobster/constrained workflow support: evaluate if installed and useful
- Skill Workshop: start proposal-only if available
- memory/compaction flush: REQUIRED for continuity

Do not claim a feature exists locally because current online documentation describes it. Installed-version proof is required.

## Anti-spin metrics

Track over a rolling proof window:

- demandless Forge launches: target 0
- repeated expired-request responses: target 0 after retirement
- repeated duplicate-slot activity: target 0 after terminal acknowledgement
- unexplained idle-with-backlog incidents: target 0
- useful owner tasks selected without Bess dispatch: target increasing
- Bess interventions per completed owner task: target decreasing
- active WIP: <= 1 production crossing + 1 staging/eval + 1 named-consumer research/design
- failed-family retries beyond budget: target 0

## First responsibility transfer sought

**Work Selection / Tick:** T2 -> T3.

Evidence required: Kevin notices idle/cooling/blocked state, chooses a different authorized objective from the standing backlog, executes through existing typed capability, verifies semantic success, records the result, and continues without Bess injecting a replacement work order.

Once repeated across distinct blocked states, promote toward T4.
