# Lesson: distinguish runtime overflow from model noncompliance

Consumer: fixed-main qualification, Maintenance diagnostics, and Chief Engineer triage. This lesson adds diagnosis; it does not promote a capability or authorize another attempt.

## Evidence

The September 2 09:00:25 MDT public main-canary receipt reports `REJECT`, `semantic_contract`, CLI exit 0, wrapper status `ok`, and a 127-character final answer. Its output SHA256 is:

`3C9BD342FA050017F16FF421A1288D97BE4F116174831E0A55A351C336112B4B`

That length and digest exactly match this public OpenClaw recovery text:

> Context overflow: prompt too large for the model. Try /reset (or /new) to start a fresh session, or use a larger-context model.

The match was calculated from upstream source at commit `0790d9f593ad30c940ed93b5872a8cf6d6f3cf8c`, the resolved `v2026.7.1-2` tag. It was not inferred from answer length alone, and no private transcript was recovered or published.

Sources:

- [Immutable Kevin receipt](https://github.com/hessmodee/KEVIN-WORK/blob/29918d21fa23b9c2263b3ddc63dccd7e4dad5a93/reports/main-agent-canary-omen.json).
- [Upstream runtime error construction](https://github.com/openclaw/openclaw/blob/0790d9f593ad30c940ed93b5872a8cf6d6f3cf8c/src/agents/embedded-agent-runner/run.ts).
- [Upstream error formatting](https://github.com/openclaw/openclaw/blob/0790d9f593ad30c940ed93b5872a8cf6d6f3cf8c/src/agents/embedded-agent-helpers/errors.ts).
- [Upstream overflow regression tests](https://github.com/openclaw/openclaw/blob/0790d9f593ad30c940ed93b5872a8cf6d6f3cf8c/src/agents/embedded-agent-runner/run.overflow-compaction.test.ts).

This is materially stronger evidence than “Qwen ignored the exact-reply instruction.” It identifies a stock runtime error in the published output. It does not establish whether the underlying cause is prompt growth, reserved output budget, a provider/context mismatch, session reuse, compaction, or another runtime condition. The published receipt omits the structured error needed to distinguish those branches.

## Detection and response rule

1. Inspect structured runtime failure metadata before treating a non-exact final answer as model behavior. In the reviewed upstream source, the overflow path emits `payloads[].isError`, `meta.error.kind`, blocked liveness metadata, and the recovery text. Wrapper `status: ok` and process exit 0 are insufficient to prove a successful agent turn.
2. When only a public receipt exists, recognize a known runtime message only through its exact SHA256 and expected length. A 127-character reply with a different digest remains unclassified.
3. Preserve the original receipt and its `REJECT` result. Diagnosis must never rewrite acceptance, strip the error banner, reset attempt history, or count the run as a semantic pass.
4. Preserve `tool_calls: null` when a transcript is incomplete. Zero observed calls in a partial transcript is not a proven zero-call turn. Absent/null/malformed tool inventory is distinct from an explicitly reported empty inventory.
5. Obtain fixed read-only evidence: installed package/source identity; effective main provider/model/context settings; input and reserved-output budget; bootstrap/skills/tool contribution sizes; and the existing request/session/error correlation. Publish allowlisted metadata only.
6. Form one falsifiable repair hypothesis from those measurements. Change one bounded cause with rollback and unchanged acceptance, then use the existing typed proof path. A renamed request, model switch, larger context label, or another `/no_think` suffix is not new evidence.

For the local provider, [Ollama's read-only running-model endpoint](https://docs.ollama.com/api/ps) exposes `context_length`. A provider alias containing `16k` is not proof of the loaded model's actual context allocation. Larger context also consumes more memory; measure before changing it, as described in [Ollama's context documentation](https://docs.ollama.com/context-length).

## Executable teaching artifact

`control-plane/diagnostics/main_canary_diagnosis.py` is a Python standard-library, metadata-only classifier. Its CLI accepts no caller arguments, reads only `reports/main-agent-canary-omen.json`, bounds input size, rejects duplicate/nonfinite JSON, and emits a sanitized diagnosis. It performs no model call, configuration write, repair, or network operation.

`classify_runtime_envelope()` is a pure helper for a future qualified collector. It distinguishes runtime errors, explicit tool inventory, absent evidence, malformed evidence and contradictions. It does not authenticate a runtime envelope or prove actual tool execution. It is not wired into the installed Omen Maintenance runner.

`tests/test_main_canary_diagnosis.py` covers the actual incident signature, misleading equal-length output, wrapped errors, partial transcripts, contradictory fields, missing/null/empty inventory, and privacy/invalid-input cases. `.github/workflows/main-canary-diagnosis.yml` runs the tests on Linux and Windows and creates a diagnosis artifact whenever the public main-canary receipt changes. Its GitHub permission is read-only.

Qualification command:

```bash
python -m unittest discover -s tests -p test_main_canary_diagnosis.py -v
python control-plane/diagnostics/main_canary_diagnosis.py
```

This is a reusable diagnostic and durable engineering lesson. Kevin independently learning, selecting, installing or using it on Omen remains unproven. Work-selection transfer remains T2.
