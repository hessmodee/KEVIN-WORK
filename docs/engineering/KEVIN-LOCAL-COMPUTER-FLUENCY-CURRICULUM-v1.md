# Kevin Local Computer Fluency Curriculum v1

**Owner:** Matt  
**Program:** `computer-fluency`  
**Authority:** GREEN learning and execution only through already-qualified typed primitives; YELLOW research/staging may prepare candidates but cannot self-promote production effects.

## Mission

Kevin must progressively learn to operate HESS-PC as a useful local AI worker without depending on Bess for routine computer actions. The durable loop is:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

A model answer is never proof that a computer action happened. Every useful capability must acquire real postcondition evidence, a recovery path, a reusable lesson, and replay evidence before it can be called mastered.

## Local/free production rule

Normal reasoning and tool use must remain local-first. Ollama/local models are the production default. Do not introduce a paid inference, credit, subscription, or automatic cloud fallback dependency. Internet access may be used for lawful research and acquiring reviewed free/open-source software, but a research result never authorizes installation, purchase, credential use, permission widening, or executable download by itself.

## Safety boundary

Computer fluency is **not** arbitrary shell authority. Do not grant or infer caller-selected PowerShell/cmd/exec, arbitrary executable paths or arguments, recursive unrestricted filesystem access, credential stores, permission changes, software installs, arbitrary downloads, generic mouse/keyboard control, or owner-representing external sends.

Prefer small typed primitives with fixed or tightly validated inputs, deterministic preconditions, semantic postconditions, rollback where applicable, and bounded retries.

## Phase 1 — Desktop orientation

Target primitives:

1. `kevin_desktop_find_folder`
   - resolve exactly one direct Desktop child folder by safe name;
   - reject traversal, separators, drive syntax and ambiguous matches;
   - do not expose private host paths in user-visible output.
2. `kevin_desktop_open_folder`
   - open only the uniquely resolved Desktop child in Explorer;
   - no arbitrary path or shell transport;
   - independently verify the visible Explorer outcome on Omen before promotion.
3. `kevin_app_launch`
   - fixed app allowlist initially: Notepad, Calculator, Paint, Explorer;
   - no caller-selected executable or arguments;
   - verify the expected process/window outcome rather than trusting the tool return alone.

### Acceptance

- CI unit/build/plugin validation passes on Windows and Linux.
- Qualified plugin is installed through a typed/reversible production path.
- fixed:main sees only the intentionally exposed Kevin tools while protected denies remain effective.
- One natural owner request opens a known Desktop folder with correlated postcondition evidence.
- Safe `not_found`, `ambiguous`, and prohibited-input trials fail closed.
- One natural owner request launches an allowlisted app and a prohibited executable request is rejected.
- Benchmark remains 30/30 critical 0.

## Phase 2 — File and folder literacy

After Phase 1 is repeatedly proven, add narrow read-oriented primitives rather than broad filesystem authority:

- list direct children of an owner-selected approved root;
- metadata/stat for a bounded resolved file;
- safe text preview with size/type/privacy limits;
- create/move/rename operations only inside explicit owner workspaces with collision and rollback rules;
- typed Office/document workflows built on proven primitives.

Every new primitive needs positive, negative, ambiguity, privacy, replay and recovery tests.

## Phase 3 — Application fluency

Expand app control only from real owner demand:

- discover installed applications read-only;
- launch fixed reviewed applications;
- use app-specific typed actions where a stable API or UI contract exists;
- prefer structured app APIs over generic mouse/keyboard automation;
- use UI Bridge only where no safer structured action exists, with session identity and visible postcondition proof.

## Phase 4 — Software research

Reader should maintain a bounded research procedure:

1. identify the owner objective and missing capability;
2. search official project/vendor sources plus independent security/reputation evidence;
3. prefer actively maintained free/open-source tools when they meet the need;
4. record license, source repository, release/version, Windows support, offline/local capability, privacy implications, update mechanism and known risks;
5. compare at least one alternative when consequential;
6. produce a recommendation/candidate only — installation remains a separately qualified typed action.

## Phase 5 — Self-maintenance and learning

For each recurring defect or successful trajectory, Kevin must:

- detect it from telemetry or owner intent;
- classify the semantic failure family so renaming/retrying cannot reset the budget;
- use Reader for fresh evidence where needed;
- create a bounded staging hypothesis with a named downstream consumer;
- execute only through proven GREEN mechanisms;
- verify the real semantic outcome independently;
- record sanitized evidence and a reusable lesson;
- submit a Skill Lab/Workshop procedure candidate when the trajectory is stable;
- replay it on a second representative task;
- promote responsibility only after repeated evidence;
- continue to another eligible owner-valued item instead of manufacturing activity.

## Worker roles

- **Reader:** evidence acquisition, software research, machine-state interpretation and contradiction handling. Read-only unless a separate typed primitive is explicitly selected.
- **Chat/fixed:main:** translate Matt's natural-language intent into qualified tools; never translate owner text into arbitrary shell.
- **Tick/Supervisor:** select the highest-value eligible GREEN work under WIP/failure-family budgets and continue without requiring Bess to provide an item ID.
- **Staging:** test candidates and failure cases before production crossing.
- **Skill Lab / Workshop:** convert repeated successful/corrected trajectories into governed reusable procedures; learning never creates new primitive authority.
- **Benchmark:** regression guard; green telemetry cannot override a failed semantic postcondition.

## Responsibility-transfer gates

Track computer fluency separately from code existence:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Do not promote merely because code exists, CI passes, a plugin loads, or a model claims success.

## Immediate curriculum queue

1. Finish Kevin Desktop v0.1 CI candidate gate.
2. Install it through a typed, pinned and reversible local production path.
3. Expose only `kevin_system_status`, `kevin_desktop_find_folder`, `kevin_desktop_open_folder`, and `kevin_app_launch` to fixed:main; preserve protected denies.
4. Prove real Desktop-folder and allowlisted-app round trips plus forbidden negatives.
5. Repair UI Bridge liveness/watchdog and prove a unique Notepad round trip without disturbing owner windows.
6. Stage a reusable `desktop-orientation` procedure and replay it on a second distinct owner task.
7. Put real computer-fluency work in the governed selector so Supervisor/Tick can select and continue it without Bess-supplied IDs.
8. Record every outside repair as autonomy debt until Kevin owns detection, selection, execution, verification, recovery and replay.

## Definition of success

Kevin is becoming self-reliant only when Matt can describe a normal computer goal in plain language, Kevin chooses the correct qualified capability, executes it locally, verifies the actual result, recovers from ordinary failure, records what it learned, and later repeats the job correctly without Bess repairing or dispatching the path.
