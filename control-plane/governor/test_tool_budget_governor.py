import unittest
from tool_budget_governor import evaluate, apply

def base():
    return {
      "mission_id":"m1","tool":"repo_read","effect":"read","target_id":"x","operation_id":"op1",
      "expected_utility":5,"latency_cost":2,"risk":"low","retry_count":0,
      "budget":{"tool_calls_remaining":4,"model_turns_remaining":2,"elapsed_seconds_remaining":20,"external_cost_cents_remaining":0},
      "progress_token":"p1"
    }

class T(unittest.TestCase):
    def test_allow(self): self.assertTrue(evaluate(base(),{}).allow)
    def test_unknown_tool(self):
        c=base(); c["tool"]="shell"; self.assertFalse(evaluate(c,{}).allow)
    def test_effect(self):
        c=base(); c["effect"]="production_write"; self.assertFalse(evaluate(c,{}).allow)
    def test_retry_ceiling(self):
        c=base(); c["retry_count"]=3; self.assertEqual(evaluate(c,{}).reason,"failure_family_cooled")
    def test_duplicate(self):
        c=base(); d=evaluate(c,{}); s=apply(d,c,{})
        self.assertEqual(evaluate(c,s).reason,"duplicate_call")
    def test_no_progress(self):
        c=base(); s={"seen_progress_tokens":["p1"]}; self.assertEqual(evaluate(c,s).reason,"no_semantic_progress")
    def test_write_idempotency(self):
        c=base(); c["effect"]="write_candidate"; c["tool"]="candidate_write"
        self.assertEqual(evaluate(c,{}).reason,"write_requires_idempotency_key")
    def test_write_with_idempotency(self):
        c=base(); c["effect"]="write_candidate"; c["tool"]="candidate_write"; c["idempotency_key"]="i1"
        self.assertTrue(evaluate(c,{}).allow)
    def test_tool_budget(self):
        c=base(); c["budget"]["tool_calls_remaining"]=0
        self.assertEqual(evaluate(c,{}).reason,"tool_budget_exhausted")
    def test_model_budget(self):
        c=base(); c["tool"]="benchmark"; c["budget"]["model_turns_remaining"]=0
        self.assertEqual(evaluate(c,{}).reason,"model_budget_exhausted")
    def test_time_budget(self):
        c=base(); c["budget"]["elapsed_seconds_remaining"]=2
        self.assertEqual(evaluate(c,{}).reason,"time_budget_exhausted")
    def test_authority_injection(self):
        c=base(); c["authority_override"]="RED"
        self.assertTrue(evaluate(c,{}).reason.startswith("unknown_fields:"))
    def test_negative_budget(self):
        c=base(); c["budget"]["external_cost_cents_remaining"]=-1
        self.assertEqual(evaluate(c,{}).reason,"budget_negative:external_cost_cents_remaining")
    def test_nonpositive_utility(self):
        c=base(); c["expected_utility"]=0
        self.assertEqual(evaluate(c,{}).reason,"nonpositive_expected_utility")

if __name__=="__main__": unittest.main()
