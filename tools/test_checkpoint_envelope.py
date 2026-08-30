import copy, unittest
from validate_checkpoint_envelope import validate

BASE={
 "mission_id":"checkpoint-resume","run_id":"run-001","stage":"review","updated_at":"2026-08-30T00:00:00-06:00",
 "input_fingerprint":"A"*64,"evidence_fingerprints":["B"*64],
 "budget":{"calls_used":2,"calls_limit":6,"seconds_used":120,"seconds_limit":900},
 "failure_family":"","failure_attempts":0,"next_action":"benchmark",
 "semantic_completion":{"criteria_met":False,"evidence_fingerprint":""},
 "operation_receipts":[{"idempotency_key":"op-1","operation":"candidate-build","target":"isolated","result_fingerprint":"C"*64}],
 "worker_slot":"14b-primary"
}

class Tests(unittest.TestCase):
 def test_valid(self): self.assertTrue(validate(copy.deepcopy(BASE)))
 def test_single_worker_slot(self):
  x=copy.deepcopy(BASE);x["worker_slot"]="14b-secondary"
  with self.assertRaises(ValueError): validate(x)
 def test_three_failure_ceiling(self):
  x=copy.deepcopy(BASE);x["failure_attempts"]=4;x["failure_family"]="review-contract"
  with self.assertRaises(ValueError): validate(x)
 def test_failure_family_required(self):
  x=copy.deepcopy(BASE);x["failure_attempts"]=1
  with self.assertRaises(ValueError): validate(x)
 def test_budget_ceiling(self):
  x=copy.deepcopy(BASE);x["budget"]["calls_used"]=7
  with self.assertRaises(ValueError): validate(x)
 def test_replay_rejected(self):
  x=copy.deepcopy(BASE);x["operation_receipts"].append(copy.deepcopy(x["operation_receipts"][0]))
  with self.assertRaises(ValueError): validate(x)
 def test_complete_requires_semantic_evidence(self):
  x=copy.deepcopy(BASE);x["stage"]="complete"
  with self.assertRaises(ValueError): validate(x)
 def test_complete_with_semantic_evidence(self):
  x=copy.deepcopy(BASE);x["stage"]="complete";x["semantic_completion"]={"criteria_met":True,"evidence_fingerprint":"D"*64}
  self.assertTrue(validate(x))
 def test_unknown_field_rejected(self):
  x=copy.deepcopy(BASE);x["authority_override"]=True
  with self.assertRaises(ValueError): validate(x)

if __name__=="__main__": unittest.main()
