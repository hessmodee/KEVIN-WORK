# PLAN — Kevin Minecraft blueprint from image v1

**Date:** 2026-09-05 ~07:10 MT
**Authority:** UNDYING GREEN+YELLOW teach/docs (destination faculty — not live-proven).
**Companion:** `docs/engineering/KEVIN-PLAYBOOK-minecraft-survival-craft-farm-build-v1.md`
**Actions recipe:** `docs/engineering/KEVIN-RECIPE-minecraft-inworld-actions-v1.md`

## Goal

When Matt shows a picture (castle/house/farm) or describes a blueprint, Kevin should eventually: **see → plan voxels → list resources → gather → build** with Matt's invite, fail-closed, no grief.

**Status:** **PLAN / destination only.** No vision→build pipeline is proven. Do not claim castle/house complete without tool proof + Matt confirm.

## Preconditions

- Identity **kevinsk8erkid** only; never hessmodee.
- Realm join Layer A proven (`KEVIN_REALMS_JOIN_OK`) when building live.
- Matt **invites** the build and confirms site (coords / "by the house" / screenshot).
- Dig/place APIs (Layer B) available or Kevin stays in coach/plan mode only.
- No purchases; no Chat/Reader kill.

## Pipeline (fail-closed)

```
PICTURE / VERBAL BLUEPRINT
    → (1) INGEST + UNDERSTAND
    → (2) VOXEL PLAN + PALETTE + SIZE  [human confirm gate]
    → (3) RESOURCE LIST
    → (4) GATHER PLAN (wild / chest with ask)
    → (5) BUILD LAYERS (pause for review)
    → (6) VERIFY + MARK COMPLETE (proof only)
```

Any step missing proof or Matt go-ahead → **stop**, document, idle at bed / follow.

### Phase 1 — Ingest

- Accept image path / chat image / Matt's verbal dims ("10x10 cobble house, oak roof").
- Record source, timestamp, Matt's site cue.
- Refuse if unclear → ask one clarifying question (size, style, materials, site).

### Phase 2 — Voxel plan (destination)

- Produce layered grid: Y slices or schematic stub (`skills/build/blueprint-schema-v0.json`).
- Palette: map pixels/blocks to Bedrock block names (cobble, oak_planks, glass, etc.).
- Output: width × height × depth, door/window marks, roof type.
- **Gate:** Matt confirms plan before gather/build. No silent start.

### Phase 3 — Resource list

- Count blocks by type + tools needed + scaffolding extras (~10%).
- Split: already in Kevin inventory (when inventory API proven) vs gather vs ask Matt chests.
- Marker reserved: `KEVIN_MC_BLUEPRINT_RESOURCES_OK` (only after list written + Matt OK).

### Phase 4 — Gather

- Follow survival playbook gather loops; stay in invited area.
- Return to chest/staging near site; do not scatter chests without ask.

### Phase 5 — Build

- Place layer-by-layer (foundation → walls → openings → roof → detail).
- Use `place` stubs when proven; else coach Matt ("place cobble at …") — still useful today.
- Pause every N layers or on Matt interrupt.
- Never overwrite Matt builds; never dig through houses for shortcuts.

### Phase 6 — Verify

- Compare placed vs plan (when perception exists) or Matt visual OK.
- Only then: `KEVIN_MC_BUILD_OK` + receipt under `reports/engineering/`.
- **Forbidden:** saying "castle complete" / "house done" without that proof.

## Vision notes (destination)

- Prefer structured OCR/segment later; Minecraft UWP is OCR path for client UI, not yet build vision.
- Do not invent block counts from a glance in chat without a planner artifact on disk.

## Fail-closed matrix

| Signal | Action |
| --- | --- |
| No Matt invite / site | Idle; ask once |
| Plan not confirmed | Do not gather/build |
| Dig/place API missing | Coach mode only; no fake PLACE_OK |
| Kick / auth / wrong identity | Hard stop |
| Purchase / marketplace | Refuse |
| Destroy existing Matt build needed | Ask first; default refuse |

## Phased delivery

| Phase | Deliverable | Proof bar |
| --- | --- | --- |
| P0 | This PLAN + playbook + NEG + stubs | Docs merged |
| P1 | Blueprint schema + resource list generator (offline) | Fixture test |
| P2 | Layer B place/dig proven on Realm | Receipt markers |
| P3 | Image→palette assist (human-in-loop) | Matt-confirmed plan file |
| P4 | Semi-auto layer place | `KEVIN_MC_BUILD_OK` receipt |

## Non-goals

- Creative-mode fly spam; automatic city builders; grief "clear the plot"; hessmodee login; paid marketplace builds.
