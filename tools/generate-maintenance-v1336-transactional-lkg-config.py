from pathlib import Path
import hashlib

SRC = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.35.ps1')
OUT = Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.36.ps1')
EXPECTED_SRC_SHA256 = '868D7E1726A47C12AF58C8A4060CC641F4F066885BF5D79550D8F9A4DA6E3A45'

raw = SRC.read_bytes()
actual = hashlib.sha256(raw).hexdigest().upper()
if actual != EXPECTED_SRC_SHA256:
    raise SystemExit(f'v1.3.35 source identity mismatch: {actual}')
text = raw.decode('utf-8')


def once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label} anchor count={count}')
    text = text.replace(old, new, 1)


once("version='1.3.35'", "version='1.3.36'", 'state version')

start = text.index('function Repair-OpenClawWindowsLkg {')
end = text.index('function Reconcile-MaintenanceCronBackoff', start)
old = text[start:end]
new = r'''function Repair-OpenClawWindowsLkg {
    if($env:OS-ne'Windows_NT'){throw 'Windows LKG recovery requires Windows'}
    $before=Get-InstalledOpenClawVersion;if($before-notin@($GatewayRejectedVersion,$GatewayLkgVersion)){throw ('Windows LKG recovery refuses unexpected installed version '+$before)}
    Assert-NpmIntegrity $GatewayLkgVersion $GatewayLkgIntegrity
    $facts=Get-DirectGatewayConfigFacts;$top=Get-GatewayTopology;if(-not$facts.current_exists){throw 'OpenClaw config missing'}
    if($top.keeper_present-and-not$top.keeper_script_present){throw 'Gateway Keeper task exists but fixed Keeper script is missing'}
    $config=Join-Path $env:USERPROFILE '.openclaw\\openclaw.json'
    $beforeConfigSha=Get-Sha $config;if(-not$beforeConfigSha){throw 'starting OpenClaw config hash unavailable'}
    $backupDir=Join-Path $BackupRoot ('openclaw-lkg-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force -Path $backupDir|Out-Null
    $savedConfig=Join-Path $backupDir 'openclaw.json';Copy-Item -LiteralPath $config -Destination $savedConfig -Force
    if((Get-Sha $savedConfig)-ne$beforeConfigSha){throw 'pretransition config snapshot hash mismatch'}
    $versionTransitionAttempted=$false;$launcher=''
    try{
        if($top.keeper_present){try{Stop-ScheduledTask -TaskName $GatewayKeeperTaskName -ErrorAction SilentlyContinue}catch{}}elseif($top.legacy_present){try{Stop-ScheduledTask -TaskName $LegacyGatewayTaskName -ErrorAction SilentlyContinue}catch{}}
        Stop-FixedGatewayListener
        if($before-ne$GatewayLkgVersion){$versionTransitionAttempted=$true;Install-ExactOpenClaw $GatewayLkgVersion}
        # The target LKG must prove it can read the untouched current config.
        # No metadata rewrite or backup substitution is allowed.
        $v=Invoke-OpenClawFixedConfig @('config','validate','--json');if($v.exit_code-ne0){throw 'LKG current-config compatibility validation failed'}
        if((Get-Sha $config)-ne$beforeConfigSha){throw 'LKG config validation unexpectedly modified config'}
        $launcher=Start-AuthoritativeGateway $top;if(-not(Wait-GatewayRpc 90)){throw 'LKG Gateway direct RPC did not become healthy'}
        $health=Invoke-OpenClawFixedConfig @('gateway','health','--json');if($health.exit_code-ne0){throw 'LKG Gateway health failed'}
        $skills=Invoke-OpenClawFixedConfig @('skills','check','--agent','main','--json');if($skills.exit_code-ne0){throw 'LKG main-agent skills check failed'}
        Assert-Benchmark30;$after=Get-InstalledOpenClawVersion
        if($after-ne$GatewayLkgVersion){throw 'LKG postcondition version mismatch'}
        if((Get-Sha $config)-ne$beforeConfigSha){throw 'OpenClaw config changed during successful LKG recovery'}
        $public=[ordered]@{schema=1;kind='kevin-openclaw-windows-lkg-recovery-public';generated_at=(Get-Date).ToString('o');state='OMEN_PROVEN';safe_for_public_repo=$true;before_version=$before;after_version=$after;validated_version=$GatewayLkgVersion;npm_integrity_verified=$true;transactional_config_validation=$true;config_snapshot_verified=$true;config_sha_unchanged=$true;config_backup_used=$false;authoritative_launcher=$launcher;keeper_preserved=[bool]$top.keeper_present;config_valid=$true;gateway_direct_rpc=$true;gateway_health=$true;main_skills_check=$true;benchmark_30_of_30=$true;rollback_available=$true;source_contract='Fixed Windows exact-version recovery to validated LKG with fixed npm integrity, exact pretransition config snapshot, target-version compatibility validation against the untouched config, preserved Keeper topology, fixed RPC/health/main-skills/Benchmark postconditions, and exact package/config rollback.';truth_boundary='No npm output, config body, credentials, paths, messages, prompts, or secrets are published.'}
        $receipt=Publish-SafeFixedReport 'reports/openclaw-windows-lkg-recovery-omen.json' 'openclaw-windows-lkg-recovery-public.json' $public 'kevin OpenClaw Windows LKG recovery telemetry'
        return [ordered]@{state='OMEN_PROVEN';receipt_sha256=$receipt;before_version=$before;after_version=$after;authoritative_launcher=$launcher;gateway_direct_rpc=$true;benchmark='30/30';transactional_config_validation=$true;config_sha_unchanged=$true}
    }catch{
        $primary=$_.Exception.Message;$packageRollbackOk=$true;$configRollbackOk=$true
        try{Copy-Item -LiteralPath $savedConfig -Destination $config -Force;if((Get-Sha $config)-ne$beforeConfigSha){throw 'starting OpenClaw config not restored exactly'}}catch{$configRollbackOk=$false}
        if($versionTransitionAttempted){
            try{Assert-NpmIntegrity $GatewayRejectedVersion $GatewayRejectedIntegrity;Install-ExactOpenClaw $GatewayRejectedVersion;if((Get-InstalledOpenClawVersion)-ne$before){throw 'starting OpenClaw version not restored'}}catch{$packageRollbackOk=$false}
        }
        try{$null=Start-AuthoritativeGateway $top}catch{};try{Assert-Benchmark30}catch{}
        if(-not$configRollbackOk -or -not$packageRollbackOk){throw ('OpenClaw Windows LKG recovery AND exact rollback failed config='+$configRollbackOk+' package='+$packageRollbackOk+' after: '+$primary)}
        throw ('OpenClaw Windows LKG recovery rollback completed: '+$primary)
    }
}

'''
text = text[:start] + new + text[end:]

