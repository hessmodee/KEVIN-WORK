"""Read-only v1.8.8 receipt reconciler; no execution, budget or migration authority.

Pure function only: inputs are already-acquired public receipts, output is a
conservative review proposal. No file, network, process, clock or runtime calls.
"""
import hashlib
import json
import re
from datetime import datetime, timezone

IDENTITY = re.compile(r"[a-z0-9][a-z0-9._-]{2,96}\Z")
SHA = re.compile(r"[A-F0-9]{64}\Z")
COMMIT = re.compile(r"[a-f0-9]{40}\Z")
STATUSES = {"IN_PROGRESS", "MIGRATED_LEGACY", "AGENT_TURN_COMPLETED_NOT_OUTCOME_PROOF"}


class EvidenceError(ValueError):
    """Invalid or ambiguous input cannot be interpreted as an empty budget."""


def require(condition, code):
    if not condition:
        raise EvidenceError(code)


def instant(value):
    require(isinstance(value, str), "TIME_TYPE")
    try:
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        raise EvidenceError("TIME_FORMAT") from None
    require(result.tzinfo is not None, "TIME_ZONE_REQUIRED")
    return result.astimezone(timezone.utc)


def unique_object(pairs):
    out = {}
    for key, value in pairs:
        require(key not in out, "DUPLICATE_JSON_KEY")
        out[key] = value
    return out


