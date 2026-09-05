"""Candidate-only validator for sanitized OS Awareness telemetry consumed by Support/HQ.

No process, shell, network, file mutation, credential access, or production authority.
"""
from __future__ import annotations

from datetime import datetime, timezone
import re
from typing import Any, Dict

HEX64 = re.compile(r"^[0-9A-Fa-f]{64}$")

TOP_KEYS = {
    "schema", "kind", "authority", "read_only", "source", "provenance",
    "freshness", "counts", "hardware_summary", "privacy"
}
SOURCE_KEYS = {"kind", "generated_at", "operation"}
PROVENANCE_KEYS = {"observer_sha256", "source_artifact", "proof_level"}
FRESHNESS_KEYS = {"checked_at", "max_age_seconds", "age_seconds", "state"}
COUNT_KEYS = {
    "processes", "services", "scheduled_tasks", "installed_software",
    "system_critical_or_error_24h", "application_critical_or_error_24h"
}
HARDWARE_KEYS = {
    "total_physical_memory_bytes", "cpu_count", "gpu_count", "memory_module_count"
}

FORBIDDEN_KEYS = {
    "hostname", "computer_name", "user", "username", "profile", "home",
    "path", "file_path", "command", "command_line", "argv", "environment",
    "env", "credential", "credentials", "secret", "secrets", "token",
    "password", "ip", "ip_address", "mac", "mac_address", "serial",
    "serial_number", "event_message", "event_messages", "registry_value",
    "document", "documents", "process_list", "service_list", "task_list",
    "software_list", "network_adapters", "network_profiles"
}


def _parse_time(value: Any) -> datetime:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("timestamp must be non-empty string")
    text = value.strip().replace("Z", "+00:00")
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        raise ValueError("timestamp must be timezone-aware")
    return dt.astimezone(timezone.utc)


def _exact_keys(obj: Any, expected: set[str], label: str) -> Dict[str, Any]:
    if not isinstance(obj, dict):
        raise ValueError(f"{label} must be object")
    keys = set(obj)
    if keys != expected:
        raise ValueError(f"{label} keys mismatch: {sorted(keys ^ expected)}")
    return obj


def _scan_forbidden(value: Any) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if str(key).lower() in FORBIDDEN_KEYS:
                raise ValueError(f"forbidden public telemetry field: {key}")
            _scan_forbidden(child)
    elif isinstance(value, list):
        for child in value:
            _scan_forbidden(child)


def validate(payload: Dict[str, Any]) -> Dict[str, Any]:
    p = _exact_keys(payload, TOP_KEYS, "payload")
    _scan_forbidden(p)

    if p["schema"] != 1 or p["kind"] != "kevin-os-awareness-hq-summary":
        raise ValueError("schema/kind mismatch")
    if p["authority"] != "GREEN" or p["read_only"] is not True:
        raise ValueError("telemetry must remain GREEN and read-only")

    source = _exact_keys(p["source"], SOURCE_KEYS, "source")
    if source["kind"] != "kevin-os-awareness-public-summary":
        raise ValueError("unexpected source kind")
    if source["operation"] != "snapshot":
        raise ValueError("HQ integration requires full bounded snapshot source")
    generated = _parse_time(source["generated_at"])

    provenance = _exact_keys(p["provenance"], PROVENANCE_KEYS, "provenance")
    if not isinstance(provenance["observer_sha256"], str) or not HEX64.fullmatch(provenance["observer_sha256"]):
        raise ValueError("observer_sha256 must be exact SHA-256")
    if provenance["source_artifact"] != "reports/os-awareness/latest-public.json":
        raise ValueError("source artifact must be fixed public summary path")
    if provenance["proof_level"] not in {"INSTALLED", "OMEN-PROVEN", "SELF-RELIANT"}:
        raise ValueError("unsupported proof level")

    freshness = _exact_keys(p["freshness"], FRESHNESS_KEYS, "freshness")
    checked = _parse_time(freshness["checked_at"])
    max_age = freshness["max_age_seconds"]
    age = freshness["age_seconds"]
    if not isinstance(max_age, int) or not 30 <= max_age <= 900:
        raise ValueError("max_age_seconds must be bounded 30..900")
    if not isinstance(age, (int, float)) or age < 0:
        raise ValueError("age_seconds must be nonnegative")
    computed = max(0.0, (checked - generated).total_seconds())
    if abs(float(age) - computed) > 2.0:
        raise ValueError("age_seconds does not match source/checked timestamps")
    expected_state = "FRESH" if computed <= max_age else "STALE"
    if freshness["state"] != expected_state:
        raise ValueError("freshness state mismatch")

    counts = _exact_keys(p["counts"], COUNT_KEYS, "counts")
    for key, value in counts.items():
        if not isinstance(value, int) or value < 0:
            raise ValueError(f"count {key} must be nonnegative integer")

    hw = _exact_keys(p["hardware_summary"], HARDWARE_KEYS, "hardware_summary")
    for key, value in hw.items():
        if not isinstance(value, int) or value < 0:
            raise ValueError(f"hardware field {key} must be nonnegative integer")

    privacy = p["privacy"]
    if privacy != "aggregate-only; no host-private identifiers, addresses, command lines, credentials, environment, event messages, or arbitrary file contents":
        raise ValueError("privacy declaration mismatch")

    return p