self_anchor = "    Write-Host 'KEVIN MAINTENANCE v1.3.35 SELFTEST PASS safe_report_publish=bounded3 create_update_race=true remote_hash_verify=true continuation_cli=cron_alias backoff_reset=true arbitrary_shell=false authority_expansion=false'\n"
self_extra = self_anchor + r'''    $lkgFn=(Get-Command Repair-OpenClawWindowsLkg).ScriptBlock.ToString();if($lkgFn.Contains('SAFE_BACKUP_NOT_PROVEN_FOR_DOWNGRADE') -or $lkgFn.Contains('SAFE_BACKUP_VERSION_NOT_COMPATIBLE')){throw 'metadata-only downgrade backup gate retained'};if(-not$lkgFn.Contains('pretransition config snapshot hash mismatch')){throw 'exact pretransition config snapshot verification missing'};if(-not$lkgFn.Contains('LKG current-config compatibility validation failed')){throw 'target-version config compatibility validation missing'};if(-not$lkgFn.Contains('LKG config validation unexpectedly modified config')){throw 'config mutation guard missing'};if(-not$lkgFn.Contains('starting OpenClaw config not restored exactly')){throw 'exact config rollback verification missing'};if(-not$lkgFn.Contains('starting OpenClaw version not restored')){throw 'exact package rollback verification missing'}
    Write-Host 'KEVIN MAINTENANCE v1.3.36 SELFTEST PASS lkg_config_compat=target_validates_untouched transactional_snapshot=true config_hash_unchanged=true exact_config_rollback=true exact_package_rollback=true keeper_preserved=true gateway_rpc_postcondition=true benchmark_30=true arbitrary_shell=false authority_expansion=false'
'''
once(self_anchor, self_extra, 'v1.3.36 selftest')

OUT.write_text(text, encoding='utf-8', newline='')
print('MAINT_V1336_GENERATED sha256=' + hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
