# PLAN — HQ Max Phase A publishers (slice 1) — 2026-09-04

## Intent
Publish scrubbed public fields from Support / Engineering snapshots so HQ Command truth chips can show real Desktop exact-4 inventory, mission_lease status, ROUTED_TO_SKILL_LAB, Drive INTERIM marker, and grants_budget_unlock — while preserving the Phase 0 rule that **absent fields stay `unknown`** (never invent exact-4, ACTIVE lease, INTERIM, or unlock).

## Boundary
- **Phase 0 (merged #82):** HQ shell + gate + chips with unknown fallback. Cache `docs/hq-owner-refinement-v3.js?v=3`.
- **Phase A (this track):** data-plane publishers / snapshot shape. Live writers: `kevin-support-bridge.ps1`, `kevin-engineering-relay.ps1` (HESS-PC `.openclaw\workspace`, not historically repo-tracked).
- **Phase B (later):** hide Night Forge in Ops header when Disabled (live screenshot still shows READY). UI-only; not this PR.

## Non-goals / hard constraints
- Do **not** edit `openclaw.json`, Desktop exact-4 allow-list, Chat ports, or Owl geometry.
- Do **not** force-push `main`.
- Public payload remains metadata-only (no configs, secrets, raw prompts, private paths).
- Unknown fallback remains mandatory in HQ when a field is missing/null.

## Full Phase A field set (target)
| Field | Intended public home | Notes |
|---|---|---|
| `desktop_tool_inventory_count` | Support `public_truth` (+ Engineering `action.public_truth`) | Exact-4 LIVE count; scrubbed integer only |
| `desktop_tool_inventory_names` | optional later | Public tool names only if already owner-safe |
| `mission_lease` | Engineering `action.mission_lease` | status/id only |
| `routed_to_skill_lab` | Engineering `action` | bool / enum `ROUTED_TO_SKILL_LAB` |
| `drive_interim` | Support or Engineering public_truth | marker only |
| `grants_budget_unlock` | Support or Engineering public_truth | bool / unknown |

## Slice 1 (this PR) — smallest publisher field
1. Teach-and-transfer **PLAN** (this file) + **LESSON**.
2. Repo helper `workspace/kevin-public-truth-v1.ps1` emitting scrubbed `public_truth` starting with **`desktop_tool_inventory_count`** (from P0.1 receipt evidence path; never reads/writes `openclaw.json`).
3. Wire helper into live Support bridge on HESS-PC (local-only until repo gains a tracked bridge copy).
4. RECEIPT proving the field shape and that HQ may still show `unknown` until the live publish lands.

## Verify
- Helper self-check returns count `4` from P0.1 receipt without touching openclaw.
- Support snapshot (after live wire) includes `public_truth.desktop_tool_inventory_count`.
- HQ chips continue to show `unknown` for fields not yet published.
- Pages still serves `hq-owner-refinement-v3.js?v=3` after #82.

## Rollback
Revert this PR. Remove `public_truth` from live Support bridge snapshot construction. Cache-buster unchanged (`?v=3`).

## Next slices
- A2: mission_lease + ROUTED_TO_SKILL_LAB into Engineering `action`.
- A3: drive_interim + grants_budget_unlock.
- A4: HQ chip wiring for the new named sources (still unknown if absent).
- B: Night Forge Ops-header hide when Disabled.