import copy, unittest
from postmortem_validator import validate
H="a"*64
BASE={
"postmortem_id":"pm-001","mission_id":"m-001","failure_family":"handoff_stale",
"status":"COOLED","symptom":"handoff was stale at replay","root_cause":"consumer time was not checked",
"fix":"validate freshness at consumption time","prevention":"replay freshness adversarial test",
"evidence":[{"kind":"test","ref":"tests/replay","sha256":H}],"confidence":"MEDIUM",
"created_at":"2026-08-30T10:00:00Z","review_at":"2026-09-06T10:00:00Z",
"expires_at":"2026-10-01T10:00:00Z","attempts":3,"materially_distinct_failures":3,
"semantic_progress":False,"authority_class":"CANDIDATE_ONLY"
}
class T(unittest.TestCase):
    def ok(self,x): self.assertTrue(validate(x)[0],validate(x))
    def bad(self,x): self.assertFalse(validate(x)[0],validate(x))
    def test_valid_cooled(self): self.ok(copy.deepcopy(BASE))
    def test_unknown_field(self):
        x=copy.deepcopy(BASE); x["authority_override"]="GREEN"; self.bad(x)
    def test_authority(self):
        x=copy.deepcopy(BASE); x["authority_class"]="GREEN"; self.bad(x)
    def test_third_failure_must_cool(self):
        x=copy.deepcopy(BASE); x["status"]="OPEN"; self.bad(x)
    def test_resolved_needs_progress(self):
        x=copy.deepcopy(BASE); x["status"]="RESOLVED"; self.bad(x)
    def test_resolved_with_progress(self):
        x=copy.deepcopy(BASE); x["status"]="RESOLVED"; x["semantic_progress"]=True; self.ok(x)
    def test_high_conf_needs_two_evidence(self):
        x=copy.deepcopy(BASE); x["confidence"]="HIGH"; self.bad(x)
    def test_high_conf_two_evidence(self):
        x=copy.deepcopy(BASE); x["confidence"]="HIGH"; x["evidence"].append({"kind":"artifact","ref":"r2","sha256":"b"*64}); self.ok(x)
    def test_bad_sha(self):
        x=copy.deepcopy(BASE); x["evidence"][0]["sha256"]="abc"; self.bad(x)
    def test_review_after_created(self):
        x=copy.deepcopy(BASE); x["review_at"]=x["created_at"]; self.bad(x)
    def test_expiry_after_review(self):
        x=copy.deepcopy(BASE); x["expires_at"]="2026-09-01T00:00:00Z"; self.bad(x)
    def test_distinct_not_over_attempts(self):
        x=copy.deepcopy(BASE); x["attempts"]=2; self.bad(x)
    def test_evidence_required(self):
        x=copy.deepcopy(BASE); x["evidence"]=[]; self.bad(x)
    def test_shell_string_rejected(self):
        x=copy.deepcopy(BASE); x["fix"]="run remote_exec to repair"; self.bad(x)
if __name__=="__main__": unittest.main()
