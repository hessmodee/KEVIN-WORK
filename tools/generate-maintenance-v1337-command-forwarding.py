"""Repair the reproduced PowerShell command-forwarding defects, not OpenClaw."""
from pathlib import Path
import hashlib
import re


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def read_pinned(path: str, expected: str) -> str:
    data = Path(path).read_bytes()
    if sha(data) != expected:
        raise SystemExit(f"source identity mismatch: {path}: {sha(data)}")
    return data.decode("utf-8")


supervisor = read_pinned(
    "control-plane/autonomy/kevin-supervisor-v1.8.4.ps1",
    "BBE4F4947E5D5BEFCBB82890F63EE4A68C0F39375A627F311036EDBB78665940",
)
supervisor = supervisor.replace("v1.8.4", "v1.8.5").replace("version = '1.8.4'", "version = '1.8.5'")
supervisor = re.sub(r"\$args\b", "$CommandArguments", supervisor, flags=re.I)
supervisor = re.sub(r"@args\b", "@CommandArguments", supervisor, flags=re.I)
sup_path = Path("control-plane/autonomy/kevin-supervisor-v1.8.5.ps1")
sup_path.write_text(supervisor, encoding="utf-8", newline="")
sup_sha = sha(sup_path.read_bytes())

text = read_pinned(
    "control-plane/maintenance/kevin-maintenance-runner-v1.3.35.ps1",
    "868D7E1726A47C12AF58C8A4060CC641F4F066885BF5D79550D8F9A4DA6E3A45",
)


def once(old: str, new: str) -> None:
    global text
    if text.count(old) != 1:
        raise SystemExit(f"unique anchor missing: {old[:90]}")
    text = text.replace(old, new, 1)


once("version='1.3.35'", "version='1.3.37'")
text = re.sub(r"\$args\b", "$CommandArguments", text, flags=re.I)
text = re.sub(r"@args\b", "@CommandArguments", text, flags=re.I)
once("$SupervisorV183Sha = 'BBE4F4947E5D5BEFCBB82890F63EE4A68C0F39375A627F311036EDBB78665940'", f"$SupervisorV183Sha = '{sup_sha}'")
text = text.replace("v1.8.4", "v1.8.5")
once(
    "    $probes=@(Invoke-OpenClawFixedConfig @('config','validate','--json'),Invoke-OpenClawFixedConfig @('gateway','status','--json'),Invoke-OpenClawFixedConfig @('plugins','doctor','--json'),Invoke-OpenClawFixedConfig @('doctor','--json'))",
    """    # Separate command expressions: comma-separated commands bind as arguments
    # to the first invocation in PowerShell. Every probe is strictly read-only.
    $probes=@(
        (Invoke-OpenClawFixedConfig @('config','validate','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','call','status','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','health','--json'))
    )
    if($probes.Count-ne4){throw 'fixed diagnostic must execute exactly four probes'}
    $allProbesOk=(@($probes|Where-Object{$_.exit_code-ne0}).Count-eq0)""",
)
once("$family=Get-GatewayFailureFamilyDetailed $text;$facts=", "$family=if($allProbesOk){'HEALTHY'}else{Get-GatewayFailureFamilyDetailed $text};$facts=")
once("root_cause_family=$family;probe_exit_codes=", "root_cause_family=$family;probe_count=$probes.Count;probe_names=@('config_validate','gateway_require_rpc','gateway_direct_rpc','gateway_health');all_probes_ok=$allProbesOk;command_forwarding_contract='v1.3.37';probe_exit_codes=")
once(
    "recommended_repair=$(if($version-eq$GatewayRejectedVersion){'TYPED_WINDOWS_LKG_RECOVERY'}else{'ROOT_CAUSE_SPECIFIC_REPAIR'})",
    "recommended_repair=$(if($allProbesOk){'NONE_ALL_PROBES_PASSED'}else{'CLASSIFY_FAILED_PROBE_BEFORE_REPAIR'})",
)
once(
    "source_contract='Four fixed OpenClaw probes plus fixed package/config/backup/Gateway topology metadata. No caller-selected command/path/argv.'",
    "source_contract='Four separately invoked read-only config/RPC/health probes with verified command forwarding plus fixed package/config/backup/Gateway topology metadata. No doctor repair, version mutation, or caller-selected command/path/argv.'",
)
anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.35 SELFTEST PASS safe_report_publish=bounded3 create_update_race=true remote_hash_verify=true continuation_cli=cron_alias backoff_reset=true arbitrary_shell=false authority_expansion=false'\n"
once(anchor, anchor + """    foreach($fn in @('Invoke-OpenClawFixedConfig','Invoke-ReaderOpenClaw','Invoke-NpmFixed')){
        if((Get-Command $fn).Parameters.ContainsKey('Args')){throw 'automatic Args parameter must never be used for fixed command forwarding'}
        if(-not(Get-Command $fn).Parameters.ContainsKey('CommandArguments')){throw 'explicit command argument parameter missing'}
    }
    Write-Host 'KEVIN MAINTENANCE v1.3.37 SELFTEST PASS explicit_command_arguments=true four_independent_readonly_probes=true version_change_not_implied=true supervisor_target=v1.8.5 authority_expansion=false'
"""
)

out = Path("control-plane/maintenance/kevin-maintenance-runner-v1.3.37.ps1")
out.write_text(text, encoding="utf-8", newline="")
print(f"SUPERVISOR_V185_GENERATED sha256={sup_sha}")
print(f"MAINT_V1337_GENERATED sha256={sha(out.read_bytes())}")
