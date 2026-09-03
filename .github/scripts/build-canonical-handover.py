#!/usr/bin/env python3
"""Build Kevin's one canonical cross-AI handover and its machine twin.

The human authority is AI-HANDOVER.md. reports/handoff-latest.json is only a
machine-readable representation of the same checkpoint and never outranks the
human document or fresher correlated runtime evidence.

The builder deliberately fingerprints *semantic turnover state*, not raw
telemetry bytes/timestamps. HESS-PC publishes fresh reports frequently; making
every heartbeat timestamp a handover commit would create repository churn and
continually move `main` underneath active engineering branches. A checkpoint is
rewritten when the current task or a turnover-relevant semantic state changes.
The handover still instructs incoming agents to read the fresh reports directly.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CURRENT_TASK = ROOT / "inbox" / "CURRENT_TASK.md"
ENGINEERING = ROOT / "reports" / "engineering" / "latest.json"
SUPPORT = ROOT / "reports" / "support-latest.json"
AUTONOMY = ROOT / "reports" / "autonomy-continuation-latest.json"
HANDOVER_MD = ROOT / "AI-HANDOVER.md"
HANDOVER_JSON = ROOT / "reports" / "handoff-latest.json"

GITHUB_VIEW = "https://github.com/hessmodee/KEVIN-WORK/blob/main/AI-HANDOVER.md"
GITHUB_RAW = "https://raw.githubusercontent.com/hessmodee/KEVIN-WORK/main/AI-HANDOVER.md"
HQ_VIEW = "https://hessmodee.github.io/KEVIN-WORK/handover.html"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig") if path.exists() else ""


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        value = json.loads(read_text(path))
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest().upper()


def dot(obj: Any, *path: str, default: Any = None) -> Any:
    cur = obj
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur


def latest_timestamp(*values: Any) -> str:
    candidates = [str(v) for v in values if v]
    return max(candidates) if candidates else "UNKNOWN"


def normalize_cron(rows: Any) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    if not isinstance(rows, list):
        return result
    for row in rows:
        if not isinstance(row, dict):
            continue
        result.append(
            {
                "key": row.get("declaration_key") or row.get("name") or "UNKNOWN",
                "enabled": row.get("enabled"),
                "last_status": row.get("last_status"),
                "consecutive_errors": row.get("consecutive_errors"),
                "every_ms": row.get("every_ms"),
            }
        )
    return sorted(result, key=lambda x: str(x["key"]))


def ui_health(age: Any) -> str:
    try:
        seconds = float(age)
    except (TypeError, ValueError):
        return "UNKNOWN"
    if seconds < 60:
        return "FRESH"
    if seconds < 300:
        return "DEGRADED"
    return "STALE"


def semantic_checkpoint(
    task: str,
    engineering: dict[str, Any],
    support: dict[str, Any],
    autonomy: dict[str, Any],
) -> dict[str, Any]:
    benchmark_status = dot(
        engineering,
        "action",
        "benchmark",
        "status",
        default=dot(support, "benchmark", "status", default="UNKNOWN"),
    )
    benchmark_passed = dot(
        engineering,
        "action",
        "benchmark",
        "passed",
        default=dot(support, "benchmark", "regression", "passed", default="?"),
    )
    benchmark_total = dot(
        engineering,
        "action",
        "benchmark",
        "total",
        default=dot(support, "benchmark", "regression", "total", default="?"),
    )
    benchmark_critical = dot(
        engineering,
        "action",
        "benchmark",
        "critical",
        default=dot(support, "benchmark", "regression", "critical_failures", default="?"),
    )
    ui_age = dot(engineering, "action", "ui_bridge", "heartbeat_age_seconds", default=None)
    queues = dot(engineering, "action", "queues", default={})
    skills = dot(engineering, "action", "composite_skills", default={})
    latest_skill = skills.get("latest_proven") if isinstance(skills, dict) else None
    return {
        "current_task_sha256": sha256_text(task),
        "benchmark": {
            "status": benchmark_status,
            "passed": benchmark_passed,
            "total": benchmark_total,
            "critical": benchmark_critical,
        },
        "ui_bridge_health": ui_health(ui_age),
        "ui_bridge_task_present": dot(engineering, "action", "ui_bridge", "task_present", default=None),
        "supervisor_last_result": dot(support, "supervisor", "last_result", default="UNKNOWN"),
        "autonomy_status": autonomy.get("status", "UNKNOWN"),
        "autonomy_eligible_count": autonomy.get("eligible_count", "UNKNOWN"),
        "queues": {
            "ready": queues.get("ready") if isinstance(queues, dict) else None,
            "running": queues.get("running") if isinstance(queues, dict) else None,
            "failed": queues.get("failed") if isinstance(queues, dict) else None,
        },
        "composite_skills": {
            "proven_count": skills.get("proven_count") if isinstance(skills, dict) else None,
            "failed": skills.get("failed") if isinstance(skills, dict) else None,
            "latest_proven_key": latest_skill.get("key") if isinstance(latest_skill, dict) else None,
        },
        "maintenance_runner_sha256": dot(support, "hashes", "maintenance_runner", default="UNKNOWN"),
        "cron": normalize_cron(dot(engineering, "action", "cron", default=[])),
    }


def main() -> None:
    task = read_text(CURRENT_TASK).strip()
    engineering = read_json(ENGINEERING)
    support = read_json(SUPPORT)
    autonomy = read_json(AUTONOMY)

    eng_at = engineering.get("generated_at", "UNKNOWN")
    sup_at = support.get("generated_at", "UNKNOWN")
    auto_at = autonomy.get("generated_at", "UNKNOWN")
    evidence_at = latest_timestamp(eng_at, sup_at, auto_at)

    benchmark_status = dot(engineering, "action", "benchmark", "status", default=dot(support, "benchmark", "status", default="UNKNOWN"))
    benchmark_passed = dot(engineering, "action", "benchmark", "passed", default=dot(support, "benchmark", "regression", "passed", default="?"))
    benchmark_total = dot(engineering, "action", "benchmark", "total", default=dot(support, "benchmark", "regression", "total", default="?"))
    benchmark_critical = dot(engineering, "action", "benchmark", "critical", default=dot(support, "benchmark", "regression", "critical_failures", default="?"))
    ui_age = dot(engineering, "action", "ui_bridge", "heartbeat_age_seconds", default="UNKNOWN")
    supervisor_result = dot(support, "supervisor", "last_result", default="UNKNOWN")
    proven_skills = dot(engineering, "action", "composite_skills", "proven_count", default="UNKNOWN")
    maintenance_sha = dot(support, "hashes", "maintenance_runner", default="UNKNOWN")

    semantic = semantic_checkpoint(task, engineering, support, autonomy)
    source_fingerprint = sha256_text(json.dumps(semantic, sort_keys=True, separators=(",", ":")))

    previous_twin = read_json(HANDOVER_JSON)
    if (
        previous_twin.get("schema") == 4
        and previous_twin.get("semantic_fingerprint_sha256") == source_fingerprint
        and HANDOVER_MD.exists()
    ):
        # Fresh telemetry may have advanced, but no turnover-relevant semantic
        # state changed. Preserve the existing checkpoint byte-for-byte to keep
        # main stable for active engineering branches.
        return

    source_hashes = {
        "current_task_sha256": sha256_text(task),
        "engineering_sha256_at_checkpoint": sha256_text(read_text(ENGINEERING)),
        "support_sha256_at_checkpoint": sha256_text(read_text(SUPPORT)),
        "autonomy_sha256_at_checkpoint": sha256_text(read_text(AUTONOMY)),
    }

    twin = {
        "schema": 4,
        "kind": "kevin-canonical-handover-machine-twin",
        "canonical_human_authority": "AI-HANDOVER.md",
        "authority_rule": "This JSON is a machine twin only. AI-HANDOVER.md is the one canonical human handover; fresher correlated runtime evidence outranks both.",
        "evidence_updated_at": evidence_at,
        "semantic_fingerprint_sha256": source_fingerprint,
        "semantic_checkpoint": semantic,
        "source_hashes": source_hashes,
        "universal_access": {
            "github": GITHUB_VIEW,
            "raw": GITHUB_RAW,
            "hq": HQ_VIEW,
        },
        "cross_ai_rule": {
            "one_handover": True,
            "no_dated_replacement_handoffs": True,
            "durable_local_work_must_be_published": True,
            "local_only_changes_are_not_complete": True,
            "required_checkpoint_after_material_change": True,
            "semantic_no_churn": True,
        },
        "runtime_snapshot": {
            "engineering_at": eng_at,
            "support_at": sup_at,
            "autonomy_at": auto_at,
            "benchmark": {
                "status": benchmark_status,
                "passed": benchmark_passed,
                "total": benchmark_total,
                "critical": benchmark_critical,
            },
            "ui_bridge_heartbeat_age_seconds_at_checkpoint": ui_age,
            "ui_bridge_health": ui_health(ui_age),
            "supervisor_last_result": supervisor_result,
            "proven_composite_skills": proven_skills,
            "maintenance_runner_sha256": maintenance_sha,
        },
        "current_task_path": "inbox/CURRENT_TASK.md",
        "fresh_runtime_sources": [
            "reports/support-latest.json",
            "reports/engineering/latest.json",
            "reports/autonomy-continuation-latest.json",
        ],
        "privacy": {
            "public_safe_metadata_only": True,
            "secrets_allowed": False,
            "private_message_bodies_allowed": False,
        },
    }

    md = f"""# Kevin AI Engineering Handover — CANONICAL

