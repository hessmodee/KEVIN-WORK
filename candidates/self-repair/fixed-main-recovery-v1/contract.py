"""Pure candidate contract for Kevin fixed:main recovery.

No filesystem access, subprocesses, network calls, config writes, or authority changes.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Tuple

EXPECTED_MODEL = "ollama-chat-16k/qwen2.5:14b"
EXPECTED_PROVIDER = "ollama-chat-16k"
EXPECTED_MODEL_ID = "qwen2.5:14b"
EXPECTED_CONTEXT = 16384
EXPECTED_NUM_CTX = 16384
EXPECTED_RESERVE_FLOOR = 2048
EXPECTED_RESERVE = 2048
EXPECTED_KEEP_RECENT = 4000

ALLOWED_REPAIR_PATHS = {
    "$.agents.defaults.compaction.reserveTokens",
    "$.agents.defaults.compaction.keepRecentTokens",
}
IGNORED_METADATA_PATHS = {
    "$.meta.lastTouchedAt",
    "$.meta.lastTouchedVersion",
}


class ContractError(ValueError):
    pass


@dataclass(frozen=True)
class MainFacts:
    model_ref: str
    provider_id: str
    model_id: str
    context_tokens: Any
    num_ctx: Any
    reserve_tokens_floor: Any
    reserve_tokens: Any
    keep_recent_tokens: Any
    main_agent_found: bool


@dataclass(frozen=True)
class Classification:
    exact_model_contract: bool
    exact_context_contract: bool
    exact_floor_contract: bool
    reserve_state: str
    keep_recent_state: str
    safe_exact_repair: bool
    repair_needed: bool
    unknown_drift: Tuple[str, ...]


def _get_map(value: Any) -> Mapping[str, Any]:
    return value if isinstance(value, Mapping) else {}


def _main_agent(cfg: Mapping[str, Any]) -> Tuple[Mapping[str, Any], bool]:
    agents = _get_map(cfg.get("agents"))
    entries = _get_map(agents.get("entries"))
    if isinstance(entries.get("main"), Mapping):
        return entries["main"], True
    roster = agents.get("list")
    if isinstance(roster, list):
        hits = [x for x in roster if isinstance(x, Mapping) and x.get("id") == "main"]
        if len(hits) == 1:
            return hits[0], True
        if len(hits) > 1:
            raise ContractError("duplicate main agent entries")
    return {}, False


def _model_ref(value: Any) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, Mapping) and isinstance(value.get("primary"), str):
        return value["primary"]
    return ""


def extract_main_facts(cfg: Mapping[str, Any]) -> MainFacts:
    if not isinstance(cfg, Mapping):
        raise ContractError("config root must be an object")
    agents = _get_map(cfg.get("agents"))
    defaults = _get_map(agents.get("defaults"))
    main, found = _main_agent(cfg)
    model = _model_ref(main.get("model")) or _model_ref(defaults.get("model"))
    provider_id, model_id = (model.split("/", 1) + [""])[:2] if "/" in model else ("", model)

    provider = _get_map(_get_map(_get_map(cfg.get("models")).get("providers")).get(provider_id))
    models = provider.get("models")
    model_entry: Mapping[str, Any] = {}
    if isinstance(models, list):
        hits = [m for m in models if isinstance(m, Mapping) and m.get("id") == model_id]
        if len(hits) == 1:
            model_entry = hits[0]
        elif len(hits) > 1:
            raise ContractError("duplicate provider model entries")

    params = _get_map(model_entry.get("params"))
    compaction = _get_map(defaults.get("compaction"))
    return MainFacts(
        model_ref=model,
        provider_id=provider_id,
        model_id=model_id,
        context_tokens=model_entry.get("contextTokens"),
        num_ctx=params.get("num_ctx"),
        reserve_tokens_floor=compaction.get("reserveTokensFloor"),
        reserve_tokens=compaction.get("reserveTokens"),
        keep_recent_tokens=compaction.get("keepRecentTokens"),
        main_agent_found=found,
    )


def _state(value: Any, expected: int) -> str:
    if value is None:
        return "ABSENT"
    if isinstance(value, bool):
        return "UNEXPECTED"
    try:
        return "EXPECTED" if int(value) == expected else "UNEXPECTED"
    except (TypeError, ValueError):
        return "UNEXPECTED"


def classify_main_config(cfg: Mapping[str, Any]) -> Dict[str, Any]:
    facts = extract_main_facts(cfg)
    exact_model = facts.model_ref == EXPECTED_MODEL
    exact_context = facts.context_tokens == EXPECTED_CONTEXT and facts.num_ctx == EXPECTED_NUM_CTX
    exact_floor = facts.reserve_tokens_floor == EXPECTED_RESERVE_FLOOR
    reserve_state = _state(facts.reserve_tokens, EXPECTED_RESERVE)
    keep_state = _state(facts.keep_recent_tokens, EXPECTED_KEEP_RECENT)

    drift: List[str] = []
    if not exact_model:
        drift.append("model_ref")
    if facts.context_tokens != EXPECTED_CONTEXT:
        drift.append("context_tokens")
    if facts.num_ctx != EXPECTED_NUM_CTX:
        drift.append("num_ctx")
    if not exact_floor:
        drift.append("reserve_tokens_floor")
    if reserve_state == "UNEXPECTED":
        drift.append("reserve_tokens")
    if keep_state == "UNEXPECTED":
        drift.append("keep_recent_tokens")

    safe = exact_model and exact_context and exact_floor and reserve_state != "UNEXPECTED" and keep_state != "UNEXPECTED"
    repair_needed = safe and (reserve_state == "ABSENT" or keep_state == "ABSENT")
    classification = Classification(
        exact_model_contract=exact_model,
        exact_context_contract=exact_context,
        exact_floor_contract=exact_floor,
        reserve_state=reserve_state,
        keep_recent_state=keep_state,
        safe_exact_repair=safe,
        repair_needed=repair_needed,
        unknown_drift=tuple(drift),
    )
    return {"facts": asdict(facts), "classification": asdict(classification)}


def build_known_repair_intents(cfg: Mapping[str, Any]) -> List[Dict[str, Any]]:
    result = classify_main_config(cfg)
    c = result["classification"]
    if not c["safe_exact_repair"]:
        raise ContractError("exact known repair preconditions are not satisfied")
    intents: List[Dict[str, Any]] = []
    if c["reserve_state"] == "ABSENT":
        intents.append({
            "operation": "config_set",
            "path": "agents.defaults.compaction.reserveTokens",
            "value": EXPECTED_RESERVE,
            "strict_json": True,
            "dry_run_first": True,
        })
    if c["keep_recent_state"] == "ABSENT":
        intents.append({
            "operation": "config_set",
            "path": "agents.defaults.compaction.keepRecentTokens",
            "value": EXPECTED_KEEP_RECENT,
            "strict_json": True,
            "dry_run_first": True,
        })
    return intents


def _leaf_map(value: Any, path: str = "$") -> Dict[str, Any]:
    if isinstance(value, Mapping):
        if not value:
            return {path: "<EMPTY_OBJECT>"}
        out: Dict[str, Any] = {}
        for key in sorted(value, key=lambda x: str(x)):
            out.update(_leaf_map(value[key], f"{path}.{key}"))
        return out
    if isinstance(value, list):
        if not value:
            return {path: "<EMPTY_ARRAY>"}
        out: Dict[str, Any] = {}
        for index, item in enumerate(value):
            out.update(_leaf_map(item, f"{path}[{index}]"))
        return out
    return {path: value}


def semantic_leaf_diff(before: Mapping[str, Any], after: Mapping[str, Any]) -> List[Dict[str, Any]]:
    left = _leaf_map(before)
    right = _leaf_map(after)
    paths = sorted(set(left) | set(right))
    changes: List[Dict[str, Any]] = []
    for path in paths:
        if path in IGNORED_METADATA_PATHS:
            continue
        if path not in left:
            changes.append({"status": "ADDED", "path": path})
        elif path not in right:
            changes.append({"status": "REMOVED", "path": path})
        elif left[path] != right[path]:
            changes.append({"status": "CHANGED", "path": path})
    return changes


def assert_only_known_repair_diff(before: Mapping[str, Any], after: Mapping[str, Any]) -> List[Dict[str, Any]]:
    changes = semantic_leaf_diff(before, after)
    unexpected = [c for c in changes if c["path"] not in ALLOWED_REPAIR_PATHS]
    if unexpected:
        raise ContractError("unrelated semantic configuration change detected")
    for change in changes:
        if change["status"] != "ADDED":
            raise ContractError("known repair may only add previously absent compaction leaves")
    post = classify_main_config(after)
    c = post["classification"]
    if not c["safe_exact_repair"] or c["reserve_state"] != "EXPECTED" or c["keep_recent_state"] != "EXPECTED":
        raise ContractError("post-repair contract not satisfied")
    return changes


def _list_of_strings(value: Any) -> Tuple[str, ...]:
    if value is None:
        return ()
    if not isinstance(value, list) or any(not isinstance(x, str) for x in value):
        raise ContractError("tool policy list must contain strings only")
    return tuple(value)


def classify_tool_policy_surfaces(cfg: Mapping[str, Any]) -> Dict[str, Any]:
    """Classify authored surfaces only; never claim the runtime-effective inventory."""
    agents = _get_map(cfg.get("agents"))
    main, found = _main_agent(cfg)
    root_tools = _get_map(cfg.get("tools"))
    main_tools = _get_map(main.get("tools"))

    def scope(name: str, tools: Mapping[str, Any]) -> Dict[str, Any]:
        allow = _list_of_strings(tools.get("allow"))
        also = _list_of_strings(tools.get("alsoAllow"))
        deny = _list_of_strings(tools.get("deny"))
        if allow and also:
            raise ContractError(f"{name} sets allow and alsoAllow together")
        profile = tools.get("profile")
        if profile is not None and not isinstance(profile, str):
            raise ContractError(f"{name} profile must be a string")
        by_provider = _get_map(tools.get("byProvider"))
        sandbox = _get_map(tools.get("sandbox"))
        return {
            "present": bool(tools),
            "profile": profile or "UNSET",
            "allow_count": len(allow),
            "also_allow_count": len(also),
            "deny_count": len(deny),
            "provider_policy_count": len(by_provider),
            "sandbox_policy_present": bool(sandbox),
        }

    return {
        "main_agent_found": found,
        "root": scope("root", root_tools),
        "main": scope("main", main_tools),
        "truth_boundary": "Authored policy surfaces only; tools.catalog/tools.effective or /context detail is required for session-effective proof.",
    }
