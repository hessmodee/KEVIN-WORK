# Kevin HQ Owner Refinement v1

Date: 2026-08-30 MDT

## Owner intent

Streamline Kevin HQ into a useful, continuously refreshed command center; remove redundant or misleading presentation; make handover sharing obvious; make Ops Floor states visually distinct and understandable; make worker owls more Kevin-like and entertaining only in ways tied to real telemetry; and keep the top-left Kevin synchronized with the Ops Floor Kevin.

## Tab audit

- **Overview — KEEP.** Executive mission state, health, current operation, short roadmap, recent evidence, current system-load summary, Kevin evolution, and verified-result summary. The duplicate full 24-hour telemetry chart is removed here because System already owns that detail.
- **Ops Floor — KEEP.** Unique live topology and worker-state visualization. Refined in this change.
- **Talk · Exp — HIDE.** The page itself states that the channel is experimental with known session instability and is not a proven Kevin conversation channel. Keeping it in primary navigation adds noise without a proven operational function.
- **Activity — KEEP.** Unique chronological evidence/event history with component filtering.
- **System — KEEP.** Owns detailed current and 24-hour RAM/CPU/GPU telemetry; this is why the duplicate Overview chart is removed.
- **Roadmap — KEEP.** Unique full ordered capability roadmap. Overview retains only the short executive subset.
- **Capabilities — KEEP.** Unique inventory of capabilities, versions, QA counts, verification state, and planned/proven status.
- **Diagnostics — KEEP.** Unique implementation/runtime details and autonomous-build diagnostics useful during troubleshooting but intentionally separated from the executive Overview.

## Owner refinements

1. The existing current `AI-HANDOVER.md` control is moved to the **top of Overview**, before Living Mission Control. It retains no-cache retrieval and exposes **COPY KEVIN HANDOVER** plus the existing view action.
2. Header Reader operational status now displays **READY** when its read-only boundary is GREEN. GREEN remains a safety/authority classification in deeper diagnostics; READY is the clearer operational status.
3. READY on Ops Floor is now **dark blue `#244f8f`**. ARMED remains cyan `#68d8ce`.
4. Ops Floor has concise definitions for READY, ARMED, WORKING, BUILDING, COOLDOWN, DEGRADED, and OFFLINE.
5. Worker owl eyes are larger and include whites, pupils, and highlights. Feet are replaced with Kevin-like filled foot/three-toe geometry.
6. Worker motion is status-dependent: READY breathes subtly; WORKING bobs and blinks; BUILDING wiggles/bobs and blinks; DEGRADED signals instability; OFFLINE is dim and static.
7. Misleading worker progress bars are removed. The existing data path can emit placeholder 0% / cycle-complete values rather than true continuously measurable completion, so displaying those bars violates the truth-first UI rule.
8. HQ top-left Kevin and Ops Floor Kevin use the same live dashboard/support telemetry classifier. Ops posts its final state to the top shell when loaded; the top shell independently applies the same classifier on other tabs. Both refresh every 5 seconds.
9. The top shell requests a fresh HQ state render every 5 seconds instead of relying only on the legacy 15-second refresh, while existing no-store telemetry fetches remain intact.

## Status meanings

- **READY:** healthy and available, no active job right now.
- **ARMED:** autonomy enabled, waiting between governed work cycles.
- **WORKING:** a real task is executing now.
- **BUILDING:** Build Lab / Forge is creating or testing a candidate.
- **COOLDOWN:** bounded pause after throttling, retry, or recovery.
- **DEGRADED:** online, but a health/evidence issue needs attention.
- **OFFLINE:** telemetry stale or component unreachable.

## Truth and safety

This is an owner-requested presentation/observability change. It does not add shell authority, credentials, external-send authority, financial authority, or permission widening. Status animation is derived from telemetry; it must not manufacture work. CI checks JavaScript syntax and owner-requested invariants before this refinement is considered regression-qualified.
