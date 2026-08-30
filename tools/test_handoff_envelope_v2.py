import copy, unittest
from validate_handoff_envelope_v2 import validate

BASE={
 "mission_id":"handoff-v2","stage_id":"review","owner":"Builder","next_owner":"Reviewer",
 "input_refs":["checkpoint:abc"],
 "source_refs":[{"source_id":"src-1","kind":"repo","fingerprint":"A"*64}],
 "technical_success":True,"semantic_success":True,
 "claims":[{"claim":"candidate contract validated","consequential":True,"evidence_grade":"A","source_ids":["src-1"]}],
 "assumptions":[],"unknowns":[],
 "freshness":{"evaluated_at":"2026-08-30T01:00:00-06:00","stale_after":"2026-08-31T01:00:00-06:00","freshness_required":True},
 "output_schema_version":"2","budget":{"calls_used":1,"calls_limit":6,"seconds_used":30,"seconds_limit":900},
 "approval_class":"YELLOW","checkpoint_ref":"checkpoint:abc","rejection_reason":""
}

class Tests(unittest.TestCase):
 def test_valid(self): self.assertTrue(validate(copy.deepcopy(BASE)))
 def test_technical_success_not_enough(self):
  x=copy.deepcopy(BASE);x["semantic_success"]=False;x["rejection_reason"]="irrelevant_output"
  self.assertTrue(validate(x))
 def test_semantic_requires_technical(self):
  x=copy.deepcopy(BASE);x["technical_success"]=False
  with self.assertRaises(ValueError): validate(x)
 def test_consequential_claim_requires_source(self):
  x=copy.deepcopy(BASE);x["claims"][0]["source_ids"]=[]
  with self.assertRaises(ValueError): validate(x)
 def test_unknown_source_rejected(self):
  x=copy.deepcopy(BASE);x["claims"][0]["source_ids"]=["missing"]
  with self.assertRaises(ValueError): validate(x)
 def test_unverified_consequential_rejected(self):
  x=copy.deepcopy(BASE);x["claims"][0]["evidence_grade"]="UNVERIFIED"
  with self.assertRaises(ValueError): validate(x)
 def test_stale_semantic_output_rejected(self):
  x=copy.deepcopy(BASE);x["freshness"]["stale_after"]="2026-08-30T00:00:00-06:00"
  with self.assertRaises(ValueError): validate(x)
 def test_freshness_requires_stale_after(self):
  x=copy.deepcopy(BASE);x["freshness"]["stale_after"]=""
  with self.assertRaises(ValueError): validate(x)
 def test_budget_exceeded(self):
  x=copy.deepcopy(BASE);x["budget"]["calls_used"]=7
  with self.assertRaises(ValueError): validate(x)
 def test_failed_semantic_requires_reason(self):
  x=copy.deepcopy(BASE);x["semantic_success"]=False
  with self.assertRaises(ValueError): validate(x)
 def test_success_cannot_carry_rejection(self):
  x=copy.deepcopy(BASE);x["rejection_reason"]="should_not_be_here"
  with self.assertRaises(ValueError): validate(x)
 def test_unknown_field_rejected(self):
  x=copy.deepcopy(BASE);x["authority_override"]=True
  with self.assertRaises(ValueError): validate(x)

if __name__=="__main__": unittest.main()
