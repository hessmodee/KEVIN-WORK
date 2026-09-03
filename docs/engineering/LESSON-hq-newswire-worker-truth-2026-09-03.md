# HQ newswire publication and worker evidence

Owner incident: missing local/national/international headlines, repeated Reader E2E instruction, Benchmark degradation and apparently idle Reader/Staging/Tick/Chat lanes.

## Confirmed causes

- Newswire run 33695685618 fetched and validated 16 headlines covering all categories, then failed publication three times: `cannot pull with rebase: You have unstaged changes`. Published feed remained dated 2026-08-30T22:39:34Z. Existing six-hour freshness filtering correctly withheld old headlines but did not explain the outage.
- Historical CRLF blobs and LF attributes can make a fresh checkout appear dirty. Publish only the validated feed through a temporary Git index against the latest remote parent; never stage unrelated files, reset the checkout, or force-push. Retry at most three times if the remote moves.
- `dashboard-state.json.build` still contains the old Reader E2E objective. It is not proof that Reader needs another test. Ticker now uses fresh Benchmark evidence and current task/event information; regional headlines are interleaved early in the rotation. Changed telemetry preserves the selected story instead of constantly resetting the ticker.
- Reader, Staging and Chat lacked explicit worker-count consumption. Their display relied on matching an active task title. Tick/Bridge completed runs were briefly shown as WORKING. Honor fresh explicit counters or active tasks, reject terminal/stale tasks, and describe completed cycles in the worker detail. Do not animate invented work or expose private chat bodies.
- HQ header could say READY/OK while Benchmark failed. The header now checks Support's actual 30/30/zero-critical verdict. HQ Truth reports stale evidence, flags the newswire, avoids green styling for failed evidence, and labels repository desired-state differences accurately.

## Kevin's detection and recovery procedure

1. Compare source timestamps with the collection schedule. Do not substitute fetch time for observation time.
2. For missing news, inspect feed age, category coverage and the workflow's build/validation/publication stages separately. Preserve the fresh-news cutoff. Never publish synthetic headlines to hide an outage.
3. If publication fails on checkout dirt, use the fixed single-file publisher. Its test proves unrelated edits and concurrent Support commits survive and replay creates no duplicate commit.
4. After repair, require a successful workflow **and** a newer published feed with local/national/world categories. Verify the served HQ script contains the repair before claiming deployment.
5. For idle worker lanes, distinguish installed component, allowed invocation, current task, historical proof, private activity visibility and Kevin-owned selection. READY does not establish all six.
6. Keep Benchmark R04 red until the exact governed rebaseline passes 30/30. Preserve the repaired 16K chat configuration and all other trust anchors.
7. A delivered lesson is not learned mastery. Prove Kevin detects a seeded recurrence, selects the bounded procedure, verifies the result, records it and handles replay before promoting responsibility.

## Remaining machine-side prerequisite

The uploaded `.bak-modelid-20260901` is byte-identical to published Maintenance v1.3.43 (SHA256 `10F61948C428F1BC45D820D72355BE91A4E3E57C5ED7918FF6E260FE02F289A8`). The `.typed-*` file is byte-identical to v1.3.32 (`8C7C389C60BFAAE8AFB519435D1FA1A7297C5B702AC5F782951B390A80F7F871`). Neither is the observed installed runner (`3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E`). Preserve those originals; obtain the actual unsuffixed local file before extending its typed production operations.

Current independent machine-side outcomes remain unproved: R04 closure; fresh UI Bridge heartbeat; effective main tool inventory/action proof; Kevin-owned Reader/Staging/Chat selection and end-to-end verification. These are not repaired by an HQ display change.

## Validation and upstream references

- Real isolated Git publication regression: dirty tracked file, untracked file, concurrent Support commit, exact one-path diff, unchanged replay.
- Actual frontend function tests: regional ordering, stale/future feed, dangerous URL rejection, R04 headline, stale support, explicit lane counters, terminal tasks and stale task attribution.
- Existing HQ shell and overlay tests include stale active evidence aging out.
- [Git read-tree](https://git-scm.com/docs/git-read-tree) documents index-only reads without worktree updates. [GitHub schedule behavior](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows#schedule) documents delayed/dropped scheduled runs; the 15-minute schedule is offset from the top of the hour and is not advertised as a guaranteed deadline.

Technical proof and deployment receipts are recorded in the shared handover after CI and publication. No responsibility promotion is implied by these outside-engineered fixes.
