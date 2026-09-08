import copy
import unittest
from datetime import datetime, timezone

from public_telemetry_contract_v1 import validate


def base_payload():
    return {
        "schema": 1,
        "kind": "kevin-os-awareness-hq-summary",
        "authority": "GREEN",
        "read_only": True,
        "source": {
            "kind": "kevin-os-awareness-public-summary",
            "generated_at": "2026-08-31T05:20:00+00:00",
            "operation": "snapshot",
        },
        "provenance": {
            "observer_sha256": "A" * 64,
            "source_artifact": "reports/os-awareness/latest-public.json",
            "proof_level": "OMEN-PROVEN",
        },
        "freshness": {
            "checked_at": "2026-08-31T05:21:00+00:00",
            "max_age_seconds": 300,
            "age_seconds": 60,
            "state": "FRESH",
        },
        "counts": {
            "processes": 150,
            "services": 295,
            "scheduled_tasks": 307,
            "installed_software": 90,
            "system_critical_or_error_24h": 3,
            "application_critical_or_error_24h": 2,
        },
        "hardware_summary": {
            "total_physical_memory_bytes": 34270429184,
            "cpu_count": 1,
            "gpu_count": 1,
            "memory_module_count": 2,
        },
        "privacy": "aggregate-only; no host-private identifiers, addresses, command lines, credentials, environment, event messages, or arbitrary file contents",
    }


class ContractTests(unittest.TestCase):
    def test_valid_fresh_payload(self):
        self.assertEqual(validate(base_payload())["freshness"]["state"], "FRESH")

    def test_valid_stale_payload_must_say_stale(self):
        p = base_payload()
        p["freshness"].update({
            "checked_at": "2026-08-31T05:30:01+00:00",
            "age_seconds": 601,
            "state": "STALE",
        })
        self.assertEqual(validate(p)["freshness"]["state"], "STALE")

    def test_stale_payload_cannot_claim_fresh(self):
        p = base_payload()
        p["freshness"].update({
            "checked_at": "2026-08-31T05:30:01+00:00",
            "age_seconds": 601,
            "state": "FRESH",
        })
        with self.assertRaises(ValueError):
            validate(p)

    def test_age_must_match_timestamps(self):
        p = base_payload()
        p["freshness"]["age_seconds"] = 1
        with self.assertRaises(ValueError):
            validate(p)

    def test_unknown_top_level_field_rejected(self):
        p = base_payload()
        p["hostname"] = "private-host"
        with self.assertRaises(ValueError):
            validate(p)

    def test_nested_sensitive_field_rejected(self):
        p = base_payload()
        p["counts"]["ip_address"] = "192.0.2.1"
        with self.assertRaises(ValueError):
            validate(p)

    def test_process_list_rejected(self):
        p = base_payload()
        p["counts"]["process_list"] = ["powershell"]
        with self.assertRaises(ValueError):
            validate(p)

    def test_wrong_source_path_rejected(self):
        p = base_payload()
        p["provenance"]["source_artifact"] = "reports/os-awareness/latest-local.json"
        with self.assertRaises(ValueError):
            validate(p)

    def test_bad_hash_rejected(self):
        p = base_payload()
        p["provenance"]["observer_sha256"] = "not-a-hash"
        with self.assertRaises(ValueError):
            validate(p)

    def test_naive_timestamp_rejected(self):
        p = base_payload()
        p["source"]["generated_at"] = "2026-08-31T05:20:00"
        with self.assertRaises(ValueError):
            validate(p)

    def test_non_green_rejected(self):
        p = base_payload()
        p["authority"] = "YELLOW"
        with self.assertRaises(ValueError):
            validate(p)

    def test_operation_must_be_snapshot(self):
        p = base_payload()
        p["source"]["operation"] = "processes"
        with self.assertRaises(ValueError):
            validate(p)

    def test_max_age_is_bounded(self):
        p = base_payload()
        p["freshness"]["max_age_seconds"] = 3600
        with self.assertRaises(ValueError):
            validate(p)

    def test_negative_count_rejected(self):
        p = base_payload()
        p["counts"]["services"] = -1
        with self.assertRaises(ValueError):
            validate(p)


if __name__ == "__main__":
    unittest.main()
