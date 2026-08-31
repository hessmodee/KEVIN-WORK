# Kevin Gmail Adapter Candidate

Proof level: **DESIGNED / ISOLATED CANDIDATE** until CI and Omen evidence promote it.

Purpose: give Kevin a narrow bidirectional Gmail communication path using Kevin's own Gmail account without placing a normal Gmail password, OAuth refresh token, client secret, or message body in the public repository or HQ telemetry.

## Initial proof envelope

- OAuth 2.0 desktop/installed-app authorization only.
- Scopes:
  - `https://www.googleapis.com/auth/gmail.send`
  - `https://www.googleapis.com/auth/gmail.readonly`
- Initial outbound recipient allowlist: `hessmodee@gmail.com` only.
- No delete, label mutation, settings mutation, forwarding-rule, bulk-mail, or arbitrary-recipient operation.
- Inbound email is untrusted evidence, never executable authority by itself.
- OAuth authorized-user JSON is stored through the Windows keyring/Credential Manager backend under `Kevin.Gmail.OAuth`, not as `token.json` in the repository.
- First-run desktop OAuth client file is supplied only from an Omen-local private path and is never committed.
- Reply bodies are stored only in `%LOCALAPPDATA%\Kevin\Private\gmail-inbox` and the public-safe result contains only metadata/hash/length/path basename.

## Expected local prerequisites

Python 3.10+ and:

```text
google-api-python-client
google-auth
google-auth-httplib2
google-auth-oauthlib
keyring
```

## Proof ladder

1. `selftest` passes without Google access.
2. CI candidate gate passes syntax/unit/static secret-safety checks.
3. On the Omen, owner supplies a **Desktop app OAuth client JSON locally** and runs `enroll` in the interactive browser session.
4. Confirm the serialized authorized-user credential exists in Windows Credential Manager/keyring and no token/client secret appears in repo/log/HQ outputs.
5. `send-test` sends exactly one test message to `hessmodee@gmail.com` and records Gmail `message_id`/`thread_id` locally.
6. Matt replies normally in Gmail.
7. `check-reply` polls only the recorded Gmail thread, stores Matt's newest reply body locally, and returns public-safe metadata plus SHA256/length.
8. A separate local private-content interpretation skill reads that reply and reports Kevin's understood task; the email body itself must not be committed to the public repo.

## Credential enrollment checkpoint

Do **not** ask Matt to paste a password, OAuth token, client secret, recovery code, or API secret into ChatGPT/GitHub.

When this candidate reaches `READY_FOR_LOCAL_CREDENTIAL_ENROLLMENT`, ask only for any non-secret account identifier if needed, then provide a local Omen step that points `--client-config` at the downloaded Google Desktop OAuth JSON. The browser consent flow signs Kevin into the account directly.

## Commands

```text
python kevin_gmail_adapter.py selftest
python kevin_gmail_adapter.py enroll --client-config C:\PRIVATE\gmail-desktop-client.json
python kevin_gmail_adapter.py send-test --subject "Kevin communication proof"
python kevin_gmail_adapter.py check-reply
```

`send-test` refuses every destination except the fixed initial owner address.

## Promotion rule

This candidate may be researched, tested, and staged under the existing GREEN candidate-development authority. Actual external email send/read access is a consequential communication capability and should not be described as production-authorized or OMEN-PROVEN until the owner completes the local OAuth enrollment and the narrow proof is explicitly accepted/proven.