> **THIS IS THE ONE CURRENT HANDOVER FOR KEVIN.** Do not create a competing dated handover. Update the source task/evidence and let the canonical handover refresh replace stale state.

**Semantic checkpoint evidence through:** {evidence_at}  
**Canonical repository:** `hessmodee/KEVIN-WORK` / `main`  
**Machine twin:** `reports/handoff-latest.json` (not a second authority)

## Universal access

Any replacement AI — ChatGPT, ChatGPT Work, Grok, Grok Build, Grokbot, Kevin, or another agent — should be given or should fetch **this exact file first**:

- GitHub: {GITHUB_VIEW}
- Raw text: {GITHUB_RAW}
- Kevin HQ: {HQ_VIEW}

If an agent cannot access one route, use another. Matt should never need to reconstruct the build from chat history.

## Absolute continuity rules

1. `AI-HANDOVER.md` is the **only human current handover**. Do not create `HANDOVER-<date>`, agent-specific handover files, or parallel current-state summaries. Historical engineering records may exist, but they are evidence, not the current turnover surface.
2. Fresh correlated HESS-PC/OpenClaw evidence outranks this document. Always inspect `reports/support-latest.json`, `reports/engineering/latest.json`, and the applicable runtime/autonomy receipts after opening this handover.
3. Every AI must read `AI-HANDOVER.md` and `inbox/CURRENT_TASK.md` before substantive Kevin work.
4. Every material durable change must be committed/pushed to `hessmodee/KEVIN-WORK` or represented by a sanitized published runtime receipt before the agent calls it complete. **Local-only work is unfinished work.**
5. A desktop-local agent such as Grokbot may test locally, but it may not leave the only copy of source, configuration intent, repair logic, or proof on HESS-PC. Before moving on, it must publish the durable source/evidence checkpoint to the shared repository.
6. Before editing shared state, pull/re-read current `main`; use a branch for source changes; reconcile before merge; never overwrite an outstanding newer request or another active writer's work.
7. If a session/token/credit limit can end without warning, checkpoint **after every substantive proof transition or material repair**, not only at the end of a conversation.
8. Never publish passwords, tokens, OAuth material, private message bodies, credentials, recovery codes, or sensitive local data to this public repository.