def reconcile(sources, family_map=None):
    """Return observed lower bounds, NEVER a runnable continuation state.

    sources: bounded list of {commit, text, sha256}. SHA verifies input bytes,
    not publisher trust. Callers must independently establish trusted provenance.
    family_map: optional previously reviewed item->family mapping, advisory only.
    Fingerprints are observation buckets, NOT authorization for a new attempt.
    """
    require(type(sources) is list and 0 < len(sources) <= 512, "SOURCES_REQUIRED_OR_LIMIT")
    if family_map is None:
        family_map = {}
    require(type(family_map) is dict, "FAMILY_MAP_TYPE")
    for key, value in family_map.items():
        require(isinstance(key, str) and IDENTITY.fullmatch(key), "FAMILY_ITEM_ID")
        require(isinstance(value, str) and IDENTITY.fullmatch(value), "FAMILY_ID")
    observed = []
    provenance = {}
    for source in sources:
        require(type(source) is dict and set(source) == {"commit", "text", "sha256"}, "SOURCE_SHAPE")
        commit, text, digest = source["commit"], source["text"], source["sha256"]
        require(isinstance(commit, str) and COMMIT.fullmatch(commit), "COMMIT_ID")
        require(isinstance(text, str) and len(text.encode("utf-8")) <= 1048576, "RECEIPT_SIZE_OR_TYPE")
        require(isinstance(digest, str) and SHA.fullmatch(digest), "DIGEST_FORMAT")
        require(hashlib.sha256(text.encode("utf-8")).hexdigest().upper() == digest, "DIGEST_MISMATCH")
        require(commit not in provenance or provenance[commit] == digest, "SOURCE_CONFLICT")
        if commit in provenance:
            continue
        provenance[commit] = digest
        try:
            receipt = json.loads(text, object_pairs_hook=unique_object)
        except (json.JSONDecodeError, UnicodeError):
            raise EvidenceError("CORRUPT_JSON") from None
        require(type(receipt) is dict, "RECEIPT_SHAPE")
        require(type(receipt.get("schema")) is int and receipt["schema"] == 1, "SCHEMA")
        require(receipt.get("kind") == "kevin-autonomy-continuation-public" and receipt.get("version") == "1.8.8", "RECEIPT_LINEAGE")
        require(receipt.get("safe_for_public_repo") is True, "PUBLIC_RECEIPT_REQUIRED")
        require(receipt.get("history_error", False) is False, "HISTORY_ERROR")
        at = instant(receipt.get("generated_at"))
        rows = receipt.get("history")
        require(type(rows) is list and 0 < len(rows) <= 512, "HISTORY_MISSING_EMPTY_OR_LIMIT")
        seen = set()
        for row in rows:
            require(type(row) is dict, "HISTORY_ROW_TYPE")
            item, fp, turns = row.get("id"), row.get("fingerprint"), row.get("turns")
            require(isinstance(item, str) and IDENTITY.fullmatch(item), "ITEM_ID")
            require(item not in seen, "DUPLICATE_ITEM_IN_SNAPSHOT")
            seen.add(item)
            require(isinstance(fp, str) and SHA.fullmatch(fp), "FINGERPRINT")
            require(type(turns) is int and 1 <= turns <= 3, "TURN_COUNT")
            require(row.get("status") in STATUSES, "HISTORY_STATUS")
            last = instant(row.get("last_turn_at"))
            require(last <= at, "ATTEMPT_AFTER_SNAPSHOT")
            observed.append((at, commit, item, fp, turns, last, row["status"]))
    epochs = {}
    issues = set()
    for at, commit, item, fp, turns, last, status in sorted(observed):
        key = (item, fp)
        if key not in epochs:
            epochs[key] = {"id": item, "fingerprint": fp, "observed_turns_lower_bound": turns,
                           "last_observed_turn_at": last.isoformat(), "source_commits": [],
                           "statuses_observed": [], "observations": []}
        epoch = epochs[key]
        previous = epoch["observations"]
        if previous:
            p = previous[-1]
            if turns < p["turns"] or last < instant(p["last_turn_at"]):
                issues.add((item, "COUNTER_OR_TIME_REGRESSION"))
            if turns == p["turns"] and last != instant(p["last_turn_at"]):
                issues.add((item, "SAME_COUNTER_DIFFERENT_ATTEMPT_TIME"))
        epoch["observed_turns_lower_bound"] = max(epoch["observed_turns_lower_bound"], turns)
        epoch["last_observed_turn_at"] = max(instant(epoch["last_observed_turn_at"]), last).isoformat()
        epoch["source_commits"].append(commit)
        if status not in epoch["statuses_observed"]:
            epoch["statuses_observed"].append(status)
        epoch["observations"].append({"commit": commit, "snapshot_at": at.isoformat(), "turns": turns,
                                       "last_turn_at": last.isoformat(), "status": status})
    items = []
    families = {}
    for item in sorted({key[0] for key in epochs}):
        rows = [epochs[k] for k in sorted(epochs) if k[0] == item]
        # Distinct fingerprints can repeat an existing reservation. Without
        # unique attempt IDs, summing epochs is evidence, NOT an exact total.
        epoch_sum = sum(r["observed_turns_lower_bound"] for r in rows)
        minimum = max(r["observed_turns_lower_bound"] for r in rows)
        latest_times = {r["last_observed_turn_at"] for r in rows}
        if len(latest_times) > 1:
            # At least one later distinct turn exists beyond the largest epoch
            # only when its last turn is later than that epoch's last turn.
            max_epoch_time = max(instant(r["last_observed_turn_at"]) for r in rows if r["observed_turns_lower_bound"] == minimum)
            minimum += sum(instant(t) > max_epoch_time for t in latest_times)
        family = family_map.get(item)
        if family is None:
            issues.add((item, "FAMILY_MAPPING_UNRESOLVED"))
        else:
            families[family] = families.get(family, 0) + minimum
        items.append({"id": item, "family": family, "epochs": rows,
                      "epoch_counter_sum_not_exact_total": epoch_sum,
                      "observed_attempts_lower_bound": minimum,
                      "remaining_budget": None, "reopen_authorized": False})
    return {"schema": 1, "kind": "kevin-history-recovery-review-only",
            "status": "REQUIRES_VALIDATED_MIGRATION", "history_complete": False,
            "authority_effect": "NONE", "runtime_mutation": False, "reopen_authorized": False,
            "items": items, "family_counter_sums_advisory_not_exact": families,
            "issues": [{"id": item, "code": code} for item, code in sorted(issues)],
            "sources": [{"commit": k, "sha256": v} for k, v in sorted(provenance.items())],
            "truth_boundary": "Published observations only; gaps and overwritten history may remain. No outcome, tool use, exact lifetime total, trusted-family adoption, or budget reopening is inferred."}
