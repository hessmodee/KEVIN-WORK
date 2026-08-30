# Kevin OS Awareness v0.1

## Purpose

Give Kevin a bounded, read-only, typed understanding of his Windows host before adding broader actuation.

This candidate does **not** grant shell authority or mutation authority. It observes known operating-system surfaces and records evidence locally.

## Typed observation verbs

1. `snapshot`
2. `hardware`
3. `processes`
4. `services`
5. `storage`
6. `tasks`
7. `network`
8. `software`
9. `event_health`

No caller can provide a command, executable, script path, registry path, WMI query, event-log query, process action, service action, or arbitrary file path.

## Data boundary

Detailed evidence remains local under `reports/os-awareness/latest-local.json`.

A separate `latest-public.json` contains only bounded summary counts and coarse hardware totals suitable for future support telemetry. It excludes command lines, environment variables, credentials, user documents, IP addresses, MAC addresses, serial numbers, event messages, registry secrets, and arbitrary file contents.

## Required proof before Omen promotion

- Windows PowerShell 5.1 parser pass.
- Self-test pass with unknown operation fail-closed.
- Static authority test confirms no process/service/task/network/registry mutation verbs and no download/network execution path.
- Real Windows CI execution of every typed observation verb.
- Omen installation through a typed pinned maintenance contract only.
- Omen self-test.
- Omen `hardware` proof must report physical memory and modules correctly.
- Omen full `snapshot` proof.
- Benchmark remains 30/30 with zero critical failures.
- Public summary inspected for privacy boundary.

## Next layers after v0.1

Once read-only OS observation is Omen-PROVEN, Kevin can use this evidence for diagnosis and planning. Separate campaigns can then add narrowly typed GREEN repair actuators for known Kevin-owned components. Observation does not itself authorize repair.
