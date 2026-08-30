import copy, unittest
from build_green_maintenance_receipt import build_receipt, canonical_fingerprint
from verify_green_maintenance_receipt import verify

BASE={
 "receipt_id":"receipt-0001","idempotency_key":"idem-00000001","action":"run_benchmark","target":"kevin-benchmark-v1","authority_class":"GREEN",
 "started_at":"2026-08-30T04:00:00-06:00","finished_at":"2026-08-30T04:00:10-06:00","precondition":{"governance_ok":True,"benchmark_status":"PASS"},
 "postcondition_check":"latest benchmark run terminal status","postcondition_observed":"PASS 30/30","postcondition_verified":True,
 "evidence":["reports/support-latest.json#benchmark"],"result":"PASS","rollback_available":False,"rollback_performed":False,"rollback_evidence":""
}

class ReceiptBindingTests(unittest.TestCase):
 def test_read_only_pass_binds_and_verifies(self):
  r=build_receipt(copy.deepcopy(BASE)); self.assertEqual([],verify(r)); self.assertFalse(r['rollback']['required'])
 def test_fingerprint_is_canonical(self):
  self.assertEqual(canonical_fingerprint({'b':2,'a':1}),canonical_fingerprint({'a':1,'b':2}))
 def test_mutable_action_requires_rollback(self):
  x=copy.deepcopy(BASE); x['action']='enable_expected_automation'; x['target']='kevin-support-bridge-v1'
  with self.assertRaisesRegex(ValueError,'rollback availability'): build_receipt(x)
 def test_mutable_action_pass_with_rollback_available(self):
  x=copy.deepcopy(BASE); x['action']='enable_expected_automation'; x['target']='kevin-support-bridge-v1'; x['rollback_available']=True
  r=build_receipt(x); self.assertTrue(r['rollback']['required']); self.assertEqual([],verify(r))
 def test_pass_without_postcondition_blocked(self):
  x=copy.deepcopy(BASE); x['postcondition_verified']=False
  with self.assertRaisesRegex(ValueError,'verified postcondition'): build_receipt(x)
 def test_fail_cannot_claim_verified(self):
  x=copy.deepcopy(BASE); x['result']='FAIL'
  with self.assertRaisesRegex(ValueError,'cannot claim'): build_receipt(x)
 def test_rolled_back_requires_performed_and_evidence(self):
  x=copy.deepcopy(BASE); x['action']='enable_expected_automation'; x['target']='x'; x['rollback_available']=True; x['result']='ROLLED_BACK'; x['postcondition_verified']=False
  with self.assertRaisesRegex(ValueError,'performed rollback'): build_receipt(x)
  x['rollback_performed']=True
  with self.assertRaisesRegex(ValueError,'requires evidence'): build_receipt(x)
  x['rollback_evidence']='restored prior enabled=false'; r=build_receipt(x); self.assertEqual([],verify(r))
 def test_non_green_rejected(self):
  x=copy.deepcopy(BASE); x['authority_class']='YELLOW'
  with self.assertRaisesRegex(ValueError,'GREEN'): build_receipt(x)
 def test_unknown_action_rejected(self):
  x=copy.deepcopy(BASE); x['action']='run_shell'
  with self.assertRaisesRegex(ValueError,'allowlisted'): build_receipt(x)
 def test_extra_field_rejected(self):
  x=copy.deepcopy(BASE); x['command']='powershell.exe'
  with self.assertRaisesRegex(ValueError,'fields mismatch'): build_receipt(x)

if __name__=='__main__': unittest.main()
