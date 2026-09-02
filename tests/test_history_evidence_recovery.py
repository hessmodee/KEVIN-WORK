"""Synthetic unit cases plus exact-byte published receipt replay; no runtime calls."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("recovery", ROOT / "control-plane/autonomy/candidates/history_evidence_recovery.py")
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
A, B = "A" * 64, "B" * 64


def row(item="fixture-work-a", fp=A, turns=3, last="2026-09-01T01:00:00Z", status="IN_PROGRESS"):
    return dict(id=item, fingerprint=fp, turns=turns, last_turn_at=last, status=status)


def receipt(rows=None, at="2026-09-02T01:00:00Z"):
    return dict(schema=1, kind="kevin-autonomy-continuation-public", version="1.8.8",
                safe_for_public_repo=True, generated_at=at, history=[row()] if rows is None else rows)


def source(doc, commit="a" * 40):
    text = doc if isinstance(doc, str) else json.dumps(doc)
    return dict(commit=commit, text=text, sha256=hashlib.sha256(text.encode()).hexdigest().upper())


class RecoveryTests(unittest.TestCase):
    def test_exact_published_receipt_bytes_and_recovery(self):
        fixtures = json.loads((ROOT / "tests/fixtures/history-public-receipts.json").read_text())
        inputs = []
        for fixture in fixtures:
            raw = fixture["text"].encode()
            blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
            self.assertEqual(fixture["blob"], blob)
            inputs.append(source(fixture["text"], fixture["commit"]))
        result = M.reconcile(inputs)
        items = {x["id"]: x for x in result["items"]}
        staging = items["staging-trajectory-reliability-v1"]
        self.assertEqual([1, 3], sorted(e["observed_turns_lower_bound"] for e in staging["epochs"]))
        self.assertEqual(4, staging["observed_attempts_lower_bound"])
        self.assertEqual(3, items["hq-direct-chat-real-roundtrip"]["observed_attempts_lower_bound"])
        self.assertFalse(result["history_complete"])
        self.assertFalse(result["reopen_authorized"])
        self.assertTrue(all(x["remaining_budget"] is None for x in result["items"]))

    def test_duplicate_source_does_not_increment(self):
        s = source(receipt())
        self.assertEqual(M.reconcile([s]), M.reconcile([s, s]))

    def test_repeated_snapshot_does_not_increment(self):
        result = M.reconcile([source(receipt()), source(receipt(at="2026-09-02T02:00:00Z"), "b" * 40)])
        self.assertEqual(3, result["items"][0]["observed_attempts_lower_bound"])

    def test_source_order_deterministic(self):
        inputs = [source(receipt()), source(receipt([row(fp=B, turns=1, last="2026-09-01T02:00:00Z")]), "b" * 40)]
        self.assertEqual(M.reconcile(inputs), M.reconcile(inputs[::-1]))

    def test_a_b_a_regression_preserves_max_and_flags_gap(self):
        inputs = [source(receipt(at="2026-09-01T01:01:00Z")),
                  source(receipt([row(fp=B, turns=1, last="2026-09-01T02:00:00Z")], "2026-09-01T02:01:00Z"), "b" * 40),
                  source(receipt([row(turns=1, last="2026-09-01T03:00:00Z")], "2026-09-01T03:01:00Z"), "c" * 40)]
        result = M.reconcile(inputs)
        self.assertEqual(2, len(result["items"][0]["epochs"]))
        self.assertEqual(3, result["items"][0]["epochs"][0]["observed_turns_lower_bound"])
        self.assertIn("COUNTER_OR_TIME_REGRESSION", [x["code"] for x in result["issues"]])
        self.assertFalse(result["reopen_authorized"])

    def test_same_reservation_two_fingerprints_not_double_counted(self):
        result = M.reconcile([source(receipt()), source(receipt([row(fp=B)]), "b" * 40)])
        self.assertEqual(3, result["items"][0]["observed_attempts_lower_bound"])
        self.assertEqual(6, result["items"][0]["epoch_counter_sum_not_exact_total"])

    def test_same_counter_changed_time_is_ambiguous(self):
        result = M.reconcile([source(receipt()), source(receipt([row(last="2026-09-01T02:00:00Z")], "2026-09-02T02:00:00Z"), "b" * 40)])
        self.assertIn("SAME_COUNTER_DIFFERENT_ATTEMPT_TIME", [x["code"] for x in result["issues"]])

    def test_no_family_guessing_or_authority_from_mapping(self):
        missing = M.reconcile([source(receipt())])
        self.assertIsNone(missing["items"][0]["family"])
        self.assertEqual({}, missing["family_counter_sums_advisory_not_exact"])
        mapped = M.reconcile([source(receipt())], {"fixture-work-a": "fixture-family"})
        self.assertEqual({"fixture-family": 3}, mapped["family_counter_sums_advisory_not_exact"])
        self.assertFalse(mapped["reopen_authorized"])

    def test_family_aliases_aggregate_only_advisory(self):
        result = M.reconcile([source(receipt([row(), row(item="fixture-work-b", turns=1)]))],
                             {"fixture-work-a": "fixture-family", "fixture-work-b": "fixture-family"})
        self.assertEqual(4, result["family_counter_sums_advisory_not_exact"]["fixture-family"])
        self.assertEqual("REQUIRES_VALIDATED_MIGRATION", result["status"])

    def test_malformed_inputs_fail_closed(self):
        bad = [[], [source("{broken")], [source("[]")], [source(receipt([]))],
               [source('{"schema":1,"schema":2}')]]
        for inputs in bad:
            with self.subTest(inputs=inputs), self.assertRaises(M.EvidenceError):
                M.reconcile(inputs)

    def test_missing_null_or_error_history_fails_closed(self):
        for shape in ("absent", None, []):
            doc = receipt()
            if shape == "absent":
                del doc["history"]
            else:
                doc["history"] = shape
            with self.assertRaises(M.EvidenceError):
                M.reconcile([source(doc)])
        doc = receipt(); doc["history_error"] = True
        with self.assertRaises(M.EvidenceError):
            M.reconcile([source(doc)])

    def test_count_types_and_bounds(self):
        for n in (True, False, 0, -1, 4, 1.5, "3", None):
            with self.subTest(n=n), self.assertRaises(M.EvidenceError):
                M.reconcile([source(receipt([row(turns=n)]))])

    def test_bad_times_and_future_attempts(self):
        for t in (None, "not-time", "2026-09-01T01:00:00", "2026-09-03T00:00:00Z"):
            with self.subTest(t=t), self.assertRaises(M.EvidenceError):
                M.reconcile([source(receipt([row(last=t)]))])

    def test_duplicate_items_rejected(self):
        with self.assertRaises(M.EvidenceError):
            M.reconcile([source(receipt([row(), row(fp=B)]))])

    def test_source_integrity_and_conflict(self):
        wrong = source(receipt()); wrong["sha256"] = "0" * 64
        with self.assertRaises(M.EvidenceError):
            M.reconcile([wrong])
        with self.assertRaises(M.EvidenceError):
            M.reconcile([source(receipt()), source(receipt([row(turns=2)]))])

    def test_bad_identity_and_lineage(self):
        for field, value in (("id", "../../private"), ("fingerprint", "not-a-sha"), ("status", "DONE")):
            r = row(); r[field] = value
            with self.assertRaises(M.EvidenceError):
                M.reconcile([source(receipt([r]))])
        for field, value in (("version", "future"), ("schema", True), ("safe_for_public_repo", False)):
            doc = receipt(); doc[field] = value
            with self.assertRaises(M.EvidenceError):
                M.reconcile([source(doc)])

    def test_prose_and_unknown_fields_cannot_authorize_or_leak(self):
        doc = receipt(); doc["private_body"] = "DO_NOT_COPY_SENTINEL"
        doc["material_new_evidence"] = True; doc["history"][0]["next_action"] = "RETRY_NOW_SENTINEL"
        result = M.reconcile([source(doc)])
        self.assertNotIn("SENTINEL", json.dumps(result))
        self.assertFalse(result["reopen_authorized"])

    def test_input_immutable_and_inprogress_not_success(self):
        inputs = [source(receipt())]; before = copy.deepcopy(inputs)
        result = M.reconcile(inputs)
        self.assertEqual(before, inputs)
        self.assertIn("IN_PROGRESS", result["items"][0]["epochs"][0]["statuses_observed"])
        self.assertNotIn("outcome_proven", result)


if __name__ == "__main__":
    unittest.main()
