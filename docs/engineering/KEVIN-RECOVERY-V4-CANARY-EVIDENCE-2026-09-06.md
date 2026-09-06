# Kevin Recovery v4: durable canary evidence-location repair — 2026-09-06

## Failure observed

Owner ran the SHA-verified Recovery v3 `-CheckOnly` on HESS-PC. It stopped with `Fresh main-agent canary receipt missing`. The owner later manually invoked `-Apply`; that invocation stopped at the identical preflight guard before `Repair-R04` or UI-task repair was reached.

Therefore both v3 invocations were safe false-stops: no production config, Benchmark baseline, R04 anchor, scheduled UI task, or other recovery target was mutated.

## Root cause

Recovery v3 correctly required the fresh fixed-main canary, but incorrectly assumed that the canary published to `KEVIN-WORK/reports/main-agent-canary-omen.json` was also retained at `~/.openclaw/workspace/reports/main-agent-canary-omen.json` on HESS-PC.

The proof itself is real. Commit `131f3afd51413f228be64ef660a8e51d9be96a0e` modified `reports/main-agent-canary-omen.json` at 2026-09-06 20:27:33Z; the exact source Git blob is `ec76565f225fdcb880ab0bbad6a58b5d555e2de0`. It records `OMEN_PROVEN`, fixed:main, exact reply, Qwen 14B on `ollama-chat-16k`, and exactly five visible Kevin tools. The local dual-model isolation proof preceding it remains separately required.

This is a durable-evidence-location bug, not a reason to weaken the canary requirement.

## v4 design

`Repair-Kevin-Recovery-20260906-v4.ps1` is a narrow wrapper around the already qualified v3 engine. It requires the exact v3 script SHA256 `DAC43A...` and does not duplicate or alter v3's R04, rollback, Benchmark, UI-task, or Notepad logic.

When a real local main-agent canary exists, v4 validates it and it outranks the published fallback. A stale, contradictory, or pre-isolation local canary causes a fail-closed stop; v4 never hides it.

Only when the local canary is absent may v4 use `Kevin-Recovery-Main-Canary-20260906.json`. That evidence capsule is SHA256-pinned, tied to current qualified config `29383...`, source commit `131f3...`, source blob `ec765...`, exact-five tool-name hash, output hash, correlated transcript hash, Qwen provider/model, and timestamp. CI independently reconstructs the source from Git history and compares the capsule fields to the pinned commit/blob.

Because v3 accepts only its historical workspace path, v4 stages the capsule's canary payload there transiently, runs exact v3, and removes the staged file only if its bytes are unchanged. If another process changes that file while recovery runs, v4 preserves it rather than deleting potentially newer evidence.

The staging write is evidence-only. It does not alter `openclaw.json`, Benchmark baseline, scheduler, UI task, or model runtime. Recovery v3 remains the sole production mutation engine and still performs its exact preconditions before any R04 change.

## Operator discipline learned

Do not hand the owner a command block that contains both CheckOnly and Apply. A PowerShell `throw` is not an interactive workflow barrier if later lines are manually pasted/run. Future recovery crossings are split into separate turns: first CheckOnly only; Apply is provided only after the returned READY output is independently reviewed.

## Transfer lesson for Kevin

Published evidence and local evidence are different durability domains. A recovery gate must either regenerate its required proof through a typed path or explicitly support a cryptographically pinned durable evidence source. It must not assume publication implies local retention, and it must never let fallback evidence override contradictory fresher local evidence.