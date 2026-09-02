import unittest
from classifier import PolicyError, classify


def cfg():
    return {
        "agents": {
            "defaults": {"model": {"primary": "ollama-chat-16k/qwen2.5:14b"}},
            "list": [{"id": "main", "tools": {}}],
        },
        "tools": {},
    }


class Tests(unittest.TestCase):
    def test_empty_policy(self):
        out = classify(cfg())
        self.assertEqual(out["installed_schema_contract"], "agents.list")
        self.assertEqual(out["main_entry_count"], 1)
        self.assertEqual(out["model_family"], "QWEN2_5")
        self.assertEqual(out["root"]["allow_count"], 0)
        self.assertFalse(out["risk_flags"]["protected_explicit_allow"])

    def test_narrow_goal_allow(self):
        x = cfg(); x["agents"]["list"][0]["tools"] = {"allow": ["get_goal", "create_goal", "update_goal"]}
        out = classify(x)
        self.assertEqual(out["main"]["allow_count"], 3)
        self.assertEqual(out["main"]["protected_explicitly_allowed"], [])
        self.assertIn("get_goal", out["main"]["known_control_allowed"])

    def test_protected_allow_flagged(self):
        x = cfg(); x["agents"]["list"][0]["tools"] = {"allow": ["get_goal", "exec"]}
        out = classify(x)
        self.assertTrue(out["risk_flags"]["protected_explicit_allow"])
        self.assertEqual(out["main"]["protected_explicitly_allowed"], ["exec"])

    def test_coding_profile_flagged(self):
        x = cfg(); x["tools"] = {"profile": "coding"}
        self.assertTrue(classify(x)["risk_flags"]["broad_root_profile"])

    def test_deny_recorded(self):
        x = cfg(); x["agents"]["list"][0]["tools"] = {"deny": ["exec", "write", "process"]}
        out = classify(x)
        self.assertEqual(out["main"]["protected_explicitly_denied"], ["exec", "process", "write"])

    def test_provider_layer(self):
        x = cfg(); x["tools"] = {"byProvider": {"ollama-chat-16k": {"allow": ["get_goal"]}}}
        self.assertEqual(classify(x)["root_provider"]["allow_count"], 1)

    def test_model_policy_precedes_provider(self):
        x = cfg(); x["tools"] = {"byProvider": {
            "ollama-chat-16k": {"allow": ["exec"]},
            "ollama-chat-16k/qwen2.5:14b": {"deny": ["exec"]},
        }}
        out = classify(x)["root_provider"]
        self.assertEqual(out["allow_count"], 0)
        self.assertEqual(out["protected_explicitly_denied"], ["exec"])

    def test_unknown_sandbox_values_not_published(self):
        x = cfg(); x["agents"]["list"][0]["sandbox"] = {
            "mode": "private-fixture", "workspaceAccess": "private-fixture"}
        out = classify(x)
        self.assertNotIn("private-fixture", str(out))
        self.assertEqual(out["sandbox"]["mode"], "OTHER")

    def test_malformed_scope_is_not_empty_policy(self):
        for value in ["", "exec", 42, [], True]:
            with self.subTest(value=value):
                x = cfg(); x["tools"] = value
                with self.assertRaises(PolicyError): classify(x)

    def test_reject_allow_plus_also_allow(self):
        x = cfg(); x["tools"] = {"allow": ["get_goal"], "alsoAllow": ["session_status"]}
        with self.assertRaises(PolicyError): classify(x)

    def test_reject_multiple_main_entries(self):
        x = cfg(); x["agents"]["list"].append({"id": "main"})
        with self.assertRaises(PolicyError): classify(x)

    def test_reject_wrong_agents_list_type(self):
        x = cfg(); x["agents"]["list"] = {}
        with self.assertRaises(PolicyError): classify(x)

    def test_values_not_published(self):
        x = cfg(); x["agents"]["list"][0]["tools"] = {"allow": ["secret-custom-name"]}
        out = classify(x)
        self.assertNotIn("secret-custom-name", str(out))
        self.assertEqual(out["main"]["allow_count"], 1)


if __name__ == "__main__": unittest.main()
