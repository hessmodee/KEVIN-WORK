# RECEIPT — Minecraft stack spike P0 (20260905-0935)

**At:** 2026-09-05 ~09:35 MT
**Actor:** GrokBot-executor
**Machine:** HESS-PC
**Scratch:** scratch/kevin-minecraft-stack-spike-v0

## Done

- Read PLAN + READY + bedrock-v0 package.json
- Fetched upstream zip via curl into isolated spike (vendor extract present locally; gitignored)
- Static API inventory: GoalFollow, combat, guard present
- Wrote install/smoke scripts + COMPAT notes
- JOIN_OK lockfile hash verified unchanged

## Not done / blocked

- Live `npm install` / `node smoke-require` in agent shell: binder error `The executable content could not be bound to this review` (approval retry also rejected)
- KEVIN_MC_STACK_SPIKE_IMPORT_OK not printed yet — operator should run install-deps.cmd + smoke-require.cmd
- Realms join / follow / combat **not** proven

## Next

1. Operator IMPORT_OK smoke
2. P1 join-compat design (client injection vs overlay)
3. P2 GoalFollow when Matt in Realm — only after join-compat
