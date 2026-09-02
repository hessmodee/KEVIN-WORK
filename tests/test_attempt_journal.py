"""Synthetic, temporary storage/effect fixtures. Never bootstrap Omen history."""
from datetime import datetime, timedelta, timezone
import hashlib
from pathlib import Path
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'control-plane/autonomy/candidates'))
from attempt_journal import Closed, FORMAT, Journal

MIGRATION = 'A' * 64
FP = 'B' * 64
EVIDENCE = 'C' * 64


def timestamp(minutes=0):
    return (datetime(2026, 9, 2, tzinfo=timezone.utc) + timedelta(minutes=minutes)).isoformat()


def fixture(path, opening=0):
    # Deliberately TEST-ONLY complete synthetic history, not recovered live state.
    with sqlite3.connect(path) as db:
        for sql in FORMAT:
            db.execute(sql)
        db.execute('INSERT INTO anchor VALUES (1,?,1)', (MIGRATION,))
        db.executemany('INSERT INTO mappings VALUES (?,?,?)',
                       [('alpha', 'family-one', opening), ('alias', 'family-one', 0), ('beta', 'family-two', 0)])


def sink(path):
    with sqlite3.connect(path) as db:
        db.execute('CREATE TABLE IF NOT EXISTS effects(reservation TEXT PRIMARY KEY, value INTEGER)')
        db.execute('INSERT OR IGNORE INTO effects VALUES (?,1)', ('request-one',))


def child():
    root = Path(sys.argv[2])
    mode = sys.argv[3]
    journal = Journal(root / 'history.db', MIGRATION)
    if mode == 'uncommitted':
        with journal.transaction() as db:
            db.execute('INSERT INTO events VALUES (1,?,?,?,?,?,?,NULL)',
                       ('request-one', 'alpha', 'family-one', FP, 'RESERVED', timestamp()))
            print('UNCOMMITTED', flush=True)
            sys.stdin.read()  # Parent terminates the actual process at this boundary.
    elif mode in {'reserved-crash', 'effect-crash'}:
        result = journal.reserve('request-one', 'alpha', FP, timestamp())
        if not result['new_reservation']:
            raise AssertionError('fresh fixture reservation required')
        if mode == 'effect-crash':
            sink(root / 'effect.db')
        os._exit(66)
    elif mode == 'compete':
        try:
            journal.reserve(sys.argv[4], 'alpha', FP, timestamp())
        except Closed:
            sys.exit(7)
    else:
        raise ValueError('fixed test mode rejected')


class JournalContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.path = self.root / 'history.db'
        fixture(self.path)
        self.j = Journal(self.path, MIGRATION)

    def tearDown(self):
        self.temp.cleanup()

    def fail_attempt(self, n, item='alpha', fp=FP):
        self.j.reserve(f'request-{n}', item, fp, timestamp(n * 20))
        self.j.record_terminal(f'request-{n}', 'FAILED', EVIDENCE, timestamp(n * 20 + 1))

    def test_reservation_is_charged_before_return(self):
        self.assertTrue(self.j.reserve('request-one', 'alpha', FP, timestamp())['new_reservation'])
        self.assertEqual(Journal(self.path, MIGRATION).snapshot()[0][5], 'RESERVED')

    def test_fingerprint_change_never_resets_exhaustion(self):
        for n in range(3): self.fail_attempt(n, fp=str(n) * 64)
        before = self.j.snapshot()
        with self.assertRaises(Closed): self.j.reserve('fourth', 'alpha', 'D' * 64, timestamp(90))
        self.assertEqual(before, self.j.snapshot())

    def test_family_alias_cannot_bypass_budget(self):
        for n in range(3): self.fail_attempt(n, item='alpha' if n % 2 else 'alias')
        with self.assertRaises(Closed): self.j.reserve('fourth', 'alias', FP, timestamp(90))

    def test_alternating_items_retains_all_history(self):
        self.fail_attempt(0); self.fail_attempt(1, 'beta'); self.fail_attempt(2)
        self.assertEqual([r[2] for r in self.j.snapshot()[::2]], ['alpha', 'beta', 'alpha'])

    def test_ab_a_epochs_remain(self):
        self.fail_attempt(0); self.fail_attempt(1, fp='D' * 64); self.fail_attempt(2)
        self.assertEqual([r[4] for r in self.j.snapshot()[::2]], [FP, 'D' * 64, FP])

    def test_missing_database_does_not_bootstrap(self):
        missing = self.root / 'missing.db'
        with self.assertRaises(Closed): Journal(missing, MIGRATION).reserve('one', 'alpha', FP, timestamp())
        self.assertFalse(missing.exists())

    def test_empty_database_rejected(self):
        self.path.unlink(); self.path.touch()
        with self.assertRaises(Closed): self.j.snapshot()

    def test_corruption_rejected(self):
        self.path.write_bytes(b'corrupt')
        with self.assertRaises(Closed): self.j.snapshot()

    def test_wrong_anchor_rejected(self):
        with self.assertRaises(Closed): Journal(self.path, 'D' * 64).snapshot()

    def test_incomplete_seed_rejected(self):
        with sqlite3.connect(self.path) as db:
            db.execute('DROP TRIGGER immutable_anchor_update')
            db.execute('UPDATE anchor SET complete=0')
            db.execute(next(s for s in FORMAT if s.startswith('CREATE TRIGGER immutable_anchor_update')))
        with self.assertRaises(Closed): self.j.snapshot()

    def test_recovery_proposal_cannot_be_seed(self):
        self.path.write_text('{"history_complete":false,"remaining_budget":null}')
        with self.assertRaises(Closed): self.j.snapshot()

    def test_unknown_item_has_no_inferred_family(self):
        with self.assertRaises(Closed): self.j.reserve('one', 'renamed-item', FP, timestamp())

    def test_pending_reservation_blocks_second_wip(self):
        self.j.reserve('one', 'alpha', FP, timestamp())
        with self.assertRaises(Closed): self.j.reserve('two', 'beta', FP, timestamp(30))

    def test_replay_never_issues_new_reservation(self):
        self.j.reserve('one', 'alpha', FP, timestamp())
        self.assertEqual(self.j.reserve('one', 'alpha', FP, timestamp(1))['status'], 'REPLAY_RESERVED')
        self.assertEqual(len(self.j.snapshot()), 1)

    def test_reservation_collision_rejected(self):
        self.j.reserve('one', 'alpha', FP, timestamp())
        with self.assertRaises(Closed): self.j.reserve('one', 'beta', FP, timestamp(1))

    def test_completed_item_cannot_reopen(self):
        self.j.reserve('one', 'alpha', FP, timestamp())
        self.j.record_terminal('one', 'VERIFIED', EVIDENCE, timestamp(1))
        with self.assertRaises(Closed): self.j.reserve('two', 'alpha', 'D' * 64, timestamp(40))
        self.assertFalse(self.j.reserve('one', 'alpha', FP, timestamp(40))['new_reservation'])

    def test_terminal_replay_and_conflict(self):
        self.fail_attempt(0)
        self.assertEqual(self.j.record_terminal('request-0', 'FAILED', EVIDENCE, timestamp(2)), 'REPLAY_TERMINAL')
        with self.assertRaises(Closed): self.j.record_terminal('request-0', 'VERIFIED', EVIDENCE, timestamp(2))

    def test_terminal_requires_reservation(self):
        with self.assertRaises(Closed): self.j.record_terminal('absent', 'VERIFIED', EVIDENCE, timestamp())

    def test_bad_clock_rejected(self):
        self.fail_attempt(1)
        for at in [timestamp(), 'yesterday', '2026-09-02T00:00:00']:
            with self.subTest(at=at), self.assertRaises(Closed): self.j.reserve('two', 'beta', FP, at)

    def test_family_repeat_interval(self):
        self.fail_attempt(0)
        with self.assertRaises(Closed): self.j.reserve('two', 'alias', FP, timestamp(2))

    def test_opening_attempts_preserved(self):
        self.path.unlink(); fixture(self.path, opening=4)
        with self.assertRaises(Closed): self.j.reserve('one', 'alpha', FP, timestamp())

    def test_append_only_sql_guards(self):
        self.fail_attempt(0)
        with sqlite3.connect(self.path) as db:
            for sql in ['DELETE FROM events', 'UPDATE events SET fingerprint="x"', 'UPDATE mappings SET opening_attempts=0']:
                with self.subTest(sql=sql), self.assertRaises(sqlite3.IntegrityError): db.execute(sql)

    def test_schema_tamper_rejected(self):
        with sqlite3.connect(self.path) as db: db.execute('DROP TRIGGER immutable_events_delete')
        with self.assertRaises(Closed): self.j.snapshot()

    def test_metadata_only_inputs(self):
        for rid in ['private message body', 'secret\nbody', 'x' * 97]:
            with self.assertRaises(Closed): self.j.reserve(rid, 'alpha', FP, timestamp())
        self.assertEqual(self.j.snapshot(), [])

    def run_child(self, mode):
        return subprocess.run([sys.executable, __file__, '--child', str(self.root), mode], timeout=15, capture_output=True)

    def test_process_death_before_commit_rolls_back(self):
        p = subprocess.Popen([sys.executable, __file__, '--child', str(self.root), 'uncommitted'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.assertEqual(p.stdout.readline().strip(), 'UNCOMMITTED')
            p.kill(); p.communicate(timeout=10)
        finally:
            if p.poll() is None: p.kill(); p.communicate(timeout=10)
        self.assertEqual(self.j.snapshot(), [])
        self.assertTrue(self.j.reserve('one', 'alpha', FP, timestamp())['new_reservation'])

    def test_process_death_after_reservation_preserves_charge(self):
        result = self.run_child('reserved-crash')
        self.assertEqual(result.returncode, 66, result.stderr)
        replay = self.j.reserve('request-one', 'alpha', FP, timestamp(1))
        self.assertFalse(replay['new_reservation'])
        self.assertEqual(len(self.j.snapshot()), 1)
        self.assertFalse((self.root / 'effect.db').exists())

    def test_process_death_after_effect_requires_reconciliation(self):
        result = self.run_child('effect-crash')
        self.assertEqual(result.returncode, 66, result.stderr)
        self.assertFalse(self.j.reserve('request-one', 'alpha', FP, timestamp(1))['new_reservation'])
        with sqlite3.connect(self.root / 'effect.db') as db:
            self.assertEqual(db.execute('SELECT * FROM effects').fetchall(), [('request-one', 1)])
        # Independent fixed fixture verifier finds committed sink evidence.
        self.j.record_terminal('request-one', 'VERIFIED', EVIDENCE, timestamp(2))
        self.assertEqual(len(self.j.snapshot()), 2)
        self.assertFalse(self.j.reserve('request-one', 'alpha', FP, timestamp(3))['new_reservation'])

    def test_concurrent_process_reservations_only_one_wins(self):
        children = [subprocess.Popen([sys.executable, __file__, '--child', str(self.root), 'compete', f'contender-{n}'], stdout=subprocess.PIPE, stderr=subprocess.PIPE) for n in range(2)]
        for p in children: p.communicate(timeout=15)
        self.assertEqual(sorted(p.returncode for p in children), [0, 7])
        self.assertEqual(len(self.j.snapshot()), 1)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--child': child()
    else: unittest.main()
