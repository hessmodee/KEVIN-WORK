# Kevin HQ Owner Refinement v1

Date: 2026-08-30 MDT

## Owner intent

Streamline Kevin HQ into a useful, continuously refreshed command center; remove redundant or misleading presentation; make handover sharing obvious; make Ops Floor states visually distinct and understandable; make worker owls more Kevin-like and entertaining only in ways tied to real telemetry; keep the top-left Kevin synchronized with the Ops Floor Kevin; and make Kevin himself selectable on the Ops Floor.

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
2. Header Reader operational status displays **READY** when its read-only boundary is GREEN. GREEN remains a safety/authority classification in deeper diagnostics; READY is the clearer operational status.
3. READY on Ops Floor is **dark blue `#244f8f`**. ARMED remains cyan `#68d8ce`.
4. ACTIVE now has its own **gold `#ffd166`** visual identity and explanation. ACTIVE means a worker lane is awake/participating in the current cycle; it is intentionally distinct from WORKING, which means a real task is executing.
5. Ops Floor definitions cover READY, ARMED, ACTIVE, WORKING, BUILDING, COOLDOWN, DEGRADED, and OFFLINE.
6. Worker owl eyes are transparent inside with colored outline rings. READY workers blink at deterministic, staggered rates and phases so the floor feels alive without implying work that is not happening. Kevin-like filled feet/toes remain.
7. Worker motion remains telemetry-linked: READY breathes subtly; WORKING bobs and blinks; BUILDING wiggles/bobs and blinks; DEGRADED signals instability; OFFLINE is dim and static.
8. Misleading worker progress bars remain removed. The old data path could emit placeholder 0% / cycle-complete values rather than true continuously measurable completion, so displaying those bars violates the truth-first UI rule.
9. Kevin's center hub is now keyboard- and mouse-selectable. Selecting another worker no longer strands the Selected Worker panel; clicking Kevin restores `Kevin — Chief of Staff` and Kevin's aggregate live state.
10. The Selected Worker panel now persists the owner's selection across Ops redraws and refreshes instead of being overwritten by background rendering.
11. While one or more worker owls are actually WORKING/BUILDING, Kevin's pupils look only toward those active workers, roughly one second at a time, in shuffled order, then return forward before repeating. The same gaze vector is posted to the top shell so the top-left Kevin mirrors the Ops-floor Kevin.
12. A conservative success celebration is enabled: only when the page observes a busy-to-idle transition plus success evidence (`PASS`, `SUCCESS`, `PROVEN`, `DONE`, `COMPLETED`, or `RECOVERY_PASS`) does Kevin perform a short flip/dance. The top-left Kevin receives the same celebration event.
13. Dynamic Ops content requests a fresh base render every 4 seconds; direct Kevin truth polling runs every 3 seconds; the top-shell Kevin truth poll runs every 3 seconds; and the overall HQ shell continues its no-store state render every 5 seconds. Static roadmap/capability copy is not falsely labeled real-time.

## False OFFLINE root cause and fix

The 2026-08-30 owner report that Kevin showed OFFLINE while the Omen was healthy exposed a timestamp-compatibility defect in the refinement layer. `support-latest.json` uses PowerShell/.NET timestamps such as `2026-08-30T22:40:34.1159186-06:00` with seven fractional-second digits. The refinement layer passed that string directly to `Date.parse()`. Browser implementations are not required to accept that extended precision consistently; an invalid parse became `Infinity` age and therefore OFFLINE.

Both the Ops and top-shell truth classifiers now normalize fractional seconds to millisecond precision before parsing. Support telemetry gets an 8-minute stale ceiling, which is safely above its 3-minute production cadence plus publication jitter while still failing closed on genuinely stale evidence. Dashboard telemetry keeps a 3-minute ceiling. The CI gate executes a real normalization/parsing test using a seven-digit PowerShell timestamp.

## Status meanings

- **READY:** healthy and available, no active job right now.
- **ARMED:** autonomy enabled, waiting between governed work cycles.
- **ACTIVE:** a worker lane is awake and participating in the current cycle; this does not by itself mean a user-visible task is executing.
- **WORKING:** a real task is executing now.
- **BUILDING:** Build Lab / Forge is creating or testing a candidate.
- **COOLDOWN:** bounded pause after throttling, retry, or recovery.
- **DEGRADED:** online, but a health/evidence issue needs attention.
- **OFFLINE:** fresh telemetry is unavailable beyond the allowed source-age window.

## Truth and safety

This remains an owner-requested presentation/observability change. It does not add shell authority, credentials, external-send authority, financial authority, or permission widening. Motion, gaze, ACTIVE styling, selection detail, and celebration are presentation behaviors derived from already-authorized telemetry. The UI must not manufacture work, success, or progress.

Dedicated workflow `HQ Owner Refinement v1 Gate` now checks JavaScript syntax, seven-digit PowerShell timestamp normalization, Kevin reselection, transparent owl-eye outlines, staggered blinking, gaze sync, celebration sync, ACTIVE color/definition, fake-progress removal, handover placement, Reader READY terminology, and near-real-time refresh invariants before the refinement is considered regression-qualified.
