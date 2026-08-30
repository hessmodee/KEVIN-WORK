# Kevin Self-Heal and Remote Bootstrap Architecture v1

Status: **candidate architecture / no production authority change**

## Problem

Kevin currently has a safe one-way remote engineering path: GitHub carries typed requests and evidence, while local OpenClaw jobs perform narrowly declared work. This is intentionally safer than remote shell. The remaining bootstrap gap is that Maintenance Intake v1.1d runs with `-CheckOnly`; a CI-qualified maintenance v1.2 replacement can be staged remotely but v1.1d still requires one explicit local `-ApplyOnce` invocation before v1.2 can take over.

The objective is to eliminate this class of human-as-transport dependency without introducing arbitrary remote code execution.

## Research conclusions

### 1. OpenClaw's scheduler is the right deterministic execution substrate

OpenClaw supports persistent command automations and recommends `--command-argv` for exact argv execution without shell parsing. Command jobs execute directly through the Gateway scheduler rather than through a model-visible generic `exec` call. Automation mutation itself is an `operator.admin` action, so a pre-created fixed job is materially safer than granting a model generic admin or exec authority.

Sources:
- OpenClaw Automations / cron documentation: exact argv command jobs; automation add/edit/run requires `operator.admin`.
- OpenClaw operator scopes: `operator.admin` is administrative control-plane authority.
- OpenClaw security documentation: cron is control-plane sensitive; generic host exec remains a separate mutating surface.

### 2. Generic exec is the wrong solution

OpenClaw documents `exec` as a mutating shell surface. Giving Bess/Kevin general gateway/node exec would solve transport but destroy the architecture's most important boundary. Host exec approvals can constrain it, but a fixed typed reconciler is still safer and easier to audit.

### 3. Self-healing needs an out-of-band layer

OpenClaw community experience repeatedly identifies the watchdog problem: a system cannot reliably repair the process that hosts its own repair logic if that process is down. Community proposals and tools converge on an external OS-level watchdog, bounded restart attempts, circuit breakers, health probes, durable incident logs, and escalation after repeated failure. Windows Task Scheduler is Kevin's appropriate out-of-band substrate.

### 4. Recovery must be reconciliation, not repeated restart

Kubernetes-style controller patterns and the observed Skill Lab crash bug point to the same rule: compare desired state with observed state, make the smallest idempotent correction, verify postconditions, and retry with a bound. A restart is only one possible typed correction, not a universal response.

### 5. Cron itself needs independent sentinels

OpenClaw issue reports document silent cron/session failure modes where a job can look scheduled but fail to produce work. Therefore Kevin must not infer health from job registration alone. Each critical job needs a fresh heartbeat/sentinel/evidence timestamp and a stale threshold.

## Target architecture

### Layer A — Typed Maintenance Reconciler inside OpenClaw

Maintenance v1.2 already implements the core model:
- schema-2 typed manifests;
- owner-preauthorized GREEN only;
- fixed operations only;
- fixed target aliases;
- exact before/after SHA256 checks;
- bounded attempts;
- independent self-test/postcondition;
- fresh Benchmark 30/30 critical=0;
- rollback on mutable failure;
- legacy executable packages never auto-apply.

When v1.2 is installed, its compatibility behavior intentionally permits a schema-2 preauthorized manifest to reconcile even though the existing cron still invokes the runner with `-CheckOnly`. This eliminates future manual ApplyOnce transport for typed GREEN operations.

### Layer B — External Windows watchdog outside OpenClaw

Install a fixed Windows Scheduled Task whose argv points only to `kevin-external-watchdog.ps1`. The watchdog is policy code, not a command broker.

Allowed actions in v0.1:
1. `probe_gateway`
2. `restart_gateway_fixed` after a bounded failed-health threshold
3. `probe_critical_crons`
4. `run_fixed_maintenance_intake` by declaration key
5. `restart_ui_bridge_fixed` by exact scheduled-task name
6. write sanitized local incident evidence

Explicitly forbidden:
- caller-supplied commands;
- caller-supplied executable paths;
- caller-supplied task names;
- arbitrary PowerShell arguments;
- config editing;
- credential reads;
- permission changes;
- production chat/tool widening;
- financial/external-send actions.

Circuit breaker:
- at most 3 repair attempts per failure family in 15 minutes;
- after exhaustion, record `COOLED` and stop changing that family until fresh evidence/state changes.

### Layer C — Durable GitHub intent/evidence channel

GitHub remains the asynchronous control/evidence bus, not a shell transport.

Remote artifacts are declarative:
- owner authorization;
- typed maintenance manifest;
- expected hashes;
- expiry;
- idempotency ID;
- desired postcondition.

Local code independently validates and executes fixed behavior. Local support/engineering feeds publish sanitized outcomes.

### Layer D — Optional authenticated OpenClaw webhook wake path

OpenClaw HTTP hooks can wake an agent or start an isolated turn, but they require local configuration and a dedicated secret and should remain behind loopback/tailnet/trusted ingress. They are useful for *waking planning*, not for bypassing typed maintenance. Do not expose Gateway auth or `/tools/invoke` publicly merely to solve maintenance transport.

## Bootstrap truth

There is no safe remote software-only route to make **v1.1d itself** execute `-ApplyOnce` unless one of the following already exists on the host:
- an admin-capable OpenClaw automation that is remotely invokable;
- a preinstalled out-of-band watcher consuming a typed intent;
- a paired node/remote management channel with an already-approved fixed command;
- a self-hosted CI runner on the Omen.

Current evidence does not show any of those. Creating one requires one initial local administrative mutation. Attempting to manufacture execution through a malformed manifest, parser side effect, credential extraction, or generic remote exec would be a safety regression and is rejected.

## Permanent fix after the one bootstrap

Once Maintenance v1.2 is installed:
1. schema-2 owner-preauthorized GREEN manifests auto-reconcile through the existing five-minute maintenance cron;
2. install the external watchdog as a fixed OS task through a separately proven typed operation;
3. add stale-heartbeat checks for UI Bridge, Engineering Relay, Skill Lab, Supervisor, Benchmark, and Maintenance Intake;
4. add fixed `repair_declared_automation` aliases only after each alias has independent tests;
5. require fresh Benchmark and evidence after each mutable repair;
6. keep all remote artifacts declarative and all executors local/fixed.

## Engineering lesson

**Remote autonomy should expand by adding narrowly typed verbs to a local reconciler, not by widening the remote transport.** The transport carries intent; the local policy owns authority.
