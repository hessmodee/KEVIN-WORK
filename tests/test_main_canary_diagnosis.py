"""Regression tests for the real Sep 2 error-classification incident."""

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "control-plane/diagnostics/main_canary_diagnosis.py"
spec = importlib.util.spec_from_file_location("main_canary_diagnosis", MODULE)
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)


def receipt():
    return {
        "schema": 1, "kind": "kevin-main-agent-canary-public",
        "agent": "fixed:main", "safe_for_public_repo": True,
        "generated_at": "2026-09-02T09:00:25.1588181-06:00",
        "state": "REJECT", "failure_stage": "semantic_contract",
        "exact_expected_reply": False, "tool_calls": None,
        "output_sha256": diag.OVERFLOW_SHA256,
        "canary_shape": {
            "final_length": 127, "final_exact_case_sensitive": False,
            "final_contains_expected": False,
            "transcript": {"present": True, "complete": False,
                           "user_messages": 0, "assistant_messages": 1,
                           "tool_calls": 0, "final_exact": False},
        },
    }


def envelope(entries=diag.MISSING, error=diag.MISSING, calls=diag.MISSING):
    meta = {}
    if entries is not diag.MISSING:
        meta["systemPromptReport"] = {"tools": {"entries": entries}}
    if error is not diag.MISSING:
        meta["error"] = error
    if calls is not diag.MISSING:
        meta["toolSummary"] = {"calls": calls}
    return {"status": "ok", "result": {"meta": meta}}


class ReceiptDiagnosis(unittest.TestCase):
    def test_public_upstream_banner_independently_matches_observed_fingerprint(self):
        text = ("Context overflow: prompt too large for the model. "
                "Try /reset (or /new) to start a fresh session, or use a larger-context model.")
        self.assertEqual(hashlib.sha256(text.encode()).hexdigest().upper(), diag.OVERFLOW_SHA256)
        self.assertEqual(len(text), diag.OVERFLOW_CHARACTERS)

    def test_real_incident_is_runtime_error_signature_not_disobedience(self):
        result = diag.diagnose_public_receipt(receipt())
        self.assertEqual(result["diagnosis"], "RUNTIME_CONTEXT_OVERFLOW_SIGNATURE_MATCH")
        self.assertEqual(result["source_generated_at"], receipt()["generated_at"])
        self.assertTrue(result["signature_match"])
        self.assertFalse(result["root_cause_determined"])
        self.assertFalse(result["retry_authorized"])
        self.assertIsNone(result["tool_calls"])
        self.assertEqual(result["tool_inventory_state"], "UNKNOWN")

    def test_same_length_alone_never_classifies_overflow(self):
        data = receipt()
        data["output_sha256"] = hashlib.sha256(("x" * 127).encode()).hexdigest()
        result = diag.diagnose_public_receipt(data)
        self.assertFalse(result["signature_match"])
        self.assertEqual(result["diagnosis"], "UNCLASSIFIED_RECEIPT")

    def test_matching_fingerprint_with_wrong_length_is_contradiction(self):
        data = receipt()
        data["canary_shape"]["final_length"] = 126
        self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "CONTRADICTORY_RECEIPT")

    def test_positive_canary_label_cannot_override_overflow_fingerprint(self):
        for field, value in [("state", "OMEN_PROVEN"), ("exact_expected_reply", True)]:
            with self.subTest(field=field):
                data = receipt()
                data[field] = value
                self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "CONTRADICTORY_RECEIPT")

    def test_exact_shape_or_transcript_cannot_override_overflow_fingerprint(self):
        for target in ("final_exact_case_sensitive", "final_contains_expected", "transcript"):
            data = receipt()
            if target == "transcript":
                data["canary_shape"]["transcript"]["final_exact"] = True
            else:
                data["canary_shape"][target] = True
            self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "CONTRADICTORY_RECEIPT")

    def test_partial_transcript_zero_stays_unknown(self):
        data = receipt()
        data["tool_calls"] = 0
        result = diag.diagnose_public_receipt(data)
        self.assertIsNone(result["tool_calls"])
        self.assertEqual(result["transcript_state"], "INCOMPLETE_REPORTED")

    def test_complete_transcript_without_user_is_rejected(self):
        data = receipt()
        data["canary_shape"]["transcript"]["complete"] = True
        data["tool_calls"] = 0
        self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "CONTRADICTORY_RECEIPT")

    def test_reported_complete_turn_preserves_nonzero_calls_without_promoting(self):
        data = receipt()
        data["output_sha256"] = "A" * 64
        data["tool_calls"] = 2
        data["canary_shape"]["transcript"].update(complete=True, user_messages=1, tool_calls=2)
        result = diag.diagnose_public_receipt(data)
        self.assertEqual(result["tool_calls"], 2)
        self.assertEqual(result["transcript_state"], "COMPLETE_REPORTED")
        self.assertFalse(result["acceptance_changed"])

    def test_wrong_kind_or_agent_or_schema_is_rejected(self):
        for key, value in [("kind", "kevin-reader-canary-public"), ("agent", "someone"),
                           ("schema", True), ("safe_for_public_repo", "true")]:
            data = receipt()
            data[key] = value
            self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "INVALID_RECEIPT")

    def test_malformed_hash_and_timestamp_and_lengths_are_rejected(self):
        for key, value in [("output_sha256", "private-value"), ("generated_at", "private-value"),
                           ("generated_at", "2026-09-02T09:00:25"), ("output_sha256", [])]:
            data = receipt()
            data[key] = value
            self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "INVALID_RECEIPT")
        for length in (True, -1, "127", 1000001):
            data = receipt()
            data["canary_shape"]["final_length"] = length
            self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "INVALID_RECEIPT")

    def test_arbitrary_failure_stage_is_never_echoed_or_used_as_code(self):
        data = receipt()
        data["failure_stage"] = {"private-value": "do not publish"}
        result = diag.diagnose_public_receipt(data)
        self.assertEqual(result["source_failure_stage"], "UNKNOWN")
        self.assertNotIn("private-value", json.dumps(result))

    def test_truthy_string_does_not_become_false_semantic_evidence(self):
        data = receipt()
        data["canary_shape"]["final_exact_case_sensitive"] = "false"
        self.assertEqual(diag.diagnose_public_receipt(data)["diagnosis"], "INVALID_RECEIPT")

    def test_diagnosis_preserves_original_receipt(self):
        data = receipt()
        before = copy.deepcopy(data)
        diag.diagnose_public_receipt(data)
        self.assertEqual(data, before)

    def test_valid_pre_final_failures_are_unclassified_not_malformed(self):
        for stage in ("gateway_probe", "agent_cli", "agent_json_parse"):
            data = receipt()
            del data["canary_shape"]
            data["failure_stage"] = stage
            data["output_sha256"] = ""
            result = diag.diagnose_public_receipt(data)
            self.assertEqual(result["diagnosis"], "NO_FINAL_SIGNATURE_AVAILABLE")
            self.assertFalse(result["signature_match"])
            self.assertIsNone(result["tool_calls"])