## Automatic semantic snapshot

- Engineering evidence at checkpoint: `{eng_at}`
- Support evidence at checkpoint: `{sup_at}`
- Autonomy evidence at checkpoint: `{auto_at}`
- Benchmark: **{benchmark_status} — {benchmark_passed}/{benchmark_total}, critical {benchmark_critical}**
- UI Bridge health at checkpoint: **{ui_health(ui_age)}** (age then: {ui_age} seconds)
- Supervisor last result: **{supervisor_result}**
- Proven composite skills: **{proven_skills}**
- Installed Maintenance identity reported by Support: `{maintenance_sha}`

The builder runs after `main` changes and on a ten-minute reconciliation schedule, but it commits a new handover only when turnover-relevant semantic state changes. This prevents telemetry timestamps from continuously moving `main` underneath active engineering branches. Incoming agents still read the fresh runtime reports directly.

Do not interpret task/hash presence as health when a semantic heartbeat or round-trip proof is required.

## Current owner task / exact continuation

The block below is pulled from `inbox/CURRENT_TASK.md`. That file is an execution input, not a competing handover.

---

{task if task else '*CURRENT_TASK missing — stop mutating and repair continuity first.*'}

---

## Cross-AI local-work convergence contract

The shared GitHub repository is the rendezvous point between agents that can see different environments. Local runtime and GitHub source are two different truth planes:

