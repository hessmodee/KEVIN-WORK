# Validator Negative-Fixture Rule v1

Status: ENGINEERING DOCTRINE

Security tests often contain dangerous-looking literals by design, for example `operation="shell"` or `command="whoami"`, so that the validator can prove those requests are rejected.

A production installer must not treat the mere presence of a negative-test literal as proof that the capability is enabled.

Required validation pattern:

1. Parse the candidate successfully.
2. Inspect executable constructs / AST command nodes for forbidden dynamic execution such as `Invoke-Expression`, shell launchers, or equivalent authority-expanding execution.
3. Verify remote request fields are not consumed as command strings.
4. Verify the typed operation allowlist is present and closed.
5. Require negative fixtures for forbidden operations and require their self-test to report blocked cases.
6. Run the candidate self-test before mutation.

Anti-pattern:

`if candidate_text contains "operation=\"shell\"" then reject candidate`

This anti-pattern creates a false positive exactly when a strong negative test is present.

This rule applies to future Operator, UI Bridge, browser, Skill Lab, maintenance, and engineering-relay installers.
