import copy, unittest
from datetime import datetime
from validate_handoff_envelope_v2 import validate

NOW=datetime.fromisoformat("2026-08-30T02:30:00-06:00")
BASE={
 "mission_id":"handoff-v2","stage_id":"review","owner":"Builder","next_owner":"Reviewer",
 "input_refs":["checkpoint:abc"],"artifact_refs":["artifact:candidate-report"],
 "source_refs":[{"source_id":"src-1","kind":"repo","fingerprint":"A"*64}],
 "trust_level":"CORROBORATED",
 "technical_success":True,"semantic_success":True,
 "claims":[{"claim":"candidate contract validated","consequential":True,"evidence_grade":"A","source_ids":["src-1"]}],
 "assumptions":[],"unknowns":[],
 "freshness":{"evaluated_at":"2026-08-30T01:00:00-06:00","stale_after":"2026-08-31T01:00:00-06:00","freshness_required":True},
 "output_schema_version":"2","budget":{"calls_used":1,"calls_limit":6,"seconds_used":30,"seconds_limit":900},
 "approval_class":"YELLOW","checkpoint_ref":"checkpoint:abc","rejection_reason":""
}

class Tests(unittest.TestCase):
 def ok(self,x): return validate(x,NOW)
 def test_valid(self): self.assertTrue(self.ok(copy.deepcopy(BASE)))
 def test_technical_success_not_enough(self):
  x=copy.deepcopy(BASE);x["semantic_success"]=False;x["rejection_reason"]="irrelevant_output"
  self.assertTrue(self.ok(x))
 def test_semantic_requires_technical(self):
  x=copy.deepcopy(BASE);x["technical_success"]=False
  with self.assertRaises(ValueError): self.ok(x)
 def test_consequential_claim_requires_source(self):
  x=copy.deepcopy(BASE);x["claims"][0]["source_ids"]=[]
  with self.assertRaises(ValueError): self.ok(x)
 def test_unknown_source_rejected(self):
  x=copy.deepcopy(BASE);x["claims"][0]["source_ids"]=["missing"]
  with self.assertRaises(ValueError): self.ok(x)
 def test_unverified_consequential_rejected(self):
  x=copy.deepcopy(BASE);x["claims"][0]["evidence_grade"]="UNVERIFIED"
  with self.assertRaises(ValueError): self.ok(x)
 def test_stale_semantic_output_rejected_at_replay_time(self):
  x=copy.deepcopy(BASE);x["freshness"]["stale_after"]="2026-08-30T02:00:00-06:00"
  with self.assertRaisesRegex(ValueError,"stale_semantic_output"): self.ok(x)
 def test_freshness_requires_stale_after(self):
  x=copy.deepcopy(BASE);x["freshness"]["stale_after"]=""
  with self.assertRaises(ValueError): self.ok(x)
 def test_future_evaluated_at_rejected(self):
  x=copy.deepcopy(BASE);x["freshness"]["evaluated_at"]="2026-08-30T03:00:00-06:00"
  with self.assertRaisesRegex(ValueError,"evaluated_at_in_future"): self.ok(x)
 def test_budget_exceeded(self):
  x=copy.deepcopy(BASE);x["budget"]["calls_used"]=7
  with self.assertRaises(ValueError): self.ok(x)
 def test_failed_semantic_requires_reason(self):
  x=copy.deepcopy(BASE);x["semantic_success"]=False
  with self.assertRaises(ValueError): self.ok(x)
 def test_success_cannot_carry_rejection(self):
  x=copy.deepcopy(BASE);x["rejection_reason"]="should_not_be_here"
  with self.assertRaises(ValueError): self.ok(x)
 def test_raw_cannot_claim_semantic_success(self):
  x=copy.deepcopy(BASE);x["trust_level"]="RAW"
  with self.assertRaisesRegex(ValueError,"semantic_success_requires"): self.ok(x)
 def test_parsed_cannot_claim_semantic_success(self):
  x=copy.deepcopy(BASE);x["trust_level"]="PARSED"
  with self.assertRaisesRegex(ValueError,"semantic_success_requires"): self.ok(x)
 def test_missing_artifact_ref_rejected(self):
  x=copy.deepcopy(BASE);x["artifact_refs"]=[]
  with self.assertRaisesRegex(ValueError,"artifact_refs"): self.ok(x)
 def test_bad_source_fingerprint_rejected(self):
  x=copy.deepcopy(BASE);x["source_refs"][0]["fingerprint"]="bad"
  with self.assertRaisesRegex(ValueError,"source_fingerprint"): self.ok(x)
 def test_duplicate_source_id_rejected(self):
  x=copy.deepcopy(BASE);x["source_refs"].append(copy.deepcopy(x["source_refs"][0]))
  with self.assertRaisesRegex(ValueError,"source_id"): self.ok(x)
 def test_unknown_field_rejected(self):
  x=copy.deepcopy(BASE);x["authority_override"]=True
  with self.assertRaises(ValueError): self.ok(x)

if __name__=="__main__": unittest.main()
