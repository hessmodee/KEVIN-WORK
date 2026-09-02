"""Candidate-only durable reservation store. No bootstrap, CLI, or effect executor.

The future typed adapter must authenticate migration provenance, bind the path,
enforce current authority/selector/hold checks, and independently verify effects.
This module alone grants no execution authority. Synthetic seeds live in tests.
"""
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
import re
import sqlite3
import time

# Describes the candidate format; production code never executes this DDL.
# Only test fixtures currently create a seed. Migration/authentication is absent.
FORMAT = [
    "CREATE TABLE anchor(schema INTEGER, migration_digest TEXT, complete INTEGER)",
    "CREATE TABLE mappings(item TEXT PRIMARY KEY, family TEXT NOT NULL, opening_attempts INTEGER NOT NULL)",
    "CREATE TABLE events(seq INTEGER PRIMARY KEY, reservation TEXT NOT NULL, item TEXT NOT NULL, family TEXT NOT NULL, fingerprint TEXT NOT NULL, kind TEXT NOT NULL, at TEXT NOT NULL, evidence TEXT)",
]
for table in ("anchor", "mappings", "events"):
    for operation in ("UPDATE", "DELETE"):
        FORMAT.append(f"CREATE TRIGGER immutable_{table}_{operation.lower()} BEFORE {operation} ON {table} BEGIN SELECT RAISE(ABORT, 'append only'); END")


class Closed(ValueError):
    """No effect or new reservation may proceed."""


def identity(value):
    if not isinstance(value, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,95}", value):
        raise Closed("invalid identity")
    return value


def digest(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-F0-9]{64}", value):
        raise Closed("invalid digest")
    return value


def instant(value):
    try:
        if not isinstance(value, str) or len(value) > 40:
            raise ValueError()
        at = datetime.fromisoformat(value)
        if at.tzinfo is None or at.utcoffset().total_seconds() != 0:
            raise ValueError()
        return at
    except (ValueError, TypeError, AttributeError):
        raise Closed("invalid UTC timestamp") from None


