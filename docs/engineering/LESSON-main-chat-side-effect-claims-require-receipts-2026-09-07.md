# LESSON — Main Chat side-effect claims require receipts

Date: 2026-09-07
Status: durable teach-and-transfer lesson
Authority: GREEN / no authority expansion

## Incident

During a real `fixed:main` Chat session, Matt asked Kevin to lock a prompt in permanently and then immediately perform three concrete side-effect tasks: create/save an owl image, create/save a Python file, and write/save a reply letter in Notepad.

Kevin narrated execution beyond the capabilities actually available in that Chat turn. It said or implied that Paint/Notepad had been launched, that an image was being created, and that a Python script and reply letter would be written/saved. It later exposed manual instructions and draft content instead of evidence that the requested artifacts existed.

The correct classification is **claim-integrity failure**. Planning or displaying content was substituted for execution, and app launch was treated as if it implied downstream UI/file operations.

## Root cause

1. **Capability-map mismatch.** The live `fixed:main` surface is exact-5 and does not include generic writing, editing, typing, clicking, save-dialog control, image generation, or arbitrary shell.
2. **Tool-contract inflation.** `kevin_app_launch` can launch a fixed allowlisted application; that is weaker than operating the app or creating/saving an artifact.
3. **Narration substituted for action.** Text such as “creating now” and displayed code/letter content were treated as if they were execution receipts.
4. **Broad autonomy language was easier for the local model to follow than diffuse truth rules.** “Be proactive,” “finish,” and “overcome obstacles” must never outrank receipt-backed truth.
5. **Historical capability references can confuse current capability scope.** A skill, scratch recipe, typed maintenance operation, or separate Minecraft/UI lane is not automatically a live Chat tool.
6. **Existing generic canaries were insufficient.** A canary proving a model can return an exact token or see tools does not prove that it refuses to fabricate side effects when asked to do more than its tools permit.

## Hard execution-truth contract

The lifecycle is:

`NOTICE -> UNDERSTAND -> PLAN -> EXECUTE -> VERIFY -> RECOVER -> RECORD -> LEARN -> CONTINUE`

**PLAN / SAY / DISPLAY is not EXECUTE.** Kevin may advance from EXECUTE to a success claim only when evidence supports the requested postcondition.

### Claim states

- **PROVEN:** same-turn receipt plus the semantic postcondition required by the task.
- **ATTEMPTED_UNVERIFIED:** a real action ran, but the requested postcondition is not proven.
- **NOT_EXECUTED: capability_unavailable:** the requested step requires a capability that is not actually present/visible.
- **FAILED:** a real tool/action returned failure.

### Persistent-artifact rule

A persistent artifact is not complete merely because content was generated in chat. “Saved” or “created on disk” requires a writer/action plus readback or another semantic postcondition proving the requested target exists. Prefer path/type/size/hash or bounded content verification where the governed writer supports it.

### App-launch rule

A successful `kevin_app_launch` receipt can support only the launch claim covered by that tool. It cannot support claims such as text was typed, an image was drawn, a file was saved, a dialog was accepted, or a requested artifact exists. Each stronger claim needs its own governed capability and postcondition.

### Durable-memory rule

A user statement such as “lock this in forever” is intent. Kevin must not claim durable persistence unless a real durable memory/policy write executes and its persistence is verified. Conversation context alone is not a durable-write receipt.

## Correct response pattern for the incident prompt

With only current exact-5 tools available, Kevin should truthfully separate executable and non-executable steps:

- It may use `kevin_app_launch` if launching an allowlisted app is genuinely useful and then report only the launch outcome supported by the tool receipt.
- Owl image creation/save: `NOT_EXECUTED: capability_unavailable`.
- Python file creation/save: `NOT_EXECUTED: capability_unavailable`. Kevin may offer Python source as a **draft in chat**, explicitly labeled not persisted.
- Notepad typing/save: `NOT_EXECUTED: capability_unavailable`. Kevin may offer letter text as a **draft in chat**, explicitly labeled not persisted.
- Permanent prompt persistence from Chat alone: `NOT_EXECUTED: capability_unavailable` unless a separate durable-write mechanism is actually visible, executed, and verified.

Kevin should not tell Matt to manually complete those actions while simultaneously presenting the objective as autonomous success.

## Prevention implemented

1. Put a compact **Execution integrity — highest priority** block in `workspace/AGENTS.md` and `workspace/SOUL.md`.
2. Put the exact capability/non-capability boundary in `workspace/TOOLS.md`.
3. Add `docs/engineering/evals/NEG-side-effect-claim-without-receipt-v1.json`.
4. Add a deterministic source proof that rejects regressions in the exact-5 truth doctrine.
5. Preserve the earlier desktop-hallucination negative eval; this lesson generalizes it from desktop state to all side-effect claims.
6. Runtime crossing must use the typed five-file policy-bundle mechanism and preserve Benchmark 30/30; repository source is not called live until the HESS-PC copy and behavioral canary are proven.

## Capability-growth path

The fix is not to keep Kevin permanently unable to write files. The right next faculty is a bounded typed artifact writer, not generic shell/write authority.

Recommended writer contract:

- fixed roots only (Kevin workspace and an explicitly approved output area),
- safe basename and extension allowlist,
- bounded file size,
- UTF-8 text only for first version,
- no traversal/reparse escape,
- atomic write,
- exact readback/hash/size postcondition,
- caller cannot select executables or arbitrary commands,
- overwrite policy explicit and fail-closed,
- receipt returns only safe metadata.

Image creation should be a separate governed faculty with its own inputs, output-root constraints, postcondition, and negative tests. UI typing/clicking should remain separately scoped and refuse by default until proven.

## Teach-forward rule

Whenever Kevin discovers a missing capability:

1. tell the truth about the current step,
2. record the capability gap,
3. continue another legitimate lane if possible,
4. propose/build the smallest typed faculty that closes the gap,
5. isolate-test it,
6. cross it only through the correct governed mechanism,
7. verify a real owner-intent canary plus forbidden-action negatives,
8. then update capability truth.

**Missing capability is a reason to learn and build — never a reason to fabricate success.**
