# READY_FOR_OWNER_AUTH

**Status:** Waiting on Matt device-code as **kevinsk8erkid** (never hessmodee).
**Where to run:** `scratch/kevin-minecraft-bedrock-v0` on HESS-PC

## Root cause of tonight's failure

Matt used (or was shown) `microsoft.com/link?otc=CODE` / `oauth20_remoteconnect`.

That path returns:
> We're unable to complete your request
> application is a first party application, the user does not have consent, and users are not permitted to consent to first party applications

**ClientId was already correct:** `Titles.MinecraftNintendoSwitch` = `00000000441cc96b` (Bedrock-known-working live title). The bug was the **URL shape**, not the client.

Second attempt (`Y69M3S274` -> "That code didn't work" + `ECONNRESET` to `oauth20_desktop.srf`) = expired/wrong code and/or network reset mid Xbox Live login. Start fresh.

## Exact Matt next step (PHONE preferred)

1. On HESS-PC, in that scratch folder, run:
   ```
   node scripts/device-code-auth.js
   ```
2. On **phone** browser (or PC): open **exactly** `https://www.microsoft.com/link`
3. Sign in as **kevinsk8erkid** only.
4. **Type** the 8-character code from the terminal / `READY_FOR_OWNER_DEVICE_CODE.txt`.
5. Wait until the terminal prints `AUTH_CACHE_OK`.
6. Then: `node scripts/realms-join.js`

### HARD NO

- Do **not** open any `?otc=` link (even if prismarine-auth message suggests `link?otc=` — ignore that ALT).
- Do **not** use hessmodee.
- Do **not** invent passwords.
- Do **not** kill Chat 18789 / Reader 19001.

## If phone link still fails

### Option B — Omen interactive browser (request_box_help)

```
request_box_help: Bedrock device-code for kevinsk8erkid
1) Confirm HESS-PC is running: node scripts/device-code-auth.js in scratch/kevin-minecraft-bedrock-v0
2) Read CODE from scratch/.../READY_FOR_OWNER_DEVICE_CODE.txt (CODE= line)
3) On Omen box browser: open https://www.microsoft.com/link (NO ?otc=)
4) Sign in as kevinsk8erkid (owner interactive session — never hessmodee)
5) Type CODE manually; wait for AUTH_CACHE_OK on HESS-PC
```

### Option C — sisu / msal scripts

- `node scripts/sisu-auth.js` — same live client, sisu Xbox path
- `node scripts/msal-device-auth.js` — microsoftonline device login (last resort; weaker title tokens)

## After auth

- Success: `AUTH_CACHE_OK` then join -> `KEVIN_REALMS_JOIN_OK`
- Or: `NETHERNET_GATE` (Realms 26.10+; bedrock-protocol #717)