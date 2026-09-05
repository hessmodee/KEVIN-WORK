# PLAN addendum - JOIN_OK

## 11. JOIN_OK proven (2026-09-05 ~01:12 MT)

| Token | Value |
| --- | --- |
| AUTH_CACHE_OK | yes |
| KEVIN_REALMS_JOIN_OK | **yes** (real) |
| Transport | nethernet / NETHERNET_JSONRPC |
| Version / protocol | 1.26.45 / **2169** (UWP 1.26.4501 matched) |
| Soft residual | late packet_violation_warning on close |
| In-world after prove | no (auto-close ~2s) |

Receipt: `reports/engineering/RECEIPT-minecraft-bedrock-realms-join-ok-20260905-0112.md`
Log pointer (local only): `scratch/kevin-minecraft-bedrock-v0/_realms-join-nethernet12-2169.log`
LESSON: `docs/engineering/LESSON-nethernet-realms-join-ok-2026-09-05.md`
RECIPE: `docs/engineering/RECIPE-nethernet-realms-overlay-v2.md`
Rejoin: `scratch/kevin-minecraft-bedrock-v0/rejoin.cmd` (KEVIN_REALMS_STAY=1)

**Play loop:** wait house bed -> follow Matt -> chat -> invited build/mine -> fail-closed.
**Status:** JOIN_OK_TEACH_AND_TRANSFER - ready for next play session via rejoin.cmd.
