# Kevin Installer Packaging Doctrine v1

Status: ACTIVE ENGINEERING RULE

## Why this exists

A Max Engineering Loop v1.0.2 installer package failed at Windows PowerShell parse time before execution because of two packaging defects:

1. `return@()` created an invalid token boundary; PowerShell requires the return expression to be separated (`return @()`).
2. A double-quoted PowerShell string used C-style backslash escaping (`\"`) instead of PowerShell quoting rules, causing the string to terminate early.

The failure occurred before installer execution and therefore made no Kevin mutation, but it created avoidable owner intervention.

## Rule: parser-safe bootstrap

Large Kevin installers should be distributed as a small outer PowerShell bootstrap containing the real installer as hash-pinned bytes.

Outer bootstrap flow:

1. decode embedded inner installer to a temporary path;
2. verify exact SHA-256;
3. run `[System.Management.Automation.Language.Parser]::ParseFile` against the entire inner installer;
4. refuse execution on any parser error;
5. only after parser PASS, invoke the transactional inner installer;
6. delete the temporary inner file.

This makes syntax validation a pre-mutation gate on the owner's actual Windows PowerShell environment.

## Style rules

- Prefer readable multiline PowerShell over compressed one-line helpers in deployment installers.
- Put whitespace between control keywords and expressions, especially `return`, `throw`, and typed expressions.
- Never use C/JavaScript backslash quote escaping in PowerShell strings.
- Prefer single-quoted PowerShell strings when testing text that itself contains double quotes.
- Embedded component payloads still require their own parser/self-tests before installation.
- Parsing is necessary but never sufficient: candidate runtime self-tests, fresh Benchmark, backup/rollback, and authority-root verification remain mandatory.

## Owner-intervention objective

Avoidable installer syntax defects are considered engineering defects because they turn Matt into a manual test harness. Build packaging should detect them before any production mutation and, whenever practical, before the owner is asked to run the installer.
