from __future__ import annotations
from dataclasses import dataclass
from hashlib import sha256
from typing import Any, Dict

ALLOWED_EFFECTS={"read","write_candidate"}
ALLOWED_TOOLS={"repo_read","file_read","validator","benchmark","candidate_write"}
MAX_RETRIES_PER_FAMILY=3

@dataclass(frozen=True)
class Decision:
    allow: bool
    reason: str
    charge: Dict[str,int|float]
    fingerprint: str

def _fp(call: Dict[str,Any]) -> str:
    stable = "|".join([
        str(call.get("mission_id","")),
        str(call.get("tool","")),
        str(call.get("effect","")),
        str(call.get("target_id","")),
        str(call.get("operation_id","")),
        str(call.get("failure_family","")),
        str(call.get("dependency_fingerprint","")),
    ])
    return sha256(stable.encode()).hexdigest()

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
    if int(call["retry_count"]) < 0: return Decision(False,"invalid_retry_count",{},_fp(call))
    if int(call["retry_count"]) >= MAX_RETRIES_PER_FAMILY: return Decision(False,"failure_family_cooled",{},_fp(call))
    if not call["progress_token"]: return Decision(False,"missing_progress_token",{},_fp(call))
    b=call["budget"]
    for k in ("tool_calls_remaining","model_turns_remaining","elapsed_seconds_remaining","external_cost_cents_remaining"):
        if k not in b: return Decision(False,"budget_missing:"+k,{},_fp(call))
        if float(b[k]) < 0: return Decision(False,"budget_negative:"+k,{},_fp(call))
    if int(b["tool_calls_remaining"]) < 1: return Decision(False,"tool_budget_exhausted",{},_fp(call))
    if call["tool"]=="benchmark" and int(b["model_turns_remaining"]) < 1:
        return Decision(False,"model_budget_exhausted",{},_fp(call))
    if float(b["elapsed_seconds_remaining"]) <= float(call["latency_cost"]):
        return Decision(False,"time_budget_exhausted",{},_fp(call))
    fp=_fp(call)
    seen=set(state.get("seen_call_fingerprints",[]))
    if fp in seen: return Decision(False,"duplicate_call",{},fp)
    prior_progress=set(state.get("seen_progress_tokens",[]))
    if call["progress_token"] in prior_progress:
        return Decision(False,"no_semantic_progress",{},fp)
    if call["effect"]=="write_candidate" and not call.get("idempotency_key"):
        return Decision(False,"write_requires_idempotency_key",{},fp)
    if float(call["expected_utility"]) <= 0:
        return Decision(False,"nonpositive_expected_utility",{},fp)
    charge={"tool_calls":1,"model_turns":1 if call["tool"]=="benchmark" else 0,
            "elapsed_seconds":float(call["latency_cost"]),"external_cost_cents":0}
    return Decision(True,"allowed",charge,fp)

def apply(decision: Decision, call: Dict[str,Any], state: Dict[str,Any]) -> Dict[str,Any]:
    if not decision.allow: raise ValueError("cannot apply rejected decision")
    out={k:(list(v) if isinstance(v,list) else v) for k,v in state.items()}
    out.setdefault("seen_call_fingerprints",[]).append(decision.fingerprint)
    out.setdefault("seen_progress_tokens",[]).append(call["progress_token"])
    return out