- **Repository/source truth:** reviewed source, procedures, current task, PR/CI, public-safe receipts.
- **HESS-PC runtime truth:** installed hashes, scheduled tasks, live heartbeats, configuration state, UI outcomes and other machine-local evidence.

No agent may silently treat one plane as the other. When Grokbot changes HESS-PC, it must publish the corresponding source/evidence checkpoint. When a remote agent changes GitHub, it must not claim the production machine changed until HESS-PC independently reports the installed result. This rule is how we prevent invisible local work and false remote assumptions.

## Incoming-agent bootstrap

A replacement agent should do this, in order:

1. Read this file.
2. Read `KEVIN-START-HERE.md` and `inbox/CURRENT_TASK.md`.
3. Read fresh `reports/support-latest.json` and `reports/engineering/latest.json`; inspect relevant open PR/CI.
4. Compare timestamps, hashes, proof level and in-flight requests. Treat stale prose as stale.
5. Continue the highest-value safe next action; do not restart the project, recreate old fixes, or ask Matt to relay information already present in the shared repository.
6. After a substantive change, update the execution input/evidence so the automatic handover builder produces the next semantic checkpoint.

## Proof and authority

Technical proof ladder:

`DESIGNED -> CI-PROVEN -> INSTALLABLE THROUGH TYPED PATH -> INSTALLED -> OMEN-PROVEN -> ROUND-TRIP-PROVEN -> REPEATEDLY-PROVEN -> SELF-RELIANT`

Responsibility transfer:

`T0 BESS-DEPENDENT -> T1 BESS-BUILT/KEVIN-TESTED -> T2 BESS-DISPATCHED/KEVIN-EXECUTED -> T3 KEVIN-RUN/BESS-VERIFIED -> T4 KEVIN-OWNED/EXCEPTION-ESCALATED -> T5 SELF-RELIANT/BESS-NOT-REQUIRED`

Never infer a higher state from a lower one. Never widen authority merely to make turnover easier.

## Generator integrity

This handover is generated by `.github/scripts/build-canonical-handover.py` and reconciled by `.github/workflows/canonical-handover.yml`. The generator is semantic and change-driven: raw heartbeat/report timestamp churn does not create handover commits, while current-task and turnover-relevant state changes do.

Semantic fingerprint: `{source_fingerprint}`

**Fresh runtime evidence first; one handover; publish every durable local change; then continue.**
"""

    HANDOVER_MD.write_text(md, encoding="utf-8", newline="\n")
    HANDOVER_JSON.parent.mkdir(parents=True, exist_ok=True)
    HANDOVER_JSON.write_text(json.dumps(twin, indent=2, sort_keys=False) + "\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
