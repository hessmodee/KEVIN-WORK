#!/usr/bin/env python3
"""Pure policy model for Kevin self-maintenance transport.

No filesystem, network, process, scheduler, shell, or host mutation occurs here.
The model defines the narrow authority envelope for the next local reconciler:
fixed aliases, fixed repository source roots, pinned before/after hashes, and a
single fixed remote work-order verb that can only wake the local reconciler.
"""
from __future__ import annotations

import re

HEX64 = re.compile(r"^[A-Fa-f0-9]{64}$")
ID = re.compile(r"^[A-Za-z0-9._-]{6,96}$")

ALIASES = {
    "maintenance_runner": {
        "local": "workspace/kevin-maintenance-runner.ps1",
        "source": re.compile(r"^control-plane/maintenance/kevin-maintenance-runner-v[0-9._-]+\.ps1$"),
        "self_test": "MAINTENANCE_SELFTEST",
    },
    "work_order_intake": {
        "local": "workspace/ControlPlane/kevin-work-order-intake-v0.1.ps1",
        "source": re.compile(r"^control-plane/intake/kevin-work-order-intake-v[0-9._-]+\.ps1$"),
        "self_test": "WORK_ORDER_INTAKE_SELFTEST",
    },
    "skill_lab_runner": {
        "local": "workspace/kevin-skill-lab.ps1",
        "source": re.compile(r"^control-plane/skill-lab/kevin-skill-lab-v[0-9._-]+\.ps1$"),
        "self_test": "SKILL_LAB_SELFTEST",
    },
}

REMOTE_VERB = "run_typed_maintenance"
REMOTE_TARGET = "kevin-maintenance-v1"


def validate_manifest(m: dict) -> list[str]:
    e: list[str] = []
    allowed = {
        "schema", "kind", "id", "authority_class", "authority_delta",
        "production_effect", "owner_policy", "preauthorized", "operation",
        "target_alias", "source_path", "source_sha256",
        "expected_current_sha256", "expected_after_sha256", "expires_at",
    }
    if not isinstance(m, dict):
        return ["manifest must be object"]
    if set(m) - allowed:
        e.append("unknown manifest field")
    if m.get("schema") != 3:
        e.append("schema must be 3")
    if m.get("kind") != "kevin-self-maintenance-manifest":
        e.append("kind mismatch")
    if not isinstance(m.get("id"), str) or not ID.fullmatch(m["id"]):
        e.append("id invalid")
    if m.get("authority_class") != "GREEN":
        e.append("authority must be GREEN")
    if m.get("authority_delta") != "NONE":
        e.append("authority_delta must be NONE")
    if m.get("production_effect") != "NONE":
        e.append("production_effect must be NONE")
    if m.get("owner_policy") != "Kevin Owner Authorization v1":
        e.append("owner policy mismatch")
    if m.get("preauthorized") is not True:
        e.append("preauthorized must be true")
    if m.get("operation") != "replace_pinned_component":
        e.append("operation not allowlisted")

    alias = m.get("target_alias")
    spec = ALIASES.get(alias)
    if spec is None:
        e.append("target alias not allowlisted")
    else:
        src = m.get("source_path")
        if not isinstance(src, str) or not spec["source"].fullmatch(src):
            e.append("source path outside alias root")

    for k in ("source_sha256", "expected_current_sha256", "expected_after_sha256"):
        if not isinstance(m.get(k), str) or not HEX64.fullmatch(m[k]):
            e.append(f"{k} invalid")
    if isinstance(m.get("source_sha256"), str) and isinstance(m.get("expected_after_sha256"), str):
        if m["source_sha256"].upper() != m["expected_after_sha256"].upper():
            e.append("source hash must equal after hash")
    return e


def validate_remote_order(o: dict) -> list[str]:
    """Remote transport may wake the reconciler, never supply its execution data."""
    e: list[str] = []
    allowed = {
        "schema", "kind", "id", "idempotency_key", "created_at", "expires_at",
        "authority_class", "verb", "target", "reason",
    }
    if not isinstance(o, dict):
        return ["order must be object"]
    if set(o) - allowed:
        e.append("unknown work-order property")
    if o.get("schema") != 1 or o.get("kind") != "kevin-work-order":
        e.append("work-order contract mismatch")
    if o.get("authority_class") != "GREEN":
        e.append("authority must be GREEN")
    if o.get("verb") != REMOTE_VERB:
        e.append("verb not allowlisted")
    if o.get("target") != REMOTE_TARGET:
        e.append("target mismatch")
    return e


def resolve_alias(alias: str) -> str:
    if alias not in ALIASES:
        raise ValueError("target alias not allowlisted")
    return ALIASES[alias]["local"]
