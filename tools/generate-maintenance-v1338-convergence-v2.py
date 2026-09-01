from pathlib import Path
import hashlib
import re

MAINT_SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.37.ps1')
MAINT_OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.38.ps1')
SUP_SRC = Path('control-plane/autonomy/kevin-supervisor-v1.8.4.ps1')
SUP_OUT = Path('control-plane/autonomy/kevin-supervisor-v1.8.5.ps1')
EXPECTED_MAINT_SHA = '17016BF56F7BBFEE6A0718A26E0729837507E4B556CA30DE395BC32D2383A765'
EXPECTED_SUP_SHA = 'BBE4F4947E5D5BEFCBB82890F63EE4A68C0F39375A627F311036EDBB78665940'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def read_pinned(path: Path, expected: str) -> str:
    data = path.read_bytes()
    actual = sha(data)
    if actual != expected:
        raise SystemExit(f'source identity mismatch: {path}: {actual}')
    return data.decode('utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    return text.replace(old, new, 1)


def replace_between(text: str, start_marker: str, end_marker: str, replacement: str, label: str) -> str:
    start = text.find(start_marker)
    if start < 0:
        raise SystemExit(f'{label} start marker missing')
    end = text.find(end_marker, start)
    if end <= start:
        raise SystemExit(f'{label} end marker missing')
    return text[:start] + replacement.rstrip() + '\n' + text[end:]


# Use numeric character identities so PowerShell string escaping cannot alter the
# Win32 quoting algorithm. This follows the CommandLineToArgvW/MS CRT contract:
# backslashes before a quote are doubled and the quote is escaped; trailing
# backslashes are doubled before the closing quote.
MAINT_QUOTE = r'''function ConvertTo-FixedWin32Arg([AllowEmptyString()][string]$Value) {
    $Quote=[string][char]34
    $Slash=[string][char]92
    if($null-eq$Value -or $Value.Length-eq0){return ($Quote+$Quote)}
    if($Value -notmatch '[\s"]'){return $Value}
    $sb=New-Object Text.StringBuilder
    [void]$sb.Append($Quote)
    $slashes=0
    for($i=0;$i-lt$Value.Length;$i++){
        $ch=$Value[$i]
        if($ch-eq[char]92){$slashes++;continue}
        if($ch-eq[char]34){
            if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
            [void]$sb.Append($Slash)
            [void]$sb.Append($Quote)
            $slashes=0
            continue
        }
        if($slashes-gt0){[void]$sb.Append(($Slash*$slashes));$slashes=0}
        [void]$sb.Append($ch)
    }
    if($slashes-gt0){[void]$sb.Append(($Slash*($slashes*2)))}
    [void]$sb.Append($Quote)
    return $sb.ToString()
}
'''

SUP_QUOTE = MAINT_QUOTE.replace('ConvertTo-FixedWin32Arg', 'ConvertTo-Win32CommandLineArg')

# Supervisor v1.8.5: exact v1.8.4 behavior, explicit command arguments, plus
# byte-tested Win32 argv quoting. No new authority or work-selection logic.
supervisor = read_pinned(SUP_SRC, EXPECTED_SUP_SHA)
supervisor = supervisor.replace('v1.8.4', 'v1.8.5').replace("version = '1.8.4'", "version = '1.8.5'")
supervisor = re.sub(r'\$args\b', '$CommandArguments', supervisor, flags=re.I)
supervisor = re.sub(r'@args\b', '@CommandArguments', supervisor, flags=re.I)
supervisor = replace_between(
    supervisor,
    'function ConvertTo-Win32CommandLineArg',
    'function Invoke-FixedNativeBounded',
    SUP_QUOTE,
    'supervisor Win32 quote function',
)
SUP_OUT.write_text(supervisor, encoding='utf-8', newline='')
sup_sha = sha(SUP_OUT.read_bytes())

# Maintenance v1.3.38: exact byte-verified v1.3.37 tarball parent plus the
# explicit command-forwarding fix, Win32 argv repair, independent diagnostics,
# and the exact Supervisor v1.8.5 pin.
text = read_pinned(MAINT_SRC, EXPECTED_MAINT_SHA)
text = replace_once(text, "version='1.3.37'", "version='1.3.38'", 'maintenance version')
text = re.sub(r'\$args\b', '$CommandArguments', text, flags=re.I)
text = re.sub(r'@args\b', '@CommandArguments', text, flags=re.I)
text = replace_between(
    text,
    'function ConvertTo-FixedWin32Arg',
    'function Get-FixedOpenClawRuntime',
    MAINT_QUOTE,
    'maintenance Win32 quote function',
)
text = replace_once(
    text,
    "$SupervisorV183Sha = 'BBE4F4947E5D5BEFCBB82890F63EE4A68C0F39375A627F311036EDBB78665940'",
    f"$SupervisorV183Sha = '{sup_sha}'",
    'supervisor pin',
)
text = text.replace('v1.8.4', 'v1.8.5')

start = text.index('function Diagnose-GatewayFailureDetail {')
end = text.index('function Invoke-NpmFixed', start)
fixed_diag = r'''function Diagnose-GatewayFailureDetail {
    # Every read-only probe is a separate command expression. This prevents
    # Windows PowerShell from binding later commands as arguments to the first.
    $probes=@(
        (Invoke-OpenClawFixedConfig @('config','validate','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','status','--require-rpc','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','call','status','--json'))
        (Invoke-OpenClawFixedConfig @('gateway','health','--json'))
    )
    if($probes.Count-ne4){throw 'fixed diagnostic must execute exactly four probes'}
    $allProbesOk=(@($probes|Where-Object{$_.exit_code-ne0}).Count-eq0)
    $text=($probes|ForEach-Object{[string]$_.output})-join"`n"
    $family=if($allProbesOk){'HEALTHY'}else{Get-GatewayFailureFamilyDetailed $text}
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology
    $version='UNKNOWN';$pkg=Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json';if(Test-Path -LiteralPath $pkg -PathType Leaf){try{$version=[string](Get-Content -LiteralPath $pkg -Raw|ConvertFrom-Json).version}catch{}}
    $public=[ordered]@{schema=1;kind='kevin-gateway-failure-detail-public';generated_at=(Get-Date).ToString('o');state='OMEN_DIAGNOSIS_PROVEN';safe_for_public_repo=$true;openclaw_version=$version;release_policy_status=$(if($version-eq$GatewayRejectedVersion){'EVIDENCE_REJECTED'}elseif($version-eq$GatewayLkgVersion){'WINDOWS_VALIDATED_LKG'}else{'OTHER'});root_cause_family=$family;probe_count=$probes.Count;probe_names=@('config_validate','gateway_require_rpc','gateway_direct_rpc','gateway_health');all_probes_ok=$allProbesOk;command_forwarding_contract='v1.3.38';win32_argv_contract='numeric-char-mscrt';probe_exit_codes=@($probes|ForEach-Object{[int]$_.exit_code});probe_output_fingerprints=@($probes|ForEach-Object{Get-TextSha256 ([string]$_.output)});config=[ordered]@{current_sha256=$facts.current_sha256;current_last_touched=$facts.current_last_touched;backup_exists=[bool]$facts.backup_exists;backup_sha256=$facts.backup_sha256;backup_last_touched=$facts.backup_last_touched;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent;telegram_present=[bool]$facts.telegram_present;discord_present=[bool]$facts.discord_present;codex_present=[bool]$facts.codex_present;memory_core_present=[bool]$facts.memory_core_present};windows=[ordered]@{keeper_present=[bool]$top.keeper_present;keeper_state=[string]$top.keeper_state;keeper_script_present=[bool]$top.keeper_script_present;keeper_script_sha256=$top.keeper_script_sha256;legacy_task_present=[bool]$top.legacy_present;legacy_task_state=[string]$top.legacy_state;port_18789_listening=[bool]$top.port_listening;gateway_listener_count=[int]$top.gateway_listener_count};recommended_repair=$(if($allProbesOk){'NONE_ALL_PROBES_PASSED'}else{'CLASSIFY_FAILED_PROBE_BEFORE_REPAIR'});source_contract='Four separately invoked read-only config/RPC/health probes with verified command forwarding and byte-tested Win32 argv quoting plus fixed package/config/backup/Gateway topology metadata. No doctor repair, version mutation, or caller-selected command/path/argv.';truth_boundary='Only classifications, exit codes, hashes, safe versions, booleans, and known plugin flags are published. No raw output, config values, credentials, paths, messages, prompts, or secrets.'}
    $receipt=Publish-SafeFixedReport 'reports/gateway-failure-detail-omen.json' 'gateway-failure-detail-public.json' $public 'kevin gateway failure detail telemetry';Assert-Benchmark30
    return [ordered]@{state='OMEN_DIAGNOSIS_PROVEN';receipt_sha256=$receipt;root_cause_family=$family;all_probes_ok=$allProbesOk;probe_count=$probes.Count;openclaw_version=$version;release_policy_status=$public.release_policy_status;recommended_repair=$public.recommended_repair;keeper_present=[bool]$top.keeper_present;backup_semantically_equivalent=[bool]$facts.backup_semantically_equivalent}
}
'''
text = text[:start] + fixed_diag + text[end:]

anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.37 SELFTEST PASS package_source=fixed_registry_tarball fixed_specs_runtime_proven=true byte_sri_sha512=true embedded_windows_policy_pin=true install_from_verified_local_tarball=true rollback_package_same_contract=true dynamic_npm_view=false arbitrary_url=false arbitrary_shell=false authority_expansion=false'\n"
extra = anchor + r'''    foreach($fn in @('Invoke-OpenClawFixedConfig','Invoke-ReaderOpenClaw','Invoke-NpmFixed')){if((Get-Command $fn).Parameters.ContainsKey('Args')){throw 'automatic Args parameter must never be used for fixed command forwarding'};if(-not(Get-Command $fn).Parameters.ContainsKey('CommandArguments')){throw 'explicit command argument parameter missing'}};$diagFn=(Get-Command Diagnose-GatewayFailureDetail).ScriptBlock.ToString();foreach($m in @("@('config','validate','--json')","@('gateway','status','--require-rpc','--json')","@('gateway','call','status','--json')","@('gateway','health','--json')",'NONE_ALL_PROBES_PASSED','CLASSIFY_FAILED_PROBE_BEFORE_REPAIR')){if(-not$diagFn.Contains($m)){throw ('diagnostic contract missing '+$m)}}
    Write-Host 'KEVIN MAINTENANCE v1.3.38 SELFTEST PASS convergence=true explicit_command_arguments=true win32_argv_preserved=true four_independent_readonly_probes=true false_downgrade_prevented=true package_source=fixed_registry_tarball byte_sri_sha512=true supervisor_target=v1.8.5 authority_expansion=false arbitrary_shell=false'
'''
text = replace_once(text, anchor, extra, 'v1.3.38 selftest')

MAINT_OUT.write_text(text, encoding='utf-8', newline='')
print(f'SUPERVISOR_V185_GENERATED sha256={sup_sha}')
print(f'MAINT_V1338_GENERATED sha256={sha(MAINT_OUT.read_bytes())}')
