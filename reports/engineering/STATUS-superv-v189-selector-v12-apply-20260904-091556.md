# STATUS â€” Superv v1.8.9 + selector v1.2 apply (2026-09-04 09:15 MT)

| Apply | Result | Before â†’ After | Notes |
|-------|--------|----------------|-------|
| Superv+selector YELLOW | **PASS** | Sup F5D8C974â€¦ â†’ 7BE40357â€¦; Sel v1.1 9DF1F770â€¦ preserved; Sel v1.2 52EADBCAâ€¦ live | Backup eports/supervisor-install-backup-20260904-090041; PR source C6E3CEF6â€¦ |
| Budget-unlock typed | **FAIL** | n/a (no mutate) | Qual NOT_READY; -Apply APPLY_REFUSED_PENDING_MATT; identity-key source missing |
| Forge M1 typed | **FAIL** | desired maint already DFF72850â€¦ | -Apply APPLY_REFUSED; M1 rewrite missing |
| Benchmark | **PASS** | 30/30 critical 0 | After Superv+R04 pin refresh |

Admission proof: router 5/5, admission 3/3, selector v1.2 selftest PASS.
