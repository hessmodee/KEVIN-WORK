# LESSON — HQ Max Phase A publishers start with scrubbed count, not invented chips (2026-09-04)

## What happened
Phase 0 (#82) landed HQ truth chips that correctly refuse to invent Desktop exact-4, lease ACTIVE, Drive INTERIM, or grants_budget_unlock. Live Ops still needs those facts on the public Support/Engineering snapshots before chips can show them. Full publisher work (lease, Skill Lab route, Drive INTERIM, budget unlock, Night Forge Ops hide) is larger than one safe pass.

## Lesson
1. **Split UI truth from data-plane publishers.** Phase 0 shell may ship with `unknown`. Phase A must publish scrubbed fields; do not fake them in JS.
2. **Smallest durable field first.** Start with `desktop_tool_inventory_count` (integer) sourced from proven P0.1 receipt evidence — not by editing `openclaw.json` / Desktop allow-list / Chat ports.
3. **Live writers may be local-only.** `kevin-support-bridge.ps1` / `kevin-engineering-relay.ps1` live under HESS-PC `.openclaw\workspace`. Repo must carry PLAN/LESSON/helper/RECEIPT so the next engineer can reconstruct the wire without a second handover file.
4. **Night Forge READY-when-Disabled is Phase B** (Ops header UI). Do not conflate with publisher slice 1.
5. **Unknown remains sacred.** HQ must keep absent → `unknown` even after publishers start emitting partial `public_truth`.

## Evidence
- Merge #82: `3e1519368a0e8c2d37c378b333dc2ae11cdf2e2c`
- Pages path: `docs/hq-owner-refinement-v3.js?v=3` via `docs/index.html`
- P0.1 receipt: `reports/engineering/RECEIPT-p01-desktop-crossing-apply-20260904-0809.json` (`after.visible_tool_count` = 4)
- PLAN: `docs/engineering/PLAN-hq-max-phase-a-publishers-2026-09-04.md`

## Transfer
Next engineer: wire remaining Phase A fields into Engineering `action` / Support `public_truth`, then Phase B Night Forge Ops hide. Do not widen Desktop tools.