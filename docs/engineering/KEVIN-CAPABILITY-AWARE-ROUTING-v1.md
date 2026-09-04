# Kevin Capability-Aware Routing v1

Date: 2026-09-04  
Status: GREEN/YELLOW source contract (CI-proven planner; live Supervisor v1.8.9 install is a separate YELLOW crossing)  
Authority effect: NONE

## Problem proven on HESS-PC

Live Supervisor continuation reported `IDLE_NO_ELIGIBLE_DEMAND` with a non-zero `blocked_count` while owner-value Skill Lab work existed.

Root causes:

1. **Program registry gap:** OPEN owner composites used program `owner-value-skills`, which was absent from `standing-programs-v1.json`, so selector v1.1 marked them `UNKNOWN_PROGRAM`.
2. **Hardcoded dispatch:** Supervisor v1.8.8 always invoked `openclaw agent --agent main` after selection, regardless of worker/capability ownership.
3. **Work Supply not in the live admission path:** standing catalog items with `worker: skill-lab` / Desktop requirements were not merged and routed before Supervisor selection.
4. **Truth boundary:** Supervisor `NO_ELIGIBLE_MISSION` is Supervisor-lane truth only; it must not erase Skill Lab ready/blocked owner demand (see P0.5).

## Required routing model

| Demand class | Owner worker | Supervisor action |
|---|---|---|
| GREEN composite skill prove/replay | `skill-lab` | Defer to Skill Lab / typed Relay staging — **do not call fixed:main** |
| Typed Engineering Relay operation | `engineering-relay` | Defer to Relay — **no arbitrary shell** |
| Desktop runtime proof | `fixed:main` **only if** Desktop tools are effective | If `tools:false`, record `DESKTOP_REQUIRED_BUT_FIXED_MAIN_TOOLLESS` — **never dispatch** |
| Guardian/audit | `guardian` | Defer to guardian lane |
| Compatible main-owned GREEN work | `fixed:main` | Existing continuation turn |

## Components

- `control-plane/autonomy/kevin-capability-router-v1.py`
- `control-plane/autonomy/kevin-work-admission-v1.py` (Work Supply → Selector v1.2 → Router)
- `control-plane/autonomy/kevin-work-selector-v1.2.py` (adds `skill-lab` lane + worker/capability metadata)
- `control-plane/autonomy/standing-programs-v1.json` (adds `owner-value-skills`)
- `control-plane/autonomy/kevin-supervisor-v1.8.9.ps1` (YELLOW source: honor router; no production install in this change)
- Tests: `tools/test-kevin-capability-router-v1.py`, `tools/test-kevin-work-admission-v1.py`
- CI: `.github/workflows/autonomy-capability-routing-v1-proof.yml`

## Live safety sequencing

1. Annotate OPEN owner composites with `lane: skill-lab`, `worker: skill-lab`, and `required_capabilities: [kevin_skill_lab_execute]`.
2. Live Supervisor v1.8.8 still runs selector v1.1, which treats `skill-lab` as `UNKNOWN_LANE` — so it **will not** send Skill Lab work to tool-less `fixed:main`.
3. Admission v1 + selector v1.2 prove the positive postcondition offline/CI: Skill Lab work is eligible and routed to Skill Lab.
4. Installing Supervisor v1.8.9 (router-aware) is a separate typed Maintenance/YELLOW crossing after CI green. Do not silent-replace v1.8.8 in this packet.

## Success criteria

- Owner Skill Lab demand remains visible as ready/blocked, not erased by Supervisor IDLE.
- Desktop-required work never dispatches to `fixed:main` while tools are false.
- No work invention; no Relay arbitrary shell; no production Desktop install from this packet.
