#!/usr/bin/env python3
"""Kevin Continuous Growth v1: deterministic admission guard for autonomous growth work.

This module grants no primitive authority. It only decides whether a proposed growth
item is structurally admissible for GREEN autonomous planning, must be owner-reviewed,
or must be rejected.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

VERDICTS = {"ALLOW_GREEN", "OWNER_REVIEW", "DENY"}


def load_json(path: str) -> Dict[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected JSON object")
    return value


def _strings(value: Any) -> List[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        return [str(value)]
    return [str(x) for x in value]


def _nonempty_list(candidate: Dict[str, Any], key: str) -> bool:
    value = candidate.get(key)
    return isinstance(value, list) and any(str(x).strip() for x in value)


def _target_protected(target: str, policy: Dict[str, Any]) -> bool:
    clean = target.replace("\\", "/").lstrip("./").lower()
    for prefix in _strings(policy.get("protected_target_prefixes")):
        p = prefix.replace("\\", "/").lstrip("./").lower()
        if clean == p or clean.startswith(p.rstrip("/") + "/"):
            return True
    return any(fragment.lower() in clean for fragment in _strings(policy.get("protected_target_contains")))


def assess(candidate: Dict[str, Any], policy: Dict[str, Any]) -> Dict[str, Any]:
    reasons: List[str] = []
    review: List[str] = []

    allowed_programs = set(_strings(policy.get("programs")))
    program = str(candidate.get("program", ""))
    if program not in allowed_programs:
        reasons.append("PROGRAM_NOT_CONTINUOUS_GROWTH")

    for field in _strings(policy.get("required_candidate_fields")):
        if field not in candidate or candidate.get(field) in (None, "", []):
            reasons.append("MISSING_REQUIRED_FIELD:" + field)

    if str(candidate.get("authority_class", "")).upper() != "GREEN":
        review.append("AUTHORITY_NOT_GREEN")

    protected = set(_strings(policy.get("protected_effects")))
    hit = sorted(protected & set(_strings(candidate.get("effects"))))
    if hit:
        review.append("PROTECTED_EFFECT:" + ",".join(hit))

    targets = _strings(candidate.get("targets"))
    protected_targets = sorted(t for t in targets if _target_protected(t, policy))
    if protected_targets:
        review.append("PROTECTED_GOVERNANCE_TARGET:" + ",".join(protected_targets))

    if not _nonempty_list(candidate, "acceptance_criteria"):
        reasons.append("ACCEPTANCE_CRITERIA_REQUIRED")
    if not _nonempty_list(candidate, "verification_plan"):
        reasons.append("VERIFICATION_PLAN_REQUIRED")

    mutates = bool(candidate.get("mutates_code_or_config"))
    if mutates:
        for field in _strings(policy.get("mutable_change_requirements")):
            if not _nonempty_list(candidate, field):
                reasons.append("MUTABLE_CHANGE_REQUIRES:" + field)

    retry = candidate.get("retry_policy") or {}
    policy_retry = policy.get("retry_policy") or {}
    max_allowed = int(policy_retry.get("max_attempts_without_material_new_evidence", 3))
    min_cooldown = int(policy_retry.get("minimum_cooldown_seconds_after_exhaustion", 300))
    attempts = int(retry.get("max_attempts_without_material_new_evidence", max_allowed))
    cooldown = int(retry.get("cooldown_seconds_after_exhaustion", min_cooldown))
    if attempts < 0 or attempts > max_allowed:
        reasons.append("RETRY_BUDGET_EXCEEDS_POLICY")
    if cooldown < min_cooldown:
        reasons.append("COOLDOWN_BELOW_POLICY")

    if candidate.get("success_by_self_narration") is True:
        reasons.append("SELF_NARRATED_SUCCESS_FORBIDDEN")
    if candidate.get("automatic_production_promotion") is True:
        review.append("AUTOMATIC_PRODUCTION_PROMOTION_FORBIDDEN")

    if reasons:
        verdict = "DENY"
    elif review:
        verdict = "OWNER_REVIEW"
    else:
        verdict = "ALLOW_GREEN"

    assert verdict in VERDICTS
    return {
        "schema": 1,
        "kind": "kevin-continuous-growth-admission",
        "policy_version": str(policy.get("version", "unknown")),
        "candidate_id": candidate.get("id"),
        "verdict": verdict,
        "deny_reasons": reasons,
        "review_reasons": review,
        "authority_effect": "NONE_VALIDATOR_ONLY",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--policy", required=True)
    ap.add_argument("--candidate", required=True)
    ap.add_argument("--output")
    args = ap.parse_args()
    result = assess(load_json(args.candidate), load_json(args.policy))
    text = json.dumps(result, indent=2) + "\n"
    if args.output:
        path = Path(args.output)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0 if result["verdict"] == "ALLOW_GREEN" else 2


if __name__ == "__main__":
    raise SystemExit(main())
