# Kevin HQ repair review — 2026-09-03

The newswire and HQ evidence fixes are deployed. The Windows Benchmark remains 29/30 with the single R04 configuration-baseline failure; no claim of complete platform repair is made.

## Delivered and verified

| Item | Result | Evidence |
|---|---|---|
| Missing regional news | Publishing repaired; 16 fresh stories across local, national, world and top categories; errors0 | [Newswire run33698873780](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33698873780); feed2026-09-03T00:17:27Z |
| Repeated Reader E2E ticker | Historical build-plan label removed from ticker selection; fresh Benchmark/current task evidence used | [PR40](https://github.com/hessmodee/KEVIN-WORK/pull/40) |
| Worker visibility | Fresh Reader/Staging/Chat/Tick counters are honored; stale/terminal tasks and completed service cycles no longer imply current work | PR40 behavioral fixtures and deployed source checks |
| HQ Truth and header | Benchmark degradation shown; failed evidence not styled as success; stale news and repository pin differences explained | PR40 |
| Obsolete owner validation gate | Current v2 assets and behavior validated while preserving avatar/layout invariants | [PR41](https://github.com/hessmodee/KEVIN-WORK/pull/41), [merged CI33699165596](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33699165596) |
| Current autonomy selection | Fresh Supervisor continuation separated from dated full audit; overdue audit remains visible | [PR42](https://github.com/hessmodee/KEVIN-WORK/pull/42), [CI33699343555](https://github.com/hessmodee/KEVIN-WORK/actions/runs/33699343555) |

The five changed served core/worker scripts matched the tested files byte for byte. Final HQ Truth SHA256 is D1E092AFA10CE4A01B4ED77F961C752C9D963277CC08FD7B66854178E24919A0. The existing owl/avatar design and private-chat boundaries are preserved.

## Why the little owls can look idle

| Lane | What the evidence establishes | What remains unproved |
|---|---|---|
| Reader | An isolated read-only path and earlier 2/2 receipt are recorded. Live display now accepts a fresh explicit Reader worker count. | Current main-agent access and autonomous invocation/verification; exact patched runtime proof publication. |
| Staging | A policy-gated candidate-validation lane. No active eligible candidate means no current staging execution. | Independent replay/negative receipts and Kevin-owned candidate validation. |
| Tick | Scheduled health/telemetry cycles are running. Worker details show the last actual cycle and result. | A completed cycle is not an ongoing job; it does not prove useful autonomous work. |
| Chat | Owner-observed text reply and manual compaction succeeded after the 16K repair. Private conversation activity is not exported as a worker counter. | Effective main tool inventory/use remains empty in the latest owner evidence. Tool names or READY badges are not access proof. |

GitHub sync Bridge and the local interactive Windows UI Bridge are different components. GitHub sync can remain healthy while the Windows UI Bridge heartbeat is stale.

## Root causes and regression protection

Newswire run33695685618 built and validated the feed but failed publication on unstaged checkout changes. Historical CRLF blobs under LF attributes reproduce checkout dirt. The new publisher uses a separate Git index and latest remote parent, changes one fixed path, preserves concurrent Support commits, never force-pushes, and stops after three failed attempts. The real Git test covers dirty/untracked files, concurrent remote changes, exact publication scope and replay.

The source timestamp, rather than fetch time, determines freshness. Frontend tests cover stale/future news, missing categories, unsafe URLs, R04 status, terminal tasks, explicit counters, stale activity and current selection versus old audits. An obsolete post-merge UI gate initially failed because it asserted retired v1/cache-version strings; PR41 fixed that gate and passed its retained layout and behavior checks.

Official references: [Git index-only read-tree](https://git-scm.com/docs/git-read-tree); [GitHub scheduled workflow delays](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows#schedule). The existing 15-minute news schedule was offset from the top of the hour; GitHub does not guarantee exact execution times.

## Windows repairs still required

1. Recover the exact installed Maintenance source, then qualify/register the fixed R04 one-leaf baseline operation. Preserve the repaired 16K config, exact other anchors, backup/rollback and independent Benchmark30/30.
2. Refresh the full autonomy audit through a qualified fixed audit path. The existing publication-only request returned SUCCESS/AUTONOMY_UNCHANGED at18:13 MDT and is archived/retired. It does not rerun the assessment or reset the three-attempt failure budget.
3. After the platform gate is restored, repair and verify the Windows UI Bridge's fresh heartbeat through its typed path.
4. Collect the exact main policy, qualify the smallest useful GREEN tool/intent surface, and prove a real allowed tool action plus forbidden-action negatives. Then prove useful Reader/Staging/Chat selection, verification, replay and a subsequent correct scheduled decision.
5. Recover the live dashboard publisher source before replacing its hardcoded historical 8K/capability/build labels. Public HQ display changes do not change Windows tooling.

The uploaded backup files match published Maintenance v1.3.43 and v1.3.32. Neither matches the installed 3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E file. This session additionally checked 47 PowerShell blobs on the control-plane branch without a match, following the earlier 104 main-branch checks. Exact sources for the installed autonomy bridge and actuator were recovered and hash-matched; their fixed refresh path does not provide arbitrary execution or a current R04 operation.

Required source: the current unsuffixed `C:\Users\hessm\.openclaw\workspace\kevin-maintenance-runner.ps1`. A byte-preserving .txt copy can be uploaded. No further owner permission is required for the already-authorized repair; the missing input is the installed source and its bounded execution integration.

## Teaching and responsibility

The incident-derived lesson is in [LESSON-hq-newswire-worker-truth-2026-09-03.md](LESSON-hq-newswire-worker-truth-2026-09-03.md). Delivery uses the existing GREEN create_text composite `kevin-hq-newswire-worker-truth@1`; final runtime proof is in [the evidence receipt](../../reports/engineering/hq-repair-20260903.json).

Delivery and outside-engineered deployment do not establish learned mastery or T4/T5 autonomy. Next acceptance is Kevin recognizing the failure, choosing the bounded repair, independently verifying it, preserving failure history, recording the lesson and handling recurrence/replay. The shared handover and existing single Chief Engineer automation carry the remaining queue; duplicate automations are not needed.
