#!/usr/bin/env python3
from copy import deepcopy

from validate_browser_contract_v0_1 import (
    sanitized_navigation_evidence,
    validate_navigate,
    validate_observe,
    validate_policy,
)

POLICY = {
    "allowed_https_hosts": ["docs.example.com", "example.com"],
    "allowed_https_ports": [443],
    "resolved_ip_policy": "PUBLIC_ONLY",
    "redirect_policy": "REVALIDATE_EACH_HOP",
    "allow_test_loopback_http": True,
    "test_loopback_ports": [3000, 4173],
}
OBS = {
    "schema": 1,
    "kind": "kevin-browser-observe",
    "authority": "GREEN",
    "max_nodes": 120,
    "max_depth": 6,
    "max_bytes": 32768,
    "screenshot_hash_evidence": True,
    "semantic_role": "button",
    "semantic_name": "Continue",
}
NAV = {
    "schema": 1,
    "kind": "kevin-browser-navigate",
    "authority": "GREEN",
    "url": "https://docs.example.com/guide?q=browser#section",
    "timeout_ms": 15000,
    "wait_until": "domcontentloaded",
    "max_redirects": 3,
}


def test_observe_bounded_semantic_request_passes():
    assert validate_observe(deepcopy(OBS)) == []


def test_observe_rejects_budget_escape_and_unknown_sensitive_fields():
    x = deepcopy(OBS); x["max_nodes"] = 201
    assert "max_nodes out of bounds" in validate_observe(x)
    x = deepcopy(OBS); x["cookies"] = True
    assert "unknown request field" in validate_observe(x)
    x = deepcopy(OBS); x["full_ax_tree"] = True
    assert "unknown request field" in validate_observe(x)


def test_observe_requires_green_authority():
    x = deepcopy(OBS); x["authority"] = "YELLOW"
    assert "authority must be GREEN" in validate_observe(x)


def test_https_exact_allowlist_passes():
    assert validate_navigate(deepcopy(NAV), deepcopy(POLICY)) == []


def test_subdomain_is_not_implicitly_allowlisted():
    x = deepcopy(NAV); x["url"] = "https://evil.docs.example.com/"
    assert "host not allowlisted" in validate_navigate(x, POLICY)


def test_policy_wildcards_fail_closed():
    p = deepcopy(POLICY); p["allowed_https_hosts"] = ["*.example.com"]
    assert "host allowlist must use exact hostnames" in validate_policy(p)


def test_embedded_credentials_and_dangerous_schemes_rejected():
    x = deepcopy(NAV); x["url"] = "https://user:secret@docs.example.com/"
    assert "embedded credentials forbidden" in validate_navigate(x, POLICY)
    x = deepcopy(NAV); x["url"] = "file:///etc/passwd"
    assert "scheme forbidden" in validate_navigate(x, POLICY)
    x = deepcopy(NAV); x["url"] = "javascript:alert(1)"
    assert "scheme forbidden" in validate_navigate(x, POLICY)


def test_production_ip_literals_and_nonstandard_ports_rejected():
    x = deepcopy(NAV); x["url"] = "https://127.0.0.1/"
    e = validate_navigate(x, POLICY)
    assert "production IP literal forbidden" in e
    x = deepcopy(NAV); x["url"] = "https://docs.example.com:8443/"
    assert "https port not allowlisted" in validate_navigate(x, POLICY)


def test_http_only_for_explicit_literal_loopback_test_harness():
    x = deepcopy(NAV); x["url"] = "http://127.0.0.1:3000/fixture"
    assert validate_navigate(x, POLICY) == []
    x = deepcopy(NAV); x["url"] = "http://localhost:3000/fixture"
    assert "test http must use literal loopback IP" in validate_navigate(x, POLICY)
    p = deepcopy(POLICY); p["allow_test_loopback_http"] = False
    x = deepcopy(NAV); x["url"] = "http://127.0.0.1:3000/fixture"
    assert "http forbidden outside explicit test policy" in validate_navigate(x, p)


def test_redirect_and_resolved_ip_policy_are_not_caller_optional():
    p = deepcopy(POLICY); p["redirect_policy"] = "FOLLOW_BLINDLY"
    assert "redirect policy must revalidate each hop" in validate_policy(p)
    p = deepcopy(POLICY); p["resolved_ip_policy"] = "ANY"
    assert "resolved IP policy must be PUBLIC_ONLY" in validate_policy(p)


def test_bounds_reject_unlimited_navigation_behavior():
    x = deepcopy(NAV); x["max_redirects"] = 6
    assert "max_redirects out of bounds" in validate_navigate(x, POLICY)
    x = deepcopy(NAV); x["timeout_ms"] = 60000
    assert "timeout_ms out of bounds" in validate_navigate(x, POLICY)
    x = deepcopy(NAV); x["wait_until"] = "networkidle"
    assert "wait_until invalid" in validate_navigate(x, POLICY)


def test_query_and_fragment_are_never_echoed_in_evidence():
    got = sanitized_navigation_evidence("https://docs.example.com/path?q=secret#frag")
    assert got == "https://docs.example.com/path"
    assert "secret" not in got and "frag" not in got


def test_caller_cannot_inject_allowlist_selector_force_or_script_fields():
    for field, value in (
        ("allowed_hosts", ["evil.example"]),
        ("css", "#submit"),
        ("xpath", "//button[1]"),
        ("force", True),
        ("javascript", "doSomething()"),
    ):
        x = deepcopy(NAV); x[field] = value
        assert "unknown request field" in validate_navigate(x, POLICY)


def test_authority_must_be_green_and_policy_exact():
    x = deepcopy(NAV); x["authority"] = "RED"
    assert "authority must be GREEN" in validate_navigate(x, POLICY)
    p = deepcopy(POLICY); p["extra"] = True
    assert "policy fields mismatch" in validate_policy(p)


def test_url_whitespace_and_invalid_port_fail_closed():
    x = deepcopy(NAV); x["url"] = " https://docs.example.com/"
    assert "url whitespace forbidden" in validate_navigate(x, POLICY)
    x = deepcopy(NAV); x["url"] = "https://docs.example.com:99999/"
    assert "port invalid" in validate_navigate(x, POLICY)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
    print(f"PASS {len(tests)}/{len(tests)} browser contract cases")
