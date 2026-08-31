# Kevin External Skill / ClawHub Scout — 2026-08-31

Purpose: reduce reinventing existing capability while preserving Kevin's owner-approved production boundary.

Status: RESEARCH / REUSE-SCOUT ONLY. Nothing listed here is installed or production-authorized by this document.

## Policy

Before building a new capability from scratch:
1. search OpenClaw native capabilities and ClawHub;
2. prefer official/native functionality when it satisfies the requirement;
3. for ClawHub, inspect owner/version/source, `openclaw skills verify @owner/slug`, Skill Card, security audit, VirusTotal/ClawScan findings, permissions, credentials, scripts and authority requested;
4. treat third-party skill content as untrusted evidence until reviewed;
5. never install a skill merely because it is popular or scanned clean;
6. compare the skill's authority surface with Kevin's current typed boundary;
7. if useful but overbroad, reuse interface/test ideas or extract a narrower candidate rather than importing excess authority;
8. installation/promotion still follows Kevin's proof/authority ladder.

## Gmail findings

### `@googleworkspace-bot/gws-gmail`
Observed capability surface includes Gmail read/search/send and helper operations such as reply/threading and watch/stream behavior.

Potential Kevin value:
- compare OAuth/account identity handling;
- compare thread-safe reply semantics;
- compare new-message watch/poll design;
- reduce custom Gmail API code if its exact local credential/storage model can satisfy Kevin's privacy and owner-only reply policy.

Do not adopt automatically. Kevin currently has a narrow owner-only Gmail policy and an existing candidate; compare before replacing.

### Other Gmail skills
ClawHub also contains third-party Gmail/inbox-secretary patterns. Some are draft-only; others include delete/archive/manage scopes. These are useful interface references but often exceed Kevin's current narrow owner-reply authority.

Decision: **research/compare first; no automatic install.**

## Windows / desktop-control findings

ClawHub contains Windows desktop-control skills capable of window/process management, keyboard/mouse simulation, screenshots, clipboard and arbitrary application launch/path arguments.

Potential Kevin value:
- learn common Windows UI primitives and failure cases;
- learn focus-before-input and unsaved-work checks;
- compare screenshot/window targeting patterns;
- compare local loopback control architectures.

Risk/fit:
- many packages expose generalized PowerShell, arbitrary paths/arguments, process start/kill and coordinate input;
- this is substantially broader than Kevin's current normal production typed-control policy.

Decision: **do not install as a shortcut to broad autonomy.** Prefer OpenClaw's declared Windows node/computer capabilities or narrowly typed Kevin primitives, with explicit policy, postconditions and rollback where applicable.

## OpenClaw native Windows direction

Current OpenClaw supports declared Windows node capabilities and an optional experimental Windows computer-use provider. Node commands must be declared and permitted by Gateway policy; computer-use requires paired capability, screen observation and explicit tool exposure.

Kevin path:
1. inventory actual Omen/OpenClaw version/capabilities locally;
2. determine whether native Windows node/computer-use exists and is compatible;
3. test in an isolated, non-consequential environment;
4. define the minimal typed action subset required for representative owner tasks;
5. require semantic UI evidence and focus/window identity;
6. promote incrementally rather than exposing unrestricted `system.run` or generalized desktop input to the normal owner-control plane.

## Browser / skills / other hubs

Use `openclaw skills search`, ClawHub and official OpenClaw docs as the default discovery pass before bespoke engineering. Verification/security metadata is a strong signal, not a guarantee.

For each candidate record:
- need/problem it solves;
- native OpenClaw equivalent if any;
- skill/publisher/version;
- trust verification state;
- authority/credentials requested;
- whether it reduces code and Bess dependency;
- whether it adds unacceptable privilege;
- decision: ADOPT / NARROW-REIMPLEMENT / RESEARCH-ONLY / REJECT.

## Current decisions

- Gmail: **COMPARE existing Kevin candidate with official/community GWS patterns; do not widen owner-only policy.**
- Windows desktop control: **NARROW-REIMPLEMENT / native OpenClaw evaluation**, not broad third-party install.
- Skill discovery: **make scouting a normal pre-build step.**
- External skill install: **never bypass proof, trust, privacy or owner authority.**
