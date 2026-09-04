# LESSON - West Motor delivery-prep pack + Relay GitHub publish (2026-09-04)

## What happened
`west-motor-delivery-prep-pack@1` reached Skill Lab **PROVEN** ~16:17 MT America/Denver after PR #90 merged to `hessmodee/KEVIN-WORK` main and Relay consumed request `grok-stage-wm-delivery-prep-v1-20260904155800`.

Evidence:
- proof_sha256=777E1F4291425AC82B59CC8D140DFD9027E1F62EE3FC591021A6DEE21AD06ECD
- manifest_sha256=B533D343C40C5C2E0E309AECDF6B5598785BC997A1CFD45EA72BA15E8BBD7685
- skill_sha256=730950C2CCD337EE31C3AE3F1328E5C6097B0301F97460905FB7A5F02EFD8732
- steps: create_spreadsheet + create_text OK
- registry proven_count=24 (includes delivery-prep)

## Teach-forward
1. **Relay needs GitHub publish.** Local-only `inbox/engineering/request.json` is insufficient; Engineering Relay fetches skill + request from GitHub via `gh api`. Publish before expecting STAGED/PROVEN.
2. **Sheet cap 5.** Skill Lab Workbook rejects >5 sheets (LESSON sheet-cap). Keep ASCII-safe payloads and unique Kevin Outputs filenames.
3. **West Motor sequence:** lot-walk checklist -> recon priority board -> delivery prep -> (next) trade intake. Do not re-prove earlier packs in the chain.
4. **Docs lag is incomplete.** After PROVEN, close WI + TURNOVER + MEMORY + inventory + recipe + LESSON + receipt the same beat (teach-and-transfer).

## Hard no
Re-prove delivery-prep / recon-board / lot-walk / appliance@3; purchases; live DMS writes; live posting; secrets; kill Chat 18789 or Reader 19001; widen Desktop beyond exact-5.

## Addendum (trade-intake sheet name)
Skill Lab REJECTED `west-motor-trade-intake-pack@1` at 16:35 MT with `throwsheet name invalid` when a workbook sheet was named `Payoff / Equity` (slash). Rename to ASCII alphanumeric/spaces only (e.g. `Payoff Equity`). Restaged as `grok-stage-wm-trade-intake-v1-20260904164000`.