class EnvelopeDiagnosis(unittest.TestCase):
    def test_wrapper_status_ok_does_not_hide_structured_runtime_error(self):
        result = diag.classify_runtime_envelope(envelope(error={"kind": "context_overflow", "message": "PRIVATE"}))
        self.assertEqual(result["runtime_error_state"], "ERROR_REPORTED")
        self.assertEqual(result["runtime_error_kind"], "context_overflow")
        self.assertNotIn("PRIVATE", json.dumps(result))

    def test_top_level_and_nested_envelopes_have_same_meaning(self):
        data = envelope(entries=[{"name": "kevin_system_status"}], error={"kind": "compaction_failure"}, calls=1)
        nested = diag.classify_runtime_envelope(data)
        direct = diag.classify_runtime_envelope(data["result"])
        for key in ("runtime_error_kind", "inventory_state", "visible_tool_count", "reported_tool_calls"):
            self.assertEqual(nested[key], direct[key])

    def test_unknown_kind_is_not_leaked(self):
        result = diag.classify_runtime_envelope(envelope(error={"kind": "PRIVATE_TOKEN", "message": "PRIVATE_BODY"}))
        self.assertEqual(result["runtime_error_kind"], "OTHER_REPORTED_ERROR")
        self.assertNotIn("PRIVATE", json.dumps(result))

    def test_mentioning_overflow_in_prose_is_not_an_error(self):
        result = diag.classify_runtime_envelope({"final": "We discussed context overflow.", "status": "ok"})
        self.assertEqual(result["runtime_error_state"], "UNKNOWN")

    def test_payload_error_is_reported_without_text(self):
        result = diag.classify_runtime_envelope({"payloads": [{"text": "PRIVATE", "isError": True}]})
        self.assertEqual(result["runtime_error_kind"], "UNCLASSIFIED")
        self.assertNotIn("PRIVATE", json.dumps(result))

    def test_conflicting_known_or_unknown_errors_are_invalid(self):
        for first, second in [("context_overflow", "compaction_failure"), ("PRIVATE_A", "PRIVATE_B")]:
            data = envelope(error={"kind": first})
            data["meta"] = {"error": {"kind": second}}
            self.assertEqual(diag.classify_runtime_envelope(data)["runtime_error_state"], "INVALID")

    def test_null_error_with_true_payload_is_invalid_even_when_duplicated(self):
        data = envelope(error=None)
        data["meta"] = {"error": None}
        data["payloads"] = [{"isError": True}]
        self.assertEqual(diag.classify_runtime_envelope(data)["runtime_error_state"], "INVALID")

    def test_missing_null_and_empty_tool_inventory_are_distinct(self):
        for value in (diag.MISSING, None):
            result = diag.classify_runtime_envelope(envelope(entries=value))
            self.assertEqual(result["inventory_state"], "UNKNOWN")
            self.assertIsNone(result["visible_tool_count"])
        result = diag.classify_runtime_envelope(envelope(entries=[]))
        self.assertEqual(result["inventory_state"], "REPORTED_EMPTY")
        self.assertEqual(result["visible_tool_count"], 0)
        self.assertIsNone(result["reported_tool_calls"])
        self.assertFalse(result["actual_tool_use_proven"])

    def test_malformed_duplicate_or_unbounded_inventory_is_invalid(self):
        for value in ({}, "read", [None], [{"description": "PRIVATE"}], ["read", "read"],
                      ["../PRIVATE"], ["read"] * 257):
            result = diag.classify_runtime_envelope(envelope(entries=value))
            self.assertEqual(result["inventory_state"], "INVALID")
            self.assertIsNone(result["visible_tool_count"])
            self.assertNotIn("PRIVATE", json.dumps(result))

    def test_valid_inventory_publishes_counts_and_digest_only(self):
        data = envelope(entries=[{"name": "privateToolName"}, {"name": "kevin_system_status"}])
        result = diag.classify_runtime_envelope(data)
        self.assertEqual(result["visible_tool_count"], 2)
        self.assertTrue(result["has_kevin_system_status"])
        self.assertNotIn("privateToolName", json.dumps(result))
        self.assertIsNone(result["reported_tool_calls"])

    def test_conflicting_inventories_do_not_silently_choose_one(self):
        data = envelope(entries=[])
        data["meta"] = {"systemPromptReport": {"tools": {"entries": ["read"]}}}
        self.assertEqual(diag.classify_runtime_envelope(data)["inventory_state"], "INVALID")

    def test_reported_zero_is_never_correlated_tool_use_proof(self):
        result = diag.classify_runtime_envelope(envelope(calls=0))
        self.assertEqual(result["reported_tool_calls"], 0)
        self.assertFalse(result["actual_tool_use_proven"])
        self.assertEqual(result["tool_call_evidence_state"], "REPORTED_ONLY")

    def test_invalid_and_conflicting_tool_counts_are_rejected(self):
        for value in (True, -1, 0.0, "0", 10001, []):
            self.assertEqual(diag.classify_runtime_envelope(envelope(calls=value))["tool_call_evidence_state"], "INVALID")
        data = envelope(calls=0)
        data["meta"] = {"toolSummary": {"calls": 1}}
        self.assertEqual(diag.classify_runtime_envelope(data)["tool_call_evidence_state"], "INVALID")

    def test_malformed_error_flags_and_metadata_are_rejected(self):
        for value in ("false", 1, None):
            result = diag.classify_runtime_envelope({"payloads": [{"isError": value}]})
            self.assertEqual(result["runtime_error_state"], "INVALID")
        result = diag.classify_runtime_envelope({"meta": "PRIVATE"})
        self.assertEqual(result["runtime_error_state"], "INVALID")
        self.assertNotIn("PRIVATE", json.dumps(result))

    def test_envelope_classification_never_mutates_or_authorizes(self):
        data = envelope(entries=[], error=None, calls=0)
        before = copy.deepcopy(data)
        result = diag.classify_runtime_envelope(data)
        self.assertEqual(data, before)
        self.assertEqual(result["authority_effect"], "NONE")
        self.assertFalse(result["retry_authorized"])
        self.assertFalse(result["tool_policy_change_authorized"])


class CliBoundary(unittest.TestCase):
    def test_no_arbitrary_file_or_other_caller_argument(self):
        run = subprocess.run([sys.executable, str(MODULE), "--receipt", "PRIVATE_PATH"],
                             capture_output=True, text=True, timeout=5)
        self.assertEqual(run.returncode, 2)
        self.assertNotIn("PRIVATE_PATH", run.stdout + run.stderr)
        self.assertEqual(json.loads(run.stdout)["error"], "NO_CALLER_ARGUMENTS_ALLOWED")

    def test_duplicate_json_fields_are_rejected(self):
        with self.assertRaises(ValueError):
            json.loads('{"state":"REJECT","state":"OMEN_PROVEN"}', object_pairs_hook=diag._unique_object)

    def test_nonfinite_json_is_rejected(self):
        with self.assertRaises(ValueError):
            json.loads('{"tool_calls":NaN}', parse_constant=diag._reject_nonfinite)


if __name__ == "__main__":
    unittest.main()
