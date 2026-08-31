# Kevin Self-Reliance v1 — Proof and Bootstrap Boundary

Date: 2026-08-30 MDT

## Status

**SOURCE PUBLISHED / CI PROVEN. OMEN INSTALL PENDING ONE FINAL LOCAL BOOTSTRAP.**

The self-reliance source set was fast-forward published to `main` at commit `6aa433961b304a38e27146b77a929166618fa2fa` without force-pushing over Kevin telemetry history.

The live Omen is still expected to report Maintenance v1.2 until the bootstrap proof receipt exists. Never infer production install from repository state alone.

## Root cause closed

The failed v1.3 bootstrap hash checks were caused by non-canonical line-ending bytes: a Windows checkout could hash CRLF bytes while the GitHub Contents API returns canonical repository LF bytes. The repair adds `.gitattributes` with `eol=lf` for hash-pinned text/control-plane artifacts and makes CI prove both LF Windows checkout and the exact bytes returned by the immutable GitHub Contents API.

## CI proof

Workflow run `33344716742` completed with both policy and Windows PowerShell jobs successful. The Windows job proved:

1. LF checkout under Windows.
2. Windows PowerShell 5.1 parser compatibility.
3. Fixed self-tests for Maintenance v1.3, Work Order Intake v1.2.2, Self-Reliance Watchdog v1.1, and the transactional bootstrap.
4. Immutable GitHub Contents API bytes exactly equal the pinned SHA256 identities.
5. No arbitrary-shell/caller-argv authority in the fixed self-reliance path.

Canonical SHA256 identities:

- Maintenance v1.3: `97F3FAE54C72F97D3634A6C070FD2E2C7E31B516FEB318CD3D1AECC4A17910C7`
- Work Order Intake v1.2.2: `55942149C892AD988E1AEE5A6FF7983D71D891ECA5B71FA20CC3FB9E7D03E903`
- Self-Reliance Watchdog v1.1: `4A6ACA6EC40E027B29CCC4C34C50EDAE9EAE90E0C8FEB41B92ACEE44CCB53D93`
- Transactional bootstrap package: `B009A3B9BF9B26C8EBF749A265411DC9E718610B8BDEF5FDB9A0F79D20C58F74`
- Required current live Maintenance v1.2 root: `3B9D5B235E593C1CFF8CC9B7DED9E82FB958C2F7CD1F29FC813ECFA87E5C5483`

The bootstrap fetches component bytes from immutable commit `a556563a56e2756b8a9f87d3472028101465a580`, not a moving branch.

## Recovery architecture after bootstrap

### Layer 0 — external Windows watchdog

`Kevin Self-Reliance Watchdog v1` runs as the current user at **Limited** run level. Its execution surface is fixed:

- `openclaw gateway status --require-rpc --json`
- only if unhealthy: `openclaw gateway restart --wait 30s --json`
- fixed local `kevin-maintenance-runner.ps1 -CheckOnly`

Gateway retries are bounded to 3 with a 15-minute cooldown. Maintenance wake runs on a bounded cadence. The watchdog accepts no caller command, argv, script, URL, local path, or remote payload.

### Layer 1 — Maintenance v1.3

Typed schema-3 maintenance can replace only fixed aliases `maintenance_runner`, `work_order_intake`, and `skill_lab_runner`, plus the separately fixed UI Bridge restart operation. Replacement requires exact before/source/after SHA256, parser, fixed self-test, backup/rollback, bounded attempt state, governance checks, and fresh Benchmark 30/30 critical=0.

This closes the old bootstrap paradox: once v1.3 is live, the maintenance system can upgrade its own pinned runner through the same typed GREEN contract.

### Layer 2 — Work Order Intake v1.2.2

Adds exactly one maintenance wake verb: `run_typed_maintenance`, fixed to target `kevin-maintenance-v1`, which locally maps only to the known maintenance runner with `-CheckOnly`. The request cannot carry a command or argv.

### Layer 3 — future capability transport

After this bootstrap is Omen-PROVEN, future GREEN fixed aliases (for example a read-only OS Observer) can be added by a CI-qualified Maintenance release and then installed through the self-maintaining typed path, rather than by asking the owner to relay PowerShell commands.

## Transactional bootstrap contract

`inbox/maintenance/packages/bootstrap-self-reliance-v1.ps1`:

- requires the exact current Maintenance v1.2 root or an already-installed exact v1.3 root;
- fetches only immutable-ref, allowlisted component paths;
- verifies exact SHA256 before mutation;
- parses and self-tests candidates under Windows PowerShell;
- backs up existing component files;
- waits for affected runners to quiesce;
- atomically installs Maintenance v1.3, Intake v1.2.2, and Watchdog v1.1;
- registers the watchdog Scheduled Task with `MultipleInstances IgnoreNew`, `StartWhenAvailable`, restart-on-failure, and `RunLevel Limited`;
- starts the watchdog and requires fresh HEALTHY/RECOVERED evidence;
- requires a fresh Benchmark PASS 30/30 critical=0;
- writes `reports/self-reliance/bootstrap-self-reliance-v1-proven.json` only after all postconditions pass;
- restores files/task state if a post-install postcondition fails.

## Why one final local bootstrap remains

The currently live Maintenance v1.2 intentionally refuses arbitrary/legacy PowerShell packages and does not have authority to replace itself. The existing Maintenance Intake simply invokes that same v1.2 runner with `-CheckOnly`; therefore it cannot grant v1.2 new self-replacement authority. Crossing that boundary remotely without one local bootstrap would require adding a broad remote-execution mechanism, which is explicitly outside Kevin's GREEN governance.

Therefore one final owner-local execution of the exact hash-pinned transactional bootstrap is the deliberate trust transition. After its proof receipt is verified, routine GREEN repair and typed maintenance should no longer require the owner to act as a PowerShell courier.
