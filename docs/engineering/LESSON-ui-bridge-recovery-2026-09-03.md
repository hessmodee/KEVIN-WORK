# UI Bridge recovery and proof boundaries

The owner directed Bess to perform repairs through the existing bridge without using Matt as routine transport. A fresh remote action_selftests request on 2026-09-03 passed Operator v0.3.3 and Initiative v0.3. UI Bridge hash and scheduled task were present, but its heartbeat was over seven hours old.

Detection: inspect the actual heartbeat observation time, component hash, task presence and current UI/Operator queues. A recent Engineering response does not make an old embedded heartbeat fresh. action_selftests executes Operator and Initiative self-tests; its UI Bridge result is metadata only.

Recovery: when the known UI Bridge hash and fixed task still match, queues are idle and the episode budget permits, use the existing restart_ui_bridge contract. Target ui_bridge_runner, task Kevin UI Bridge v0.3, heartbeat timeout 15 seconds. Do not change the binary, generalize paths or add arbitrary commands. One attempt for this incident; retire the manifest after a terminal response so an unrelated Benchmark failure does not trigger repeated restarts.

Verification: require a heartbeat newer than the request and another fresh observation showing it continues. Then exercise the already-proven ui_notepad_write primitive with a uniquely named verification file and require the typed output evidence. A registered composite proves its bounded output, not all computer actions.

Platform gate: the restart's final Benchmark gate can fail after the UI heartbeat recovers. Keep these truths separate. Benchmark must remain FAIL_CRITICAL_REGRESSION while R04 Production config frozen fails. Do not weaken R04, reset attempt history, undo the owner-proven 16K chat repair, or call the maintenance transaction fully accepted.

Source provenance: 62 branch heads and 226 reachable historical PowerShell blobs were checked. None matches installed Maintenance 3CFC77177324564DBE9632D078385119AB41831760212BD6A4FA3F613A7B0D6E. The uploaded suffixed files are older backups. Existing bridge contracts do not expose arbitrary source export. Preserve the unpublished script and obtain its exact bytes before extending its production path.

Transfer: this lesson and its Notepad verification are Bess-dispatched, Kevin-executed work (T2). Future mastery requires Kevin to detect a new recurrence, select the authorized repair, verify it, retain failure budgets and escalate only the unsupported part. No new tool authority is created by this lesson.
