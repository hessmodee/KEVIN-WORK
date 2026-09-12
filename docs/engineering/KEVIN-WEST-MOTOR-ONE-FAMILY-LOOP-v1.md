# West Motor ONE family loop (v1)

**HARD GATE (Matt 2026-09-11 / CoS halt):** STOP minting clone `create_spreadsheet`+`create_text` PROVE packs / fresh west-motor|dealer xlsx aliases. Those stay **DESIGNED**. Do not mint four more PROVEN aliases for parts / aging / lot / delivery / recon / trade.

## One standing family

Treat West Motor owner-value as **one** standing family loop, not N independent PROVE products:

| Refresh slot (same family) | Canonical pack (already PROVEN — do not re-alias) |
|---|---|
| Parts chase | `west-motor-parts-chase-board-pack@1` |
| Aging inventory | `west-motor-aging-inventory-action-pack@1` |
| Lot walk | `west-motor-lot-walk-checklist-pack@1` |
| Delivery prep | `west-motor-delivery-prep-pack@1` |
| Recon priority | `west-motor-recon-priority-board-pack@1` |
| Trade intake | `west-motor-trade-intake-pack@1` (overshoot; no further clones) |
| Transport | `vehicle-transport-mission-pack@1` |

**Family id:** `west-motor-owner-value`

## Loop recipe (Tick / RUNTIME)

1. **Select refresh, not mint.** If the dealer needs a board again, refresh the existing canonical pack / standing WI — do **not** materialize `*-fresh-YYYY-MM-DD-vN` clone PROVE aliases.
2. **DESIGNED only** for new spreadsheet+text shapes in this lane. Lab may stage design; do not F17F-clone-prove.
3. **Outcomes.** Tick publishes `reports/owner-outcomes-latest.json` from `reports/invocations/done/` receipts. Actor honesty: `MIXED` / `GROKBOT_ACTED` / `KEVIN_ACTED`. `autonomy_credit=false` until true `KEVIN_ACTED`.
4. **Floor.** ONE CLOCK = `reports/hq-live-floor.json` cycle. Stripe `*_proven` / COMPLETED for packs already proven; `last_attempt` = newest receipt time. Bridge honest. No painter PR from RUNTIME.
5. **Lab GAP.** Cron owns `skill_lab.failed_count` leftovers — RUNTIME watches only; no pack paste as Kevin-learned.
6. **Browser-qual** stays design-only forever in this lane.

## Tick hook (intent)

On each Tick / PushPublic beat after owner invokes:

1. Rebuild `reports/owner-outcomes-latest.json` from done receipts (this recipe).
2. Publish to public main with floor (`Publish-Kevin-HqLiveFloor-v1.ps1 -PushPublic`) so Bridge/HQ see outcomes + ONE CLOCK.
3. Do **not** extend builder allowlist / F17F for new west-motor|dealer xlsx clones.

## Breach note (2026-09-11/12 night)

RUNTIME overshot freeze with recon-priority and trade-intake (and friction before hard stop). Dealer-vehicle-recon tip publish halted. Further clone PROVE minting is forbidden under Automatic Authority inside this gate.

## PASS

RUNTIME never claims PASS. VERIFY judges from receipts only.