class Journal:
    MAX_ATTEMPTS = 3
    MIN_REPEAT_SECONDS = 900
    MAX_BYTES = 16 * 1024 * 1024
    MAX_MAPPINGS = 256
    MAX_EVENTS = 4096
    MAX_VM_STEPS = 2_000_000
    MAX_SECONDS = 2.0
    PROGRESS_INTERVAL = 1000

    def __init__(self, path, expected_migration_digest):
        # mode=rw never creates a missing database; there is no repair/bootstrap.
        self.path = Path(path)
        self.expected = digest(expected_migration_digest)

    @contextmanager
    def transaction(self):
        db = None
        try:
            # No truncation, rotation, pruning or automatic replacement on overflow.
            # The fixed adapter must additionally bind/authenticate this local path.
            if not self.path.is_file() or self.path.stat().st_size > self.MAX_BYTES:
                raise Closed("journal missing or storage bound exceeded")
            deadline = time.monotonic() + self.MAX_SECONDS
            steps = 0

            def progress():
                nonlocal steps
                steps += self.PROGRESS_INTERVAL
                return int(steps >= self.MAX_VM_STEPS or time.monotonic() >= deadline)

            db = sqlite3.connect(self.path.resolve().as_uri() + "?mode=rw",
                                 uri=True, timeout=0.5, isolation_level=None)
            db.set_progress_handler(progress, self.PROGRESS_INTERVAL)
            db.setlimit(sqlite3.SQLITE_LIMIT_LENGTH, 4096)
            db.setlimit(sqlite3.SQLITE_LIMIT_SQL_LENGTH, 4096)
            db.execute("PRAGMA cache_size=-1024")
            db.execute("PRAGMA synchronous=EXTRA")
            if db.execute("PRAGMA journal_mode").fetchone()[0] != "delete":
                raise Closed("unsupported durability mode")
            if db.execute("PRAGMA synchronous").fetchone()[0] != 3:
                raise Closed("durability setting unavailable")
            db.execute("BEGIN IMMEDIATE")
            page_size = db.execute("PRAGMA page_size").fetchone()[0]
            max_pages = self.MAX_BYTES // page_size
            if db.execute("PRAGMA page_count").fetchone()[0] > max_pages:
                raise Closed("journal page bound exceeded")
            if db.execute(f"PRAGMA max_page_count={max_pages}").fetchone()[0] != max_pages:
                raise Closed("journal growth limit unavailable")
            self.validate(db)
            yield db
            if time.monotonic() >= deadline:
                raise Closed("journal operation deadline exceeded")
            db.execute("COMMIT")
        except (sqlite3.Error, OSError):
            raise Closed("journal unavailable or invalid; no budget reset") from None
        finally:
            if db is not None:
                # An exhausted progress callback must never interrupt cleanup.
                db.set_progress_handler(None, 0)
                try:
                    if db.in_transaction:
                        db.execute("ROLLBACK")
                finally:
                    db.close()

    def validate(self, db):
        actual = {row[0] for row in db.execute("SELECT sql FROM sqlite_master WHERE sql IS NOT NULL")}
        if actual != set(FORMAT):
            raise Closed("journal schema mismatch")
        for table, maximum in (("anchor", 1), ("mappings", self.MAX_MAPPINGS), ("events", self.MAX_EVENTS)):
            count = db.execute(f"SELECT count(*) FROM (SELECT 1 FROM {table} LIMIT {maximum + 1})").fetchone()[0]
            if count > maximum:
                raise Closed("journal row bound exceeded")
        if db.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
            raise Closed("journal corrupt")
        if db.execute("SELECT schema, migration_digest, complete FROM anchor").fetchall() != [(1, self.expected, 1)]:
            raise Closed("validated complete migration required")
        mappings = db.execute("SELECT item, family, opening_attempts FROM mappings").fetchall()
        if not mappings:
            raise Closed("empty migration")
        known = {}
        for item, family, count in mappings:
            identity(item); identity(family)
            if item in known or type(count) is not int or count < 0:
                raise Closed("invalid migration mapping/count")
            known[item] = (family, count)
        reservations = {}
        terminals = set()
        previous = None
        for seq, rid, item, family, fp, kind, at, evidence in db.execute("SELECT * FROM events ORDER BY seq"):
            identity(rid); digest(fp)
            when = instant(at)
            if previous is not None and when < previous:
                raise Closed("history time regressed")
            previous = when
            if item not in known or known[item][0] != family:
                raise Closed("unknown canonical family")
            if kind == "RESERVED":
                if rid in reservations or evidence is not None:
                    raise Closed("invalid duplicate reservation")
                reservations[rid] = (item, family, fp)
            elif kind in {"FAILED", "VERIFIED"}:
                digest(evidence)
                if reservations.get(rid) != (item, family, fp) or rid in terminals:
                    raise Closed("invalid terminal correlation")
                terminals.add(rid)
            else:
                raise Closed("invalid event kind")

    @staticmethod
    def check_clock(db, at):
        now = instant(at)
        last = db.execute("SELECT at FROM events ORDER BY seq DESC LIMIT 1").fetchone()
        if last and now < instant(last[0]):
            raise Closed("clock moved backwards")
        return now

    def reserve(self, reservation, item, fingerprint, at):
        identity(reservation); identity(item); digest(fingerprint)
        with self.transaction() as db:
            now = self.check_clock(db, at)
            prior = db.execute("SELECT item, fingerprint FROM events WHERE reservation=? AND kind='RESERVED'", (reservation,)).fetchone()
            if prior:
                if prior != (item, fingerprint):
                    raise Closed("reservation identity conflict")
                status = db.execute("SELECT kind FROM events WHERE reservation=? ORDER BY seq DESC LIMIT 1", (reservation,)).fetchone()[0]
                return {"status": "REPLAY_" + status, "new_reservation": False}
            # Reserve room for the corresponding terminal; never strand a newly
            # accepted reservation merely because the event capacity is reached.
            if db.execute("SELECT count(*) FROM events").fetchone()[0] + 2 > self.MAX_EVENTS:
                raise Closed("journal full; validated migration required")
            mapping = db.execute("SELECT family, opening_attempts FROM mappings WHERE item=?", (item,)).fetchone()
            if mapping is None:
                raise Closed("unmapped item; no inferred family")
            family, opening = mapping
            if db.execute("SELECT 1 FROM events WHERE item=? AND kind='VERIFIED'", (item,)).fetchone():
                raise Closed("completed item cannot reopen")
            if db.execute("SELECT 1 FROM events r WHERE r.kind='RESERVED' AND NOT EXISTS (SELECT 1 FROM events t WHERE t.reservation=r.reservation AND t.kind IN ('FAILED','VERIFIED'))").fetchone():
                raise Closed("unresolved reservation requires independent recovery")
            item_count = opening + db.execute("SELECT count(*) FROM events WHERE item=? AND kind='RESERVED'", (item,)).fetchone()[0]
            family_count = db.execute("SELECT sum(opening_attempts) FROM mappings WHERE family=?", (family,)).fetchone()[0]
            family_count += db.execute("SELECT count(*) FROM events WHERE family=? AND kind='RESERVED'", (family,)).fetchone()[0]
            if max(item_count, family_count) >= self.MAX_ATTEMPTS:
                raise Closed("exhausted; no automatic reopening")
            last = db.execute("SELECT at FROM events WHERE family=? ORDER BY seq DESC LIMIT 1", (family,)).fetchone()
            if last and (now - instant(last[0])).total_seconds() < self.MIN_REPEAT_SECONDS:
                raise Closed("family repeat cooldown")
            db.execute("INSERT INTO events(reservation,item,family,fingerprint,kind,at,evidence) VALUES (?,?,?,?,?,?,NULL)",
                       (reservation, item, family, fingerprint, "RESERVED", at))
        # Returned only after durable COMMIT; never a tool/authority grant.
        return {"status": "RESERVED", "new_reservation": True}

    def record_terminal(self, reservation, kind, evidence_digest, at):
        """Persist the typed verifier's result, not an assertion of owner outcome.

        Verifier authentication and semantic receipt checks are integration gates.
        No caller-selected command, prose or effect body is accepted here.
        """
        identity(reservation); digest(evidence_digest)
        if kind not in {"FAILED", "VERIFIED"}:
            raise Closed("terminal kind rejected")
        with self.transaction() as db:
            self.check_clock(db, at)
            row = db.execute("SELECT item,family,fingerprint FROM events WHERE reservation=? AND kind='RESERVED'", (reservation,)).fetchone()
            if row is None:
                raise Closed("missing reservation")
            terminal = db.execute("SELECT kind,evidence FROM events WHERE reservation=? AND kind!='RESERVED'", (reservation,)).fetchone()
            if terminal:
                if terminal != (kind, evidence_digest):
                    raise Closed("conflicting terminal evidence")
                return "REPLAY_TERMINAL"
            if db.execute("SELECT count(*) FROM events").fetchone()[0] >= self.MAX_EVENTS:
                raise Closed("journal full; preserve unresolved reservation")
            db.execute("INSERT INTO events(reservation,item,family,fingerprint,kind,at,evidence) VALUES (?,?,?,?,?,?,?)",
                       (reservation, *row, kind, at, evidence_digest))
        return "RECORDED"

    def snapshot(self):
        with self.transaction() as db:
            return db.execute("SELECT * FROM events ORDER BY seq").fetchall()
