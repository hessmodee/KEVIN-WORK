import unittest
from contract import (
    ContractError,
    DESKTOP_TOOLS,
    DESKTOP_TOOLS_V0_1,
    DESKTOP_TOOLS_V0_2,
    validate_request,
)

BENCH={"status":"PASS","passed":30,"total":30,"critical":0}

def desktop():
    return {
      "schema":2,"kind":"kevin-production-crossing-request","id":"desktop-proof-001",
      "authority_class":"YELLOW","operation":"install_kevin_desktop_v0_1","requires_owner_approval":True,
      "preconditions":{
        "source_contract":"docs/engineering/KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md",
        "plugin_id":"kevin-desktop","requested_tools":list(DESKTOP_TOOLS),
        "fixed_main_tools_before":0,"benchmark":dict(BENCH),"rollback_required":True
      }
    }

def list_folder():
    return {
      "schema":2,"kind":"kevin-production-crossing-request","id":"desktop-list-folder-001",
      "authority_class":"YELLOW","operation":"install_kevin_desktop_list_folder_v0_2",
      "requires_owner_approval":True,
      "preconditions":{
        "source_contract":"docs/engineering/KEVIN-DESKTOP-LIST-FOLDER-CROSSING-CONTRACT-2026-09-04.md",
        "plugin_id":"kevin-desktop","plugin_version":"0.2.0",
        "requested_tools":list(DESKTOP_TOOLS_V0_2),
        "fixed_main_tools_before":list(DESKTOP_TOOLS_V0_1),
        "benchmark":dict(BENCH),"rollback_required":True
      }
    }

class ContractTests(unittest.TestCase):
    def test_desktop_happy(self):
        p=validate_request(desktop())
        self.assertEqual(p["exact_expected_tools"],list(DESKTOP_TOOLS))
        self.assertEqual(p["authority_delta"],"NONE")

    def test_list_folder_happy(self):
        p=validate_request(list_folder())
        self.assertEqual(p["exact_expected_tools"],list(DESKTOP_TOOLS_V0_2))
        self.assertEqual(p["exact_before_tools"],list(DESKTOP_TOOLS_V0_1))
        self.assertEqual(p["operation"],"install_kevin_desktop_list_folder_v0_2")

    def test_task_happy(self):
        r={"schema":2,"kind":"kevin-production-crossing-request","id":"nightforge-001",
           "authority_class":"YELLOW","operation":"retire_legacy_kevin_night_forge","requires_owner_approval":True,
           "preconditions":{"task_name":"KevinNightForge","replacement_scheduler_proven":True,
                            "benchmark":dict(BENCH),"rollback_required":True}}
        self.assertEqual(validate_request(r)["exact_task_name"],"KevinNightForge")

    def test_reject_extra_tool(self):
        r=desktop(); r["preconditions"]["requested_tools"].append("shell")
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_list_folder_without_exact4_before(self):
        r=list_folder(); r["preconditions"]["fixed_main_tools_before"]=0
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_list_folder_shell_widen(self):
        r=list_folder(); r["preconditions"]["requested_tools"]=list(DESKTOP_TOOLS_V0_2)+["kevin_shell"]
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_reordered_or_missing_tools(self):
        r=desktop(); r["preconditions"]["requested_tools"]=r["preconditions"]["requested_tools"][:-1]
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_green_auto_apply(self):
        r=desktop(); r["authority_class"]="GREEN"
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_no_owner_gate(self):
        r=desktop(); r["requires_owner_approval"]=False
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_benchmark_drift(self):
        r=desktop(); r["preconditions"]["benchmark"]["passed"]=29
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_other_task(self):
        r={"schema":2,"kind":"kevin-production-crossing-request","id":"task-evil-001",
           "authority_class":"YELLOW","operation":"retire_legacy_kevin_night_forge","requires_owner_approval":True,
           "preconditions":{"task_name":"SomeOtherTask","replacement_scheduler_proven":True,
                            "benchmark":dict(BENCH),"rollback_required":True}}
        with self.assertRaises(ContractError): validate_request(r)

    def test_reject_unknown_fields(self):
        r=desktop(); r["command"]="powershell.exe"
        with self.assertRaises(ContractError): validate_request(r)

if __name__=="__main__":
    unittest.main()
