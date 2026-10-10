#!/usr/bin/env python3
"""Pure validator for Kevin Phase 2C browser observe/navigate requests.

Candidate only. This file performs no DNS, network, browser, filesystem, process,
shell, credential, or host mutation. It validates typed requests against an
already-installed policy supplied separately from the request.
"""
from __future__ import annotations

import ipaddress
from urllib.parse import urlsplit

OBSERVE_FIELDS = {
    "schema", "kind", "authority", "max_nodes", "max_depth", "max_bytes",
    "screenshot_hash_evidence", "semantic_role", "semantic_name",
}
NAVIGATE_FIELDS = {
    "schema", "kind", "authority", "url", "timeout_ms", "wait_until", "max_redirects",
}
WAIT_UNTIL = {"domcontentloaded", "load"}
DANGEROUS_SCHEMES = {"javascript", "data", "file", "gopher", "ftp", "smb", "dict"}


def _base(req, kind, fields):
    errors = []
    if not isinstance(req, dict):
        return ["request must be object"]
    if set(req) - fields:
        errors.append("unknown request field")
    if req.get("schema") != 1:
        errors.append("schema must be 1")
    if req.get("kind") != kind:
        errors.append("kind mismatch")
    if req.get("authority") != "GREEN":
        errors.append("authority must be GREEN")
    return errors


def validate_observe(req):
    errors = _base(req, "kevin-browser-observe", OBSERVE_FIELDS)
    if errors:
        return errors

    for key, lower, upper in (
        ("max_nodes", 1, 200),
        ("max_depth", 1, 8),
        ("max_bytes", 1024, 65536),
    ):
        value = req.get(key)
        if not isinstance(value, int) or isinstance(value, bool) or not lower <= value <= upper:
            errors.append(f"{key} out of bounds")

    if not isinstance(req.get("screenshot_hash_evidence"), bool):
        errors.append("screenshot_hash_evidence must be boolean")

    role = req.get("semantic_role")
    name = req.get("semantic_name")
    if role is not None and (not isinstance(role, str) or not role.strip() or len(role) > 80):
        errors.append("semantic_role invalid")
    if name is not None and (not isinstance(name, str) or not name.strip() or len(name) > 200):
        errors.append("semantic_name invalid")

    return errors


def _normalize_host(host):
    if not host:
        raise ValueError("missing host")
    h = host.rstrip(".").lower()
    return h.encode("idna").decode("ascii")


def _literal_ip(host):
    try:
        return ipaddress.ip_address(host.strip("[]"))
    except ValueError:
        return None


def validate_policy(policy):
    errors = []
    if not isinstance(policy, dict):
        return ["policy must be object"]
    allowed = {
        "allowed_https_hosts", "allowed_https_ports", "resolved_ip_policy",
        "redirect_policy", "allow_test_loopback_http", "test_loopback_ports",
    }
    if set(policy) != allowed:
        errors.append("policy fields mismatch")
    hosts = policy.get("allowed_https_hosts")
    if not isinstance(hosts, list) or not hosts:
        errors.append("allowed_https_hosts required")
    else:
        for h in hosts:
            if not isinstance(h, str) or not h.strip() or "*" in h or "/" in h or "://" in h:
                errors.append("host allowlist must use exact hostnames")
                break
            try:
                if _literal_ip(_normalize_host(h)) is not None:
                    errors.append("production host allowlist must not use IP literals")
                    break
            except Exception:
                errors.append("invalid allowed host")
                break
    ports = policy.get("allowed_https_ports")
    if not isinstance(ports, list) or not ports or any(not isinstance(p, int) or isinstance(p, bool) or not 1 <= p <= 65535 for p in ports):
        errors.append("allowed_https_ports invalid")
    if policy.get("resolved_ip_policy") != "PUBLIC_ONLY":
        errors.append("resolved IP policy must be PUBLIC_ONLY")
    if policy.get("redirect_policy") != "REVALIDATE_EACH_HOP":
        errors.append("redirect policy must revalidate each hop")
    if not isinstance(policy.get("allow_test_loopback_http"), bool):
        errors.append("allow_test_loopback_http must be boolean")
    test_ports = policy.get("test_loopback_ports")
    if not isinstance(test_ports, list) or any(not isinstance(p, int) or isinstance(p, bool) or not 1024 <= p <= 65535 for p in test_ports):
        errors.append("test_loopback_ports invalid")
    return errors


def validate_navigate(req, policy):
    errors = _base(req, "kevin-browser-navigate", NAVIGATE_FIELDS)
    errors.extend(validate_policy(policy))
    if errors:
        return errors

    timeout = req.get("timeout_ms")
    redirects = req.get("max_redirects")
    if not isinstance(timeout, int) or isinstance(timeout, bool) or not 1000 <= timeout <= 30000:
        errors.append("timeout_ms out of bounds")
    if not isinstance(redirects, int) or isinstance(redirects, bool) or not 0 <= redirects <= 5:
        errors.append("max_redirects out of bounds")
    if req.get("wait_until") not in WAIT_UNTIL:
        errors.append("wait_until invalid")

    raw = req.get("url")
    if not isinstance(raw, str) or not raw.strip() or len(raw) > 2048:
        errors.append("url invalid")
        return errors
    if raw != raw.strip():
        errors.append("url whitespace forbidden")
        return errors

    # Parse the scheme before requiring a network host. Non-network/dangerous
    # schemes such as file: and javascript: frequently have no hostname; they
    # must still be classified explicitly as forbidden rather than collapsing
    # into a generic parse failure.
    try:
        u = urlsplit(raw)
        scheme = u.scheme.lower()
    except Exception:
        errors.append("url parse failed")
        return errors

    if scheme in DANGEROUS_SCHEMES or scheme not in {"https", "http"}:
        errors.append("scheme forbidden")
        return errors

    if not u.netloc:
        errors.append("network location required")
        return errors

    try:
        host = _normalize_host(u.hostname)
    except Exception:
        errors.append("url parse failed")
        return errors

    if u.username is not None or u.password is not None:
        errors.append("embedded credentials forbidden")

    ip = _literal_ip(host)
    try:
        port = u.port
    except ValueError:
        errors.append("port invalid")
        return errors

    if scheme == "https":
        if ip is not None:
            errors.append("production IP literal forbidden")
        allowed_hosts = {_normalize_host(x) for x in policy["allowed_https_hosts"]}
        if host not in allowed_hosts:
            errors.append("host not allowlisted")
        effective_port = 443 if port is None else port
        if effective_port not in set(policy["allowed_https_ports"]):
            errors.append("https port not allowlisted")
    else:
        # HTTP exists only for a deliberate local deterministic test harness.
        if policy["allow_test_loopback_http"] is not True:
            errors.append("http forbidden outside explicit test policy")
        if ip is None or not ip.is_loopback:
            errors.append("test http must use literal loopback IP")
        if port is None or port not in set(policy["test_loopback_ports"]):
            errors.append("test loopback port not allowlisted")

    return errors


def sanitized_navigation_evidence(url):
    """Return origin/path only; never echo query, fragment, or userinfo."""
    u = urlsplit(url)
    host = _normalize_host(u.hostname)
    port = u.port
    scheme = u.scheme.lower()
    default = (scheme == "https" and (port is None or port == 443)) or (scheme == "http" and port == 80)
    authority = host if default or port is None else f"{host}:{port}"
    path = u.path or "/"
    return f"{scheme}://{authority}{path}"
