"""Pure fixed:main tool-policy classifier for OpenClaw 2026.7.1-2.

No filesystem, network, process, config write, or tool invocation occurs here.
The classifier accepts already-parsed config and returns only bounded policy metadata.
"""
from __future__ import annotations

import hashlib
import json
from typing import Any, Dict, List

KNOWN_SAFE_CONTROL = {
    "get_goal", "create_goal", "update_goal", "update_plan", "progress_card",
    "session_status", "sessions_list", "sessions_history", "read",
}
PROTECTED = {
    "exec", "process", "write", "edit", "apply_patch", "browser",
    "sessions_spawn", "sessions_send", "conversations_send", "cron",
}
PROFILES = {"minimal", "coding", "messaging", "full"}


class PolicyError(ValueError):
    pass


def _obj(value: Any) -> Dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise PolicyError("policy scope must be an object")
    return value


def _enum(value: Any, allowed: set[str]) -> str:
    if value is None:
        return "UNSET"
    return value if isinstance(value, str) and value in allowed else "OTHER"


def _list(value: Any) -> List[str]:
    if value is None:
        return []
    if not isinstance(value, list) or any(not isinstance(x, str) for x in value):
        raise PolicyError("tool allow/deny values must be string arrays")
    return sorted(set(value), key=str.casefold)


def _hash(values: List[str]) -> str:
    blob = json.dumps(values, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(blob.encode("utf-8")).hexdigest().upper()


def _policy(scope: Any) -> Dict[str, Any]:
    scope = _obj(scope)
    profile = scope.get("profile")
    if profile is not None and profile not in PROFILES:
        profile = "OTHER"
    allow = _list(scope.get("allow"))
    also = _list(scope.get("alsoAllow"))
    deny = _list(scope.get("deny"))
    if allow and also:
        raise PolicyError("allow and alsoAllow are mutually exclusive")
    lowered_allow = {x.casefold() for x in allow + also}
    lowered_deny = {x.casefold() for x in deny}
    return {
        "present": bool(scope),
        "profile": profile or "UNSET",
        "allow_count": len(allow),
        "also_allow_count": len(also),
        "deny_count": len(deny),
        "allow_hash": _hash(allow),
        "also_allow_hash": _hash(also),
        "deny_hash": _hash(deny),
        "known_control_allowed": sorted(x for x in KNOWN_SAFE_CONTROL if x.casefold() in lowered_allow),
        "protected_explicitly_allowed": sorted(x for x in PROTECTED if x.casefold() in lowered_allow),
        "protected_explicitly_denied": sorted(x for x in PROTECTED if x.casefold() in lowered_deny),
    }


def classify(config: Any) -> Dict[str, Any]:
    if not isinstance(config, dict):
        raise PolicyError("config root must be an object")
    agents = _obj(config.get("agents"))
    rows = agents.get("list")
    if rows is None:
        rows = []
    if not isinstance(rows, list):
        raise PolicyError("agents.list must be an array in the installed-version contract")
    mains = [x for x in rows if isinstance(x, dict) and x.get("id") == "main"]
    if len(mains) > 1:
        raise PolicyError("multiple main agent entries")
    main = mains[0] if mains else {}
    model = main.get("model") or _obj(agents.get("defaults")).get("model")
    if isinstance(model, dict):
        model = model.get("primary")
    model = model if isinstance(model, str) else "UNKNOWN"
    provider = model.split("/", 1)[0] if "/" in model else "UNKNOWN"

    root_tools = _obj(config.get("tools"))
    main_tools = _obj(main.get("tools"))
    root_by = _obj(root_tools.get("byProvider"))
    main_by = _obj(main_tools.get("byProvider"))

    def provider_scope(container: Dict[str, Any]) -> Dict[str, Any]:
        # v2026.7.1-2 checks the full model key before the provider key.
        if model in container:
            return _obj(container[model])
        if provider in container:
            return _obj(container[provider])
        return {}

    sandbox = _obj(main.get("sandbox"))
    sandbox_tools = _obj(_obj(main_tools.get("sandbox")).get("tools"))
    if not sandbox_tools:
        sandbox_tools = _obj(_obj(root_tools.get("sandbox")).get("tools"))

    return {
        "schema": 1,
        "kind": "kevin-main-tool-policy-classification",
        "installed_schema_contract": "agents.list",
        "main_entry_count": len(mains),
        "model_family": "QWEN2_5" if "qwen2.5" in model.casefold() else "OTHER",
        "model_id_sha256": hashlib.sha256(model.encode()).hexdigest().upper(),
        "provider_id_sha256": hashlib.sha256(provider.encode()).hexdigest().upper(),
        "root": _policy(root_tools),
        "main": _policy(main_tools),
        "root_provider": _policy(provider_scope(root_by)),
        "main_provider": _policy(provider_scope(main_by)),
        "sandbox": {
            "mode": _enum(sandbox.get("mode"), {"off", "all", "non-main"}),
            "workspace_access": _enum(sandbox.get("workspaceAccess"), {"none", "ro", "rw"}),
            "tools": _policy(sandbox_tools),
        },
        "risk_flags": {
            "broad_root_profile": root_tools.get("profile") in {"coding", "full"},
            "broad_main_profile": main_tools.get("profile") in {"coding", "full"},
            "protected_explicit_allow": bool(_policy(root_tools)["protected_explicitly_allowed"] or _policy(main_tools)["protected_explicitly_allowed"]),
        },
    }
