from pathlib import Path

p=Path('control-plane/install/KEVIN-CONTROL-PLANE-v1.3-REVIEW-CONTRACT-REPAIR.ps1')
s=p.read_text(encoding='utf-8')
new="function Use-StoredGhCredential {if([string]$env:KEVIN_GH_AUTH_MODE -eq 'env'){$env:GH_PROMPT_DISABLED='1';return};foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath (\"Env:{0}\" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}"
if new in s:
    print('INSTALLER_ENV_AUTH_ALREADY_APPLIED')
    raise SystemExit(0)
old="function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath (\"Env:{0}\" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}"
if s.count(old)!=1:
    raise SystemExit(f'installer auth anchor count={s.count(old)}')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
print('INSTALLER_ENV_AUTH_PATCHED')
