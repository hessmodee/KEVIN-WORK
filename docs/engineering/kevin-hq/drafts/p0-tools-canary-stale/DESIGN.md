# Design — Tools CANARY STALE honesty
**Target:** `docs/hq-owner-refinement-v3.js` Tools pulse chip · System · Command Attention  
**Themes:** tools freshness gate · never imply ON when canary/evidence stale  
**Extends:** P1-4 pulse freshness chips (#127) — **canary-specific**; do not redo #127 gate table  
**Banned:** HESS-PC operate · Minecraft · #122–#133 redos · Supervisor/ControlPlane pin changes

## Problem
P1-4 ages the Tools chip off dashboard `generated_at`, but `brain.tools===true` can still paint **ON** while the tools **canary / evidence** itself is stale or missing. Matt must never read Tools as live ON when canary is STALE.

## Signals (public only)
| Source | Field | Meaning |
|--------|-------|---------|
| `dashboard.brain.tools` | bool | Declared tools ON/OFF |
| `dashboard` / engineering tools evidence | `tools_canary_at` / `canary_at` / `tools_evidence_at` | Canary timestamp |
| age of canary vs gate | default **180s** (same Tools chip gate as P1-4) | STALE when exceeded |
| missing canary when tools claimed ON | — | treat as CANARY STALE (fail-closed) |

## Pure API — `toolsCanaryHonesty(input)`
```js
toolsCanaryHonesty({
  tools,              // true | false | null/undefined
  canaryAgeSec,       // number | Infinity | null (null = missing)
  canaryGateSec,      // default 180
  dashAgeSec          // optional; dashboard age (compose P1-4)
}) → {
  label,    // 'ON' | 'OFF' | 'CANARY STALE' | 'unknown'
  cls,      // 'fresh'|'stale'|'bad'|'unknown'
  chipTag,  // freshness tag for pulse chrome
  implyOn,  // true ONLY when tools===true AND canary fresh
  attention // optional Attention line when stale/off
}
```

### Rules
1. `tools === false` → `label='OFF'`, `cls='bad'`, `implyOn=false`, Attention: tools OFF
2. `tools === true` AND canary missing (`canaryAgeSec` null/undefined/NaN) OR `canaryAgeSec > gate`  
   → `label='CANARY STALE'`, `cls='stale'`, **`implyOn=false`** (never paint bare ON)
3. `tools === true` AND canary fresh → `label='ON'`, `cls='fresh'`, `implyOn=true`
4. else → `label='unknown'`, `cls='unknown'`, `implyOn=false`

### Honesty gates
- **Never** imply tools ON when canary/evidence stale or absent.
- Complements P1-4: keep Superv/Lease/… gate table; this packet only upgrades Tools label honesty.
- Do not reopen #127 patch identity — compose via `toolsCanaryHonesty` before rendering Tools chip value.
- Compose with p2-stale-source-quarantine when shipped (quarantine can starve WORKING; this owns Tools chip text).

## UI chrome
```text
Tools · STALE 4m
CANARY STALE          ← not "ON"
```
- System / pulse: same label.
- Attention when `label==='CANARY STALE'`: warn “Tools canary/evidence STALE — do not treat hands as live.”

## Test
`test-tools-canary-stale.cjs` + fixtures TOOLS_ON_FRESH · TOOLS_CANARY_STALE · TOOLS_OFF.
