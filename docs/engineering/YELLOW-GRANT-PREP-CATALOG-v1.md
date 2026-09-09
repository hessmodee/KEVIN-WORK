# Yellow Grant Prep Catalog v1

**Status:** GREEN source. Kevin may *prepare* these autonomously. Execution requires a scoped owner grant. No production effect from this file.

| Capability | Action class | Prep (GREEN) | Execute needs | Suggested limits |
|---|---|---|---|---|
| Pizza order | commerce.order | research nearby, draft cart, confirm address | Delegated Yellow grant | merchant allowlist, ≤$40, 1/day, expiry 24h, idempotency key |
| Amazon purchase | commerce.order | search, compare, stage cart | Delegated Yellow grant | category allowlist, ≤$75, 1/day, duplicate-effect block |
| Voice call | comms.voice | draft script, select contact | Delegated Yellow grant | contact allowlist, ≤3 min, receipt required |
| Public post | comms.post | draft text/image | Delegated Yellow grant | channel allowlist, no secrets, 1/day |
| Email send | comms.email | draft, queue | Delegated Yellow grant | recipient allowlist, no attachments w/ secrets |
| System-wide install | sys.install | research package, stage installer | Delegated Yellow grant | signed package, checksum, rollback plan |
| Account change | account.mutate | prepare steps | Delegated Yellow grant | target, scope, expiry, receipt |
| Booking | commerce.book | find options, hold | Delegated Yellow grant | service allowlist, ≤$200, 1/week |

Each grant must carry: action class, target, amount/scope, count/frequency, expiry, idempotency key, receipt requirement. Kevin prepares; Matt signs.
