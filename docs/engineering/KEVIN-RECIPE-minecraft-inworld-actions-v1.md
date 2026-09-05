# KEVIN RECIPE — Minecraft in-world actions (bedrock-protocol) v1

**Updated:** 2026-09-05 ~07:10 MT
**Authority:** UNDYING GREEN+YELLOW.
**Edition:** Bedrock LOCKED. Scratch: `scratch/kevin-minecraft-bedrock-v0/`.
**Prerequisite:** Stay join via `rejoin.cmd` → `KEVIN_REALMS_JOIN_OK` (+ heartbeat when `KEVIN_REALMS_STAY=1`).

## Honest status

| Action | Status | Notes |
| --- | --- | --- |
| Join / stay / heartbeat | **PROVEN** | NetherNet 2169 / 1.26.45 |
| Chat `text` | **PROVEN path** (opt-in HI gated) | `client.queue("text", …)` as kevinsk8erkid |
| Look nudge `move_player` | **Stub landed** (opt-in) | `KEVIN_REALMS_MOVE_PROBE=1` → marker `KEVIN_REALMS_MOVE_PROBE_OK` if entity pos known — **not** walk/dig |
| Walk / pathfollow | **Near / stub** | Not proven; follow Matt = etiquette destination |
| Dig / break block | **Near / stub** | Module stub only |
| Place block | **Near / stub** | Module stub only |
| Craft / inventory | **Near / stub** | APIs not live-proven |
| Farm loops | **Destination** | Wiki + playbook teach; no `FARM_OK` yet |
| Blueprint build | **Destination** | PLAN only |

## After JOIN stay — action map

### Chat (known)

```js
client.queue("text", {
  type: "chat", needs_translation: false, source_name: "kevinsk8erkid", xuid: "",
  platform_chat_id: "", filtered_message: "", message: msg
});
```

Rules: rate-limit; never impersonate hessmodee; no hi while Matt asleep; default HI off.

### Look / move probe (known stub)

Env: `KEVIN_REALMS_MOVE_PROBE=1` (default OFF).
Packet attempt: `move_player` with same position, tiny yaw delta.
Success log: `KEVIN_REALMS_MOVE_PROBE_OK`. Skip soft if no `client.entity.position`.

### Walk (stub — not proven)

Destination: repeated `player_auth_input` / movement packets with pathing. **Do not claim follow-as-packet proven** — etiquette "follow Matt" is behavioral intent until stub ships + receipt.

Module stub: `skills/build/../` → `skills/gather/move-stub.js` (scaffold).

### Dig (stub — not proven)

Destination packet family (Bedrock): block dig / player action start/stop break. Exact field layout must be validated against protocol 2169 before live use.

Stub: `skills/gather/dig-stub.js` → reserved marker `KEVIN_MC_DIG_OK`.

Safety: only invited blocks; never Matt builds/chests/bed without ask.

### Place (stub — not proven)

Destination: inventory select + place block packet facing a support block.

Stub: `skills/build/place-stub.js` → reserved `KEVIN_MC_PLACE_OK`.

### Craft / inventory (stub — not proven)

Destination: read `inventory_content` / `inventory_slot`; crafting via window/recipe packets or server-side craft where available on Realms.

Stubs: `skills/craft/craft-stub.js`, `skills/craft/inventory-stub.js`.
Reserved: `KEVIN_MC_CRAFT_OK`, `KEVIN_MC_INV_OK`.

**Today:** Kevin may **list recipes verbally** from wiki (tools/food) without claiming crafted.

### Farm (stub — not proven)

Stub: `skills/farm/farm-loop-stub.js` — survey/till/plant/harvest sequence calling dig/place later.
Reserved: `KEVIN_MC_FARM_OK`.

## Env flags (default safe)

| Env | Default | Meaning |
| --- | --- | --- |
| `KEVIN_REALMS_STAY` | set by rejoin | Stay after join |
| `KEVIN_REALMS_CHAT_HI` | OFF | Chat hi only if stay + Matt present policy |
| `KEVIN_REALMS_MOVE_PROBE` | OFF | One look nudge |
| Future action flags | OFF | Must default OFF until receipt |

## Fail-closed

- No token → `READY_FOR_OWNER_DEVICE_CODE`
- Preflight MC UI → wait; do not kill Minecraft.Windows
- Packet unsupported → soft skip + log; do not fake OK markers
- Kick / uninvite / wrong identity / purchase → hard stop
- Never hessmodee

## Proof rule

OK markers and "I crafted/planted/built X" require same-turn tool output or `reports/engineering/RECEIPT-…`. Otherwise say **READY / stub / destination**.
