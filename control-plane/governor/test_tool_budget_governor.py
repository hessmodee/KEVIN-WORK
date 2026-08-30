import unittest
from tool_budget_governor import evaluate, apply


def base():
    return {
      "mission_id":"m1","tool":"repo_read","effect":"read","target_id":"x","operation_id":"op1",
      "expected_utility":5,"latency_cost":2,"risk":"low","retry_count":0,
      "budget":{"tool_calls_remaining":4,"model_turns_remaining":2,"elapsed_seconds_remaining":20,"external_cost_cents_remaining":0},
      "progress_token":"p1"
    }


def next_call(state, **changes):
    c=base()
    c["operation_id"]="op2"
    c["target_id"]="y"
    c["progress_token"]="p2"
    c["budget"]={k:v for k,v in state["remaining_budget"].items()}
    c.update(changes)
    return c


class T(unittest.TestCase):
    def test_allow(self):
        self.assertTrue(evaluate(base(),{}).allow)

    def test_unknown_tool(self):
        c=base(); c["tool"]="shell"
        self.assertFalse(evaluate(c,{}).allow)

    def test_effect(self):
        c=base(); c["effect"]="production_write"
        self.assertFalse(evaluate(c,{}).allow)

    def test_budget_is_persistently_debited(self):
        c=base(); d=evaluate(c,{})
        s=apply(d,c,{})
        self.assertEqual(s["remaining_budget"]["tool_calls_remaining"],3)
        self.assertEqual(s["remaining_budget"]["elapsed_seconds_remaining"],18)

    def test_budget_reset_attempt_rejected(self):
        c=base(); s=apply(evaluate(c,{}),c,{})
        fresh=next_call(s)
        fresh["budget"]=base()["budget"]
        self.assertEqual(evaluate(fresh,s).reason,"budget_state_mismatch")

    def test_cumulative_tool_budget_exhausts(self):
        c=base(); c["budget"]["tool_calls_remaining"]=1
        s=apply(evaluate(c,{}),c,{})
        n=next_call(s)
        self.assertEqual(evaluate(n,s).reason,"tool_budget_exhausted")

    def test_benchmark_debits_model_turn(self):
        c=base(); c["tool"]="benchmark"; c["budget"]["model_turns_remaining"]=1
        s=apply(evaluate(c,{}),c,{})
        self.assertEqual(s["remaining_budget"]["model_turns_remaining"],0)

    def test_failure_family_three_attempt_ceiling_is_stateful(self):
        c=base(); c["failure_family"]="model_timeout"; c["dependency_fingerprint"]="dep1"
        s={}
        for attempt in range(3):
            c["retry_count"]=attempt
            c["operation_id"]=f"op{attempt}"
            c["target_id"]=f"t{attempt}"
            c["progress_token"]=f"p{attempt}"
            if s:
                c["budget"]={k:v for k,v in s["remaining_budget"].items()}
            d=evaluate(c,s)
            self.assertTrue(d.allow)
            s=apply(d,c,s)
        c["retry_count"]=3; c["operation_id"]="op4"; c["target_id"]="t4"; c["progress_token"]="p4"
        c["budget"]={k:v for k,v in s["remaining_budget"].items()}
        self.assertEqual(evaluate(c,s).reason,"failure_family_cooled")

    def test_retry_count_cannot_be_forged(self):
        c=base(); c["failure_family"]="model_timeout"; c["dependency_fingerprint"]="dep1"
        s=apply(evaluate(c,{}),c,{})
        n=next_call(s,failure_family="model_timeout",dependency_fingerprint="dep1",retry_count=0)
        self.assertEqual(evaluate(n,s).reason,"retry_state_mismatch")

    def test_dependency_change_gets_new_failure_family_key(self):
        c=base(); c["failure_family"]="model_timeout"; c["dependency_fingerprint"]="dep1"
        s=apply(evaluate(c,{}),c,{})
        n=next_call(s,failure_family="model_timeout",dependency_fingerprint="dep2",retry_count=0)
        self.assertTrue(evaluate(n,s).allow)

    def test_failure_family_requires_dependency_fingerprint(self):
        c=base(); c["failure_family"]="model_timeout"
        self.assertEqual(evaluate(c,{}).reason,"failure_family_requires_dependency_fingerprint")

    def test_duplicate_cannot_be_evaded_with_new_operation_id(self):
        c=base(); s=apply(evaluate(c,{}),c,{})
        n=base(); n["operation_id"]="different-op"; n["budget"]={k:v for k,v in s["remaining_budget"].items()}
        self.assertEqual(evaluate(n,s).reason,"duplicate_call")

    def test_no_progress(self):
        c=base(); s={"seen_progress_tokens":["p1"]}
        self.assertEqual(evaluate(c,s).reason,"no_semantic_progress")

    def test_write_idempotency(self):
        c=base(); c["effect"]="write_candidate"; c["tool"]="candidate_write"
        self.assertEqual(evaluate(c,{}).reason,"write_requires_idempotency_key")

    def test_idempotency_replay_rejected_across_changed_operation(self):
        c=base(); c["effect"]="write_candidate"; c["tool"]="candidate_write"; c["idempotency_key"]="i1"
        s=apply(evaluate(c,{}),c,{})
        n=next_call(s,effect="write_candidate",tool="candidate_write",idempotency_key="i1")
        self.assertEqual(evaluate(n,s).reason,"idempotency_replay")

    def test_new_idempotency_key_allowed(self):
        c=base(); c["effect"]="write_candidate"; c["tool"]="candidate_write"; c["idempotency_key"]="i1"
        s=apply(evaluate(c,{}),c,{})
        n=next_call(s,effect="write_candidate",tool="candidate_write",idempotency_key="i2")
        self.assertTrue(evaluate(n,s).allow)

    def test_tool_budget(self):
        c=base(); c["budget"]["tool_calls_remaining"]=0
        self.assertEqual(evaluate(c,{}).reason,"tool_budget_exhausted")

    def test_model_budget(self):
        c=base(); c["tool"]="benchmark"; c["budget"]["model_turns_remaining"]=0
        self.assertEqual(evaluate(c,{}).reason,"model_budget_exhausted")

    def test_time_budget_exact_fit_allowed(self):
        c=base(); c["budget"]["elapsed_seconds_remaining"]=2
        self.assertTrue(evaluate(c,{}).allow)

    def test_time_budget_underflow_rejected(self):
        c=base(); c["budget"]["elapsed_seconds_remaining"]=1
        self.assertEqual(evaluate(c,{}).reason,"time_budget_exhausted")

    def test_authority_injection(self):
        c=base(); c["authority_override"]="RED"
        self.assertTrue(evaluate(c,{}).reason.startswith("unknown_fields:"))

    def test_negative_budget(self):
        c=base(); c["budget"]["external_cost_cents_remaining"]=-1
        self.assertEqual(evaluate(c,{}).reason,"budget_negative:external_cost_cents_remaining")

    def test_unknown_budget_field_rejected(self):
        c=base(); c["budget"]["authority_budget"]=99
        self.assertEqual(evaluate(c,{}).reason,"budget_unknown:authority_budget")

    def test_nonpositive_utility(self):
        c=base(); c["expected_utility"]=0
        self.assertEqual(evaluate(c,{}).reason,"nonpositive_expected_utility")

    def test_negative_latency_rejected(self):
        c=base(); c["latency_cost"]=-1
        self.assertEqual(evaluate(c,{}).reason,"invalid_latency_cost")


if __name__=="__main__":
    unittest.main()
