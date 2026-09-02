"""Resource-limit regressions against disposable, explicitly synthetic seeds."""
from unittest.mock import patch
import tempfile
from pathlib import Path
import unittest

from test_attempt_journal import fixture, fixture_db, MIGRATION, FP, EVIDENCE, timestamp
from attempt_journal import Closed, Journal


class JournalBounds(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / 'history.db'
        fixture(self.path)
        self.j = Journal(self.path, MIGRATION)

    def tearDown(self):
        self.temp.cleanup()

    def history(self, rows):
        with fixture_db(self.path) as db:
            for n in range(rows):
                db.execute('INSERT INTO events VALUES (?,?,?,?,?,?,?,?)',
                           (n + 1, f'request-{n // 2}', 'alpha', 'family-one', FP,
                            'RESERVED' if n % 2 == 0 else 'FAILED', timestamp(),
                            None if n % 2 == 0 else EVIDENCE))

    def test_oversize_file_rejected_before_sqlite_open_without_truncation(self):
        with self.path.open('ab') as f:
            f.truncate(Journal.MAX_BYTES + 1)
        with patch('attempt_journal.sqlite3.connect') as connect:
            with self.assertRaises(Closed): self.j.snapshot()
            connect.assert_not_called()
        self.assertEqual(self.path.stat().st_size, Journal.MAX_BYTES + 1)

    def test_mapping_limit_accepts_boundary_and_rejects_one_more(self):
        with fixture_db(self.path) as db:
            db.executemany('INSERT INTO mappings VALUES (?,?,0)',
                           [(f'item-{n}', f'family-{n}') for n in range(Journal.MAX_MAPPINGS - 3)])
        self.assertEqual(self.j.snapshot(), [])
        with fixture_db(self.path) as db:
            db.execute("INSERT INTO mappings VALUES ('overflow','overflow',0)")
        before = self.path.read_bytes()
        with self.assertRaisesRegex(Closed, 'row bound'): self.j.snapshot()
        self.assertEqual(self.path.read_bytes(), before)

    def test_extra_anchor_fails_closed(self):
        with fixture_db(self.path) as db:
            db.execute('INSERT INTO anchor VALUES (1,?,1)', (MIGRATION,))
        with self.assertRaisesRegex(Closed, 'row bound'): self.j.snapshot()

    def test_event_boundary_can_be_read_without_discarding_history(self):
        self.history(Journal.MAX_EVENTS)
        self.assertEqual(len(self.j.snapshot()), Journal.MAX_EVENTS)

    def test_event_overflow_preserves_all_rows_and_rejects(self):
        self.history(Journal.MAX_EVENTS + 1)
        before = self.path.read_bytes()
        with self.assertRaisesRegex(Closed, 'row bound'): self.j.snapshot()
        self.assertEqual(self.path.read_bytes(), before)

    def test_capacity_leaves_room_for_terminal_and_allows_replay(self):
        self.j.MAX_EVENTS = 2  # Smaller synthetic capacity; production default unchanged.
        self.j.reserve('one', 'alpha', FP, timestamp())
        self.j.record_terminal('one', 'FAILED', EVIDENCE, timestamp(1))
        self.assertFalse(self.j.reserve('one', 'alpha', FP, timestamp(20))['new_reservation'])
        self.assertEqual(self.j.record_terminal('one', 'FAILED', EVIDENCE, timestamp(20)), 'REPLAY_TERMINAL')
        with self.assertRaisesRegex(Closed, 'full'): self.j.reserve('two', 'beta', FP, timestamp(20))
        self.assertEqual(len(self.j.snapshot()), 2)

    def test_insufficient_terminal_capacity_rejects_before_reservation(self):
        self.j.MAX_EVENTS = 1
        with self.assertRaisesRegex(Closed, 'full'): self.j.reserve('one', 'alpha', FP, timestamp())
        self.assertEqual(self.j.snapshot(), [])

    def test_full_legacy_seed_keeps_unresolved_reservation(self):
        self.j.reserve('one', 'alpha', FP, timestamp())
        self.j.MAX_EVENTS = 1
        with self.assertRaisesRegex(Closed, 'full'):
            self.j.record_terminal('one', 'FAILED', EVIDENCE, timestamp(1))
        self.assertEqual(self.j.snapshot()[0][5], 'RESERVED')

    def test_vm_budget_interrupts_expensive_query_and_rolls_back(self):
        with self.assertRaises(Closed):
            with self.j.transaction() as db:
                db.execute("INSERT INTO mappings VALUES ('temporary','temporary',0)")
                db.execute('WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<10000000) SELECT sum(x) FROM n').fetchone()
        with fixture_db(self.path) as db:
            self.assertIsNone(db.execute("SELECT 1 FROM mappings WHERE item='temporary'").fetchone())
        self.assertEqual(Journal(self.path, MIGRATION).snapshot(), [])

    def test_deadline_before_commit_rolls_back_without_clock_sleep(self):
        with patch('attempt_journal.time.monotonic', return_value=0.0) as clock:
            with self.assertRaisesRegex(Closed, 'deadline'):
                with self.j.transaction() as db:
                    db.execute("INSERT INTO mappings VALUES ('temporary','temporary',0)")
                    clock.return_value = Journal.MAX_SECONDS + 1
        with fixture_db(self.path) as db:
            self.assertIsNone(db.execute("SELECT 1 FROM mappings WHERE item='temporary'").fetchone())

    def test_large_sql_value_rejected_and_state_remains_valid(self):
        with self.assertRaises(Closed):
            with self.j.transaction() as db:
                db.execute('INSERT INTO mappings VALUES (?,\'family\',0)', ('x' * 4097,))
        self.assertEqual(self.j.snapshot(), [])

    def test_page_growth_limit_rolls_back_not_truncates(self):
        self.j.MAX_BYTES = self.path.stat().st_size
        with self.assertRaises(Closed):
            with self.j.transaction() as db:
                for n in range(10000):
                    db.execute('INSERT INTO mappings VALUES (?,?,0)', (f'new-{n}', 'f' * 90))
        self.assertLessEqual(self.path.stat().st_size, self.j.MAX_BYTES)
        self.assertEqual(Journal(self.path, MIGRATION).snapshot(), [])

    def test_oversized_timestamp_rejected_without_reservation(self):
        with self.assertRaises(Closed): self.j.reserve('one', 'alpha', FP, '0' * 10000)
        self.assertEqual(self.j.snapshot(), [])


if __name__ == '__main__':
    unittest.main()
