# Kevin R04 Production-Config Rebaseline v1 — Candidate

Status: **CANDIDATE ONLY / NOT INSTALLED**

Purpose: close the single intentional Benchmark R04 drift created when Matt validated the fixed:main context/compaction repair on 2026-09-02, without reverting the good OpenClaw configuration and without weakening Benchmark.

## Exact approved identities

- repaired `openclaw.json`: `23DA8F7F0EE12A7453B70ABC03138BEB54686185CF2238100637ECAF1F8A93A5`
- immediately pre-repair accepted config: `215AC88DF59FE91DD38580E8A77A488096CA77AFE840AACDBB1530DA760B5A84`
- Benchmark runner: `4C766122A83A3A3B268C07F0AE0A8A7C9F33BA1A7B25ECE6855ABA61E3297964`

The repaired config is additionally required to retain:

- `ollama-chat-16k/qwen2.5:14b`
- model/provider context 16384
- Ollama `num_ctx=16384`
- `reserveTokensFloor=2048`
- `reserveTokens=2048`
- `keepRecentTokens=4000`

## Production preconditions

The PowerShell candidate refuses unless:

1. all fixed files exist at their canonical Kevin/OpenClaw locations;
2. current production config bytes match the exact owner-proven repaired SHA;
3. config JSON still contains the intended repair contract;
4. Benchmark runner bytes match the exact proven runner SHA;
5. baseline schema/kind/hashes are valid;
6. baseline `hashes.production_config` is exactly the old pre-repair accepted SHA;
7. baseline Benchmark runner anchor matches the current proven runner;
8. fresh/latest Benchmark evidence is exactly 29/30, critical1, with only R04 failing.

## Allowed mutation

Exactly one semantic leaf:

`$.hashes.production_config`

from the old accepted config SHA to the owner-proven repaired config SHA.

Every other baseline semantic leaf must hash identically before/after.

## Transaction

`preflight -> byte backup -> stage -> one-leaf semantic proof -> atomic replace -> recheck config/runner -> fresh Benchmark -> require PASS30/30 critical0 -> receipt`

Any failure after mutation restores the exact baseline backup and verifies its SHA before returning failure.

## Authority boundary

- no arbitrary paths;
- no caller-supplied command/argv;
- no config mutation;
- no Benchmark source mutation;
- no Supervisor/Forge/Reader/Goal/Promotion mutation;
- no shell strings from owner/model input;
- no network or credentials;
- no permission or authority expansion.

The only process launched is the fixed local Benchmark runner through fixed `powershell.exe` arguments after the one-leaf baseline transition.

## Why this is not installed yet

The installed Maintenance runner has local hash `3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`, while its exact Grok-patched source was not durably committed. Replacing that runner merely to gain this operation risks undoing morning progress. This candidate must first pass CI and then be connected through a governed exact-current execution path that does not overwrite the unknown installed Maintenance lineage.

The candidate does **not** grant itself that transport.
