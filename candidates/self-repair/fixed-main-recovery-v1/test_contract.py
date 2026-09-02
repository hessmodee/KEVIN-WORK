import copy
import unittest

from contract import (
    ContractError,
    assert_only_known_repair_diff,
    build_known_repair_intents,
    classify_main_config,
    classify_tool_policy_surfaces,
    semantic_leaf_diff,
)


def base_config():
    return {
        "meta": {"lastTouchedAt": "before", "lastTouchedVersion": "2026.7.1-2"},
        "agents": {
            "defaults": {
                "model": {"primary": "ollama-chat-16k/qwen2.5:14b"},
                "compaction": {"reserveTokensFloor": 2048},
            },
            "entries": {"main": {"id": "main"}},
        },
        "models": {
            "providers": {
                "ollama-chat-16k": {
                    "models": [
                        {
                            "id": "qwen2.5:14b",
                            "contextTokens": 16384,
                            "params": {"num_ctx": 16384},
                        }
                    ]
                }
            }
        },
        "tools": {"profile": "coding", "allow": [], "deny": ["exec", "process"]},
    }


class FixedMainContractTests(unittest.TestCase):
    def test_missing_known_values_produces_two_exact_intents(self):
        cfg = base_config()
        state = classify_main_config(cfg)["classification"]
        self.assertTrue(state["safe_exact_repair"])
        self.assertTrue(state["repair_needed"])
        intents = build_known_repair_intents(cfg)
        self.assertEqual(
            [i["path"] for i in intents],
            [
                "agents.defaults.compaction.reserveTokens",
                "agents.defaults.compaction.keepRecentTokens",
            ],
        )
        self.assertTrue(all(i["dry_run_first"] for i in intents))

    def test_exact_post_repair_is_idempotent(self):
        cfg = base_config()
        c = cfg["agents"]["defaults"]["compaction"]
        c["reserveTokens"] = 2048
        c["keepRecentTokens"] = 4000
        state = classify_main_config(cfg)["classification"]
        self.assertTrue(state["safe_exact_repair"])
        self.assertFalse(state["repair_needed"])
        self.assertEqual(build_known_repair_intents(cfg), [])

    def test_unknown_reserve_value_fails_closed(self):
        cfg = base_config()
        cfg["agents"]["defaults"]["compaction"]["reserveTokens"] = 9999
        state = classify_main_config(cfg)["classification"]
        self.assertFalse(state["safe_exact_repair"])
        self.assertIn("reserve_tokens", state["unknown_drift"])
        with self.assertRaises(ContractError):
            build_known_repair_intents(cfg)

    def test_wrong_model_context_fails_closed(self):
        cfg = base_config()
        cfg["models"]["providers"]["ollama-chat-16k"]["models"][0]["contextTokens"] = 8192
        state = classify_main_config(cfg)["classification"]
        self.assertFalse(state["safe_exact_repair"])
        self.assertIn("context_tokens", state["unknown_drift"])

    def test_only_known_leaf_additions_are_accepted(self):
        before = base_config()
        after = copy.deepcopy(before)
        after["meta"]["lastTouchedAt"] = "after"
        c = after["agents"]["defaults"]["compaction"]
        c["reserveTokens"] = 2048
        c["keepRecentTokens"] = 4000
        changes = assert_only_known_repair_diff(before, after)
        self.assertEqual(
            [x["path"] for x in changes],
            [
                "$.agents.defaults.compaction.keepRecentTokens",
                "$.agents.defaults.compaction.reserveTokens",
            ],
        )

    def test_unrelated_semantic_change_is_rejected(self):
        before = base_config()
        after = copy.deepcopy(before)
        c = after["agents"]["defaults"]["compaction"]
        c["reserveTokens"] = 2048
        c["keepRecentTokens"] = 4000
        after["agents"]["defaults"]["model"]["primary"] = "other/model"
        self.assertTrue(any(x["path"].endswith("model.primary") for x in semantic_leaf_diff(before, after)))
        with self.assertRaises(ContractError):
            assert_only_known_repair_diff(before, after)

    def test_change_existing_known_value_is_rejected(self):
        before = base_config()
        c = before["agents"]["defaults"]["compaction"]
        c["reserveTokens"] = 1024
        c["keepRecentTokens"] = 4000
        after = copy.deepcopy(before)
        after["agents"]["defaults"]["compaction"]["reserveTokens"] = 2048
        with self.assertRaises(ContractError):
            assert_only_known_repair_diff(before, after)

    def test_tool_policy_classification_never_claims_effective_inventory(self):
        cfg = base_config()
        result = classify_tool_policy_surfaces(cfg)
        self.assertEqual(result["root"]["profile"], "coding")
        self.assertEqual(result["root"]["deny_count"], 2)
        self.assertFalse(result["main"]["present"])
        self.assertIn("tools.effective", result["truth_boundary"])

    def test_allow_plus_also_allow_invalid_same_scope(self):
        cfg = base_config()
        cfg["tools"]["allow"] = ["session_status"]
        cfg["tools"]["alsoAllow"] = ["get_goal"]
        with self.assertRaises(ContractError):
            classify_tool_policy_surfaces(cfg)

    def test_duplicate_main_entries_rejected(self):
        cfg = base_config()
        cfg["agents"].pop("entries")
        cfg["agents"]["list"] = [{"id": "main"}, {"id": "main"}]
        with self.assertRaises(ContractError):
            classify_main_config(cfg)


if __name__ == "__main__":
    unittest.main()
