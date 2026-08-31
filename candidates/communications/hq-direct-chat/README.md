# Kevin HQ Direct Chat v0.1 — candidate

Status: **DESIGNED / candidate-only**. This is not production proof and does not claim a Matt -> Kevin -> Matt round trip.

## Owner goal

Provide a native private conversation surface in Kevin HQ so Matt can type a message to Kevin and see Kevin's reply directly, including from a phone.

## Architecture boundary

The public GitHub Pages HQ remains read-only. A public static page must never receive or persist private owner messages, OAuth material, Telegram tokens, bot tokens, chat IDs, OpenClaw configuration, or other secrets.

Production chat therefore requires an owner-private local transport hosted on or adjacent to the Omen and reachable only through an explicitly private path (for example loopback for same-host use or a separately configured private LAN/Tailscale path). The endpoint address and credentials, if any, stay local and are never committed to this repository.

The browser UI may submit only the typed envelope defined below. The local transport may translate an accepted message into Kevin's normal governed intent path. Message text is **intent/evidence, never executable authority**. It must not become an arbitrary command, shell string, executable path, argv, PowerShell, JavaScript, or permission override. Consequential actions still require existing typed authority.

## Typed envelope

Owner message:

```json
{
  "schema": 1,
  "kind": "kevin-owner-message",
  "request_id": "owner-<uuid>",
  "idempotency_key": "owner-<uuid>",
  "created_at": "RFC3339 timestamp",
  "channel": "hq-private",
  "sender": "owner",
  "recipient": "kevin",
  "content": "human-language message",
  "content_sha256": "64 uppercase hex chars"
}
```

Kevin reply:

```json
{
  "schema": 1,
  "kind": "kevin-owner-reply",
  "request_id": "owner-<uuid>",
  "reply_id": "kevin-<uuid>",
  "created_at": "RFC3339 timestamp",
  "channel": "hq-private",
  "sender": "kevin",
  "recipient": "owner",
  "status": "REPLIED",
  "content": "human-language reply",
  "content_sha256": "64 uppercase hex chars"
}
```

## Truthful lifecycle

Only these states are permitted:

- `QUEUED`: accepted by the private owner-chat transport but not yet acknowledged by Kevin intake.
- `RECEIVED`: Kevin intake has accepted the request ID/idempotency key.
- `THINKING`: Kevin is actively processing the request or constructing a governed downstream plan.
- `REPLIED`: a correlated reply has been durably produced.
- `FAILED`: processing ended with a bounded terminal failure and an owner-safe reason code.

A rendered textbox, a queued file, a transport ping, or an uncorrelated response is **not** ROUND-TRIP-PROVEN.

## Idempotency / replay

The same `idempotency_key` may be retried after a transport interruption but must never create a second Kevin task or a second owner-visible reply. A replay with different content for an existing key fails closed.

## Public proof policy

Repository/HQ public telemetry may expose only:

- request/reply IDs;
- lifecycle state;
- created/received/replied timestamps;
- elapsed milliseconds;
- content SHA-256 values;
- bounded reason codes;
- proof level.

Public proof must not contain message bodies, endpoint addresses, bearer material, bot tokens, cookies, private headers, local usernames/paths, or raw configuration.

## Mobile UX acceptance contract

When this panel is integrated into production HQ, validate at minimum 360px, 390px, 430px and desktop widths:

- no horizontal page scrolling;
- composer remains visible and usable when the software keyboard is open;
- primary send/retry controls have a minimum 44px touch dimension;
- transcript text remains readable without zoom;
- request status remains visible without covering the composer;
- long words/URLs wrap instead of overflowing;
- desktop layout and Ops Floor remain unchanged except the owner-requested communication/mobile improvements.

## Proof ladder

1. DESIGNED — schema/UX/security contract exists.
2. CI-PROVEN — deterministic validator/adversarial tests pass.
3. INSTALLED — exact local private adapter and HQ panel identities are verified on Omen.
4. OMEN-PROVEN — local adapter self-test proves typed intake, idempotency and private/public evidence split.
5. ROUND-TRIP-PROVEN — genuine Matt -> Kevin -> Matt message/reply with correlation and timestamps.
6. REPEATEDLY-PROVEN — repeated round trips survive refresh/retry/restart without duplication.
7. SELF-RELIANT — Kevin detects/reports/repairs bounded GREEN chat-transport failures through typed mechanisms.

## Explicit non-goals

This candidate grants no arbitrary shell, no public write API, no third-party messaging authority, no recipient expansion, no credential access, no production promotion, and no authority to interpret untrusted inbound content as executable instructions.
