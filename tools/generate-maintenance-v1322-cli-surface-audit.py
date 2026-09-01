from pathlib import Path
import hashlib

SRC=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.21.ps1')
OUT=Path('control-plane/maintenance/kevin-maintenance-runner-v1.3.22.ps1')
EXPECTED='AF8C37FEF03A8BD0F2E2131FCA9BA7384D26F4AFD8B35CF8D6608D1249733ED3'
raw=SRC.read_bytes()
actual=hashlib.sha256(raw).hexdigest().upper()
if actual!=EXPECTED:
    raise SystemExit(f'v1.3.21 source identity mismatch: {actual}')
text=raw.decode('utf-8')
if text.count("version='1.3.21'")!=1:
    raise SystemExit('version anchor mismatch')
text=text.replace("version='1.3.21'","version='1.3.22'",1)

old="""        'version' {@('--version')}
        'config_validate' {@('config','validate','--json')}"""
new="""        'version' {@('--version')}
        'root_help' {@('--help')}
        'automations_help' {@('automations','--help')}
        'cron_help' {@('cron','--help')}
        'agent_help' {@('agent','--help')}
        'config_validate' {@('config','validate','--json')}"""
if text.count(old)!=1:
    raise SystemExit('read-only probe switch anchor mismatch')
text=text.replace(old,new,1)

old="""    $version=Invoke-OpenClawReadOnlyProbe 'version'
    $validate=Invoke-OpenClawReadOnlyProbe 'config_validate'"""
new="""    $version=Invoke-OpenClawReadOnlyProbe 'version'
    $rootHelp=Invoke-OpenClawReadOnlyProbe 'root_help'
    $automationsHelp=Invoke-OpenClawReadOnlyProbe 'automations_help'
    $cronHelp=Invoke-OpenClawReadOnlyProbe 'cron_help'
    $agentHelp=Invoke-OpenClawReadOnlyProbe 'agent_help'
    $validate=Invoke-OpenClawReadOnlyProbe 'config_validate'"""
if text.count(old)!=1:
    raise SystemExit('runtime capabilities probe anchor mismatch')
text=text.replace(old,new,1)

old="""        openclaw=[ordered]@{
            cli_present=[bool]$version.available
            version=$versionToken
            config_valid=([int]$validate.exit_code -eq 0)
            gateway_deep_probe_ok=([int]$gateway.exit_code -eq 0)
        }"""
new="""        openclaw=[ordered]@{
            cli_present=[bool]$version.available
            version=$versionToken
            version_exit_code=[int]$version.exit_code
            version_output_sha256=(Get-TextSha256 (Safe-Text ([string]$version.output) 400))
            config_valid=([int]$validate.exit_code -eq 0)
            gateway_deep_probe_ok=([int]$gateway.exit_code -eq 0)
            cli_surface=[ordered]@{
                root_help_ok=([int]$rootHelp.exit_code -eq 0)
                root_mentions_agent=([string]$rootHelp.output -match '(?i)\\bagent\\b')
                root_mentions_automations=([string]$rootHelp.output -match '(?i)\\bautomations\\b')
                root_mentions_cron=([string]$rootHelp.output -match '(?i)\\bcron\\b')
                automations_help_ok=([int]$automationsHelp.exit_code -eq 0)
                automations_fell_to_tui=([string]$automationsHelp.output -match '(?i)TUI needs an interactive TTY')
                cron_help_ok=([int]$cronHelp.exit_code -eq 0)
                cron_fell_to_tui=([string]$cronHelp.output -match '(?i)TUI needs an interactive TTY')
                agent_help_ok=([int]$agentHelp.exit_code -eq 0)
                agent_has_local=([string]$agentHelp.output -match '(?i)--local')
                agent_has_message=([string]$agentHelp.output -match '(?i)--message')
                agent_has_agent=([string]$agentHelp.output -match '(?i)--agent')
                agent_has_json=([string]$agentHelp.output -match '(?i)--json')
            }
        }"""
if text.count(old)!=1:
    raise SystemExit('public OpenClaw block anchor mismatch')
text=text.replace(old,new,1)

old="Write-Host 'KEVIN MAINTENANCE v1.3.21 SELFTEST PASS canonical_automations_cli=true noninteractive_scheduler_adapter=fixed arbitrary_shell=false authority_expansion=false'"
if text.count(old)!=1:
    raise SystemExit('v1.3.21 selftest marker mismatch')
new=old+"\n    Write-Host 'KEVIN MAINTENANCE v1.3.22 SELFTEST PASS cli_surface_audit=fixed read_only=true raw_help_published=false arbitrary_shell=false authority_expansion=false'"
text=text.replace(old,new,1)
OUT.write_text(text,encoding='utf-8',newline='')
print('MAINT_V1322_GENERATED sha256='+hashlib.sha256(OUT.read_bytes()).hexdigest().upper())
