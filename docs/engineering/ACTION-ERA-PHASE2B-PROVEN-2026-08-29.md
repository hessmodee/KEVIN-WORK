# Kevin Action Era Phase 2B — Proven Capability Record

Date: 2026-08-29 MT
Status: LIVE + PROVEN

## Capability

Kevin can autonomously create a GREEN typed UI work order in his 24/7 background runtime, delegate it across a Windows interactive-session boundary, operate an allowlisted Windows application semantically, save and verify the result, capture screenshot evidence, close the application he owns, and continue unattended work.

## Proven end-to-end path

Initiative Engine -> Green Operator -> typed GREEN request -> LIMITED InteractiveToken UI Bridge -> Notepad -> semantic RichEditD2DPT target -> UI Automation ValuePattern -> save -> exact byte verification -> target-window screenshot -> close owned app -> audit/proof -> fresh Benchmark.

## Proven component identities

- Supervisor v1.6 High Gear: `63B8D9C27625E0FB6AFE62165BE376E7ED7EB416E5DA15BB47C206BBF4AE4989`
- Design Forge v3.7: `4C83DF29E765D61F2B26D2029FE6C2C7ED68DA90E5A7A457A82BE769029E22CA`
- Benchmark v1.1c: `02447EE8F3302E3EA1EF00290DBA6804F30FAC9F46CAE8714F402EA2D013CC38`
- Goal OS: `B20C7AC8EDC35C656ED544C4D13D3EB4FF4A79453AF0F49BD60B7DF31092AEF0`
- Support Bridge v1.1d: `E72A2A635326CF1AB036404E64E274D2F56CE79CA5CEB268DBF9B2EA4B67BEA5`
- Maintenance Runner v1.1d: `B47714C91EFDCCD1FAE6C2CB0B97D72F799125A63C084956916A8BD5A07678C1`
- Green Operator v0.3.3: `19EEA6749FB70EB18A6ACC2DC0C9DF4313C0AC0D893F646A6D1170044E4C282F`
- Initiative Engine v0.3: `8AA0DC8F5A1502A3E4D0150EB073DC77C29D47F153E066B32D6B8E4B2ACB7CD3`
- UI Bridge v0.3.4: `5516F60E118D9714A969322C930E525DF722DB099CF10BF5EB23822557598B42`

## First proven UI result

- Work order: `ui-bridge-first-win-20260829-224033`
- Operation: `ui_notepad_write`
- Authority: GREEN
- Text method: `uia_valuepattern`
- Save method: `uia_save_menu`
- Output SHA256: `170C0A8ACE6CEB29AE30B9AE219DC1D334EB29F050A26B33FC943324B157EE89`
- Screenshot SHA256: `436E3EFE5A2639103EFD2790523D9E247CB4FE9023F8793226B0EEE01081DFDE`
- Post-action Benchmark: PASS 30/30, critical=0

## Engineering lessons that are now doctrine

1. A 24/7 background process cannot be assumed to share the logged-in Windows desktop. UI execution belongs behind a LIMITED InteractiveToken bridge.
2. Discover modern packaged Notepad by its process `MainWindowHandle`, then enter UI Automation with `AutomationElement::FromHandle`; do not rely on root-tree process-start-time discovery.
3. UI readiness is asynchronous. Wait boundedly for the exact semantic control and supported pattern rather than testing once.
4. On this machine the proven Notepad editor surface is `RichEditD2DPT` with writable `ValuePattern`.
5. Evidence paths must be executed in candidate self-tests before promotion; parsing alone is not enough.
6. Installation must tolerate legitimate cron contention, but promotion requires a fresh successful benchmark rather than stale evidence.
7. Trust pins between components are part of the contract; a mismatch must defer/fail closed.
8. Semantic UI methods are preferred. Generic coordinate mouse and unrestricted keyboard remain blocked.
9. No UI session means DEFER, not FORCE.
10. A candidate/spec is not a capability. Only verified end-to-end evidence may enter the proven capability registry.

## Authority boundaries retained

- Arbitrary shell: BLOCKED
- Generic mouse coordinates: BLOCKED
- Unrestricted keyboard: BLOCKED
- Browser/network actions: not yet authorized by Phase 2B
- Purchases/financial transactions: BLOCKED without explicit owner approval
- External sends: BLOCKED without explicit owner approval
- Permission/credential/safety changes: never self-authorized
- Yellow/Red autonomous execution: BLOCKED

## Reusable architecture rule

Future application/browser primitives should reuse this shape:

`background control plane -> typed request -> authority check -> narrow interactive broker -> semantic target -> execute -> observe -> verify -> evidence -> audit -> continue`

New primitives expand authority and require the proof bar. Composite skills made only from already-proven GREEN primitives may be developed and tested through the governed Skill Lab without creating a new authority class.
