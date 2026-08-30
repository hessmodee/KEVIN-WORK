from __future__ import annotations
from copy import deepcopy
from dataclasses import dataclass
from hashlib import sha256
from typing import Any, Dict

ALLOWED_EFFECTS={"read","write_candidate"}
ALLOWED_TOOLS={"repo_read","file_read","validator","benchmark","candidate_write"}
MAX_RETRIES_PER_FAMILY=3
BUDGET_KEYS=("tool_calls_remaining","model_turns_remaining","elapsed_seconds_remaining","external_cost_cents_remaining")

@dataclass(frozen=True)
class Decision:
    allow: bool
    reason: str
    charge: Dict[str,int|float]
    fingerprint: str


def _fp(call: Dict[str,Any]) -> str:
    # Intentionally excludes caller-chosen operation_id so a caller cannot evade
    # duplicate detection merely by minting a new operation identifier.
    stable = "|".join([
        str(call.get("mission_id","")),
        str(call.get("tool","")),
        str(call.get("effect","")),
        str(call.get("target_id","")),
        str(call.get("failure_family","")),
        str(call.get("dependency_fingerprint","")),
        str(call.get("progress_token","")),
    ])
    return sha256(stable.encode()).hexdigest()


def _family_key(call: Dict[str,Any]) -> str | None:
    family=str(call.get("failure_family","")).strip()
    dep=str(call.get("dependency_fingerprint","")).strip()
    if not family and not dep:
        return None
    if not family or not dep:
        return "INVALID"
    return sha256((family+"|"+dep).encode()).hexdigest()


def _valid_budget(b: Any) -> str | None:
    if not isinstance(b,dict):
        return "budget_not_object"
    unknown=set(b)-set(BUDGET_KEYS)
    if unknown:
        return "budget_unknown:"+",".join(sorted(unknown))
    for k in BUDGET_KEYS:
        if k not in b:
            return "budget_missing:"+k
        try:
            v=float(b[k])
        except (TypeError,ValueError):
            return "budget_non_numeric:"+k
        if v < 0:
            return "budget_negative:"+k
    return None


def evaluate(call: Dict[str,Any], state: Dict[str,Any]) -> Decision:
    required={"mission_id","tool","effect","target_id","operation_id","expected_utility","latency_cost",
              "risk","retry_count","budget","progress_token"}
    unknown=set(call)-{
        *required,"failure_family","dependency_fingerprint","idempotency_key"
    }
    missing=required-set(call)
    if missing: return Decision(False,"missing_fields:"+",".join(sorted(missing)),{},_fp(call))
    if unknown: return Decision(False,"unknown_fields:"+",".join(sorted(unknown)),{},_fp(call))
    if call["tool"] not in ALLOWED_TOOLS: return Decision(False,"tool_not_allowlisted",{},_fp(call))
    if call["effect"] not in ALLOWED_EFFECTS: return Decision(False,"effect_not_allowed",{},_fp(call))
    if call["risk"] not in {"low","medium"}: return Decision(False,"risk_not_allowed",{},_fp(call))
    if not str(call["mission_id"]).strip() or not str(call["target_id"]).strip() or not str(call["operation_id"]).strip():
        return Decision(False,"empty_identity_field",{},_fp(call))
    if not call["progress_token"]: return Decision(False,"missing_progress_token",{},_fp(call))

    try:
        retry_count=int(call["retry_count"])
        latency=float(call["latency_cost"])
        utility=float(call["expected_utility"])
    except (TypeError,ValueError):
        return Decision(False,"invalid_numeric_field",{},_fp(call))
    if retry_count < 0: return Decision(False,"invalid_retry_count",{},_fp(call))
    if latency < 0: return Decision(False,"invalid_latency_cost",{},_fp(call))
    if utility <= 0: return Decision(False,"nonpositive_expected_utility",{},_fp(call))

    budget_error=_valid_budget(call["budget"])
    if budget_error: return Decision(False,budget_error,{},_fp(call))
    presented={k:float(call["budget"][k]) for k in BUDGET_KEYS}
    persisted=state.get("remaining_budget")
    if persisted is not None:
        persisted_error=_valid_budget(persisted)
        if persisted_error: return Decision(False,"state_"+persisted_error,{},_fp(call))
        canonical={k:float(persisted[k]) for k in BUDGET_KEYS}
        if presented != canonical:
            return Decision(False,"budget_state_mismatch",{},_fp(call))
        budget=canonical
    else:
        budget=presented

    if budget["tool_calls_remaining"] < 1: return Decision(False,"tool_budget_exhausted",{},_fp(call))
    model_charge=1 if call["tool"]=="benchmark" else 0
    if budget["model_turns_remaining"] < model_charge:
        return Decision(False,"model_budget_exhausted",{},_fp(call))
    if budget["elapsed_seconds_remaining"] < latency:
        return Decision(False,"time_budget_exhausted",{},_fp(call))

    family_key=_family_key(call)
    if family_key == "INVALID":
        return Decision(False,"failure_family_requires_dependency_fingerprint",{},_fp(call))
    retry_counts=state.get("retry_counts",{})
    if not isinstance(retry_counts,dict):
        return Decision(False,"state_retry_counts_invalid",{},_fp(call))
    current_retry=int(retry_counts.get(family_key,0)) if family_key else 0
    if retry_count != current_retry:
        return Decision(False,"retry_state_mismatch",{},_fp(call))
    if current_retry >= MAX_RETRIES_PER_FAMILY:
        return Decision(False,"failure_family_cooled",{},_fp(call))

    fp=_fp(call)
    seen=set(state.get("seen_call_fingerprints",[]))
    if fp in seen: return Decision(False,"duplicate_call",{},fp)
    prior_progress=set(state.get("seen_progress_tokens",[]))
    if call["progress_token"] in prior_progress:
        return Decision(False,"no_semantic_progress",{},fp)

    idem=str(call.get("idempotency_key","")).strip()
    if call["effect"]=="write_candidate" and not idem:
        return Decision(False,"write_requires_idempotency_key",{},fp)
    if idem and idem in set(state.get("used_idempotency_keys",[])):
        return Decision(False,"idempotency_replay",{},fp)

    charge={"tool_calls":1,"model_turns":model_charge,
            "elapsed_seconds":latency,"external_cost_cents":0}
    return Decision(True,"allowed",charge,fp)


def apply(decision: Decision, call: Dict[str,Any], state: Dict[str,Any]) -> Dict[str,Any]:
    if not decision.allow: raise ValueError("cannot apply rejected decision")
    out=deepcopy(state)
    out.setdefault("seen_call_fingerprints",[]).append(decision.fingerprint)
    out.setdefault("seen_progress_tokens",[]).append(call["progress_token"])

    idem=str(call.get("idempotency_key","")).strip()
    if idem:
        out.setdefault("used_idempotency_keys",[]).append(idem)

    family_key=_family_key(call)
    if family_key and family_key != "INVALID":
        counts=out.setdefault("retry_counts",{})
        counts[family_key]=int(counts.get(family_key,0))+1

    source=out.get("remaining_budget",call["budget"])
    remaining={k:float(source[k]) for k in BUDGET_KEYS}
    remaining["tool_calls_remaining"]-=decision.charge["tool_calls"]
    remaining["model_turns_remaining"]-=decision.charge["model_turns"]
    remaining["elapsed_seconds_remaining"]-=decision.charge["elapsed_seconds"]
    remaining["external_cost_cents_remaining"]-=decision.charge["external_cost_cents"]
    if any(v < 0 for v in remaining.values()):
        raise ValueError("budget underflow")
    out["remaining_budget"]=remaining
    return out
