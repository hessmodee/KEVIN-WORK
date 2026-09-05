# READY_FOR_HOME_OPTEST

**When:** 2026-09-05 ~11:15 MT (America/Denver)
**Verdict:** GO for tonight live op-test (owner must close MC UI first)

## Checklist

| Item | Status |
| --- | --- |
| Chat 18789 | LISTEN |
| Reader 19001 | LISTEN |
| Operator 19101 | LISTEN |
| Auth caches (5) credentials/kevin-minecraft/ | present |
| Protocol 2169 / 1.26.45 | COMPAT-REALMS-NETHERNET.md |
| JOIN_OK gym lock SHA256 | 26397A3E84558B6841143C75CC9DEE5B25928AE7CBC58C384C2C1592F8BC865D unchanged |
| smoke-require IMPORT_OK | PASS |
| smoke-bridge | PASS |
| smoke-companion-wire | PASS |
| preflight-home-optest.cmd | HOME_OPTEST_PREFLIGHT=GO |
| rejoin-companion.cmd | exit 2 while MC UI open (correct); uses rejoin-companion.js inject |
| gym rejoin.cmd + preflight-stay.cmd | present |
| Skill library + elite playbooks | present |
| Desktop exact-5 (TOOLS) | kevin_system_status + 3 desktop folder tools + kevin_app_launch |
| Minecraft.Windows | OPEN = CLOSE_REQUIRED before rejoin |

## Owner-only

- Close Minecraft.Windows
- Xbox as hessmodee
- Device-code reauth if caches rejected
- Claim FOLLOW_OK/COMBAT_OK only after live receipts

## Pointers

- Playcard: scratch/kevin-minecraft-stack-spike-v0/OPTEST-PLAYCARD-HOME-2026-09-05.md
- Entry: scratch/kevin-minecraft-stack-spike-v0/rejoin-companion.cmd
- Safe sweep: scratch/kevin-minecraft-stack-spike-v0/preflight-home-optest.cmd
