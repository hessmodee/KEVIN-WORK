from pathlib import Path

installer_path=Path('control-plane/install/KEVIN-CONTROL-PLANE-v1.3-REVIEW-CONTRACT-REPAIR.ps1')
workflow_path=Path('.github/workflows/control-plane-v13-installer-gate.yml')
installer=installer_path.read_text(encoding='utf-8')
workflow=workflow_path.read_text(encoding='utf-8')

old="function Use-StoredGhCredential {foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath (\"Env:{0}\" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}"
new="function Use-StoredGhCredential {if([string]$env:KEVIN_GH_AUTH_MODE -eq 'env'){$env:GH_PROMPT_DISABLED='1';return};foreach($n in @('GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN')){Remove-Item -LiteralPath (\"Env:{0}\" -f $n) -ErrorAction SilentlyContinue};$env:GH_PROMPT_DISABLED='1'}"
if installer.count(old)!=1: raise SystemExit(f'installer auth anchor count={installer.count(old)}')
installer=installer.replace(old,new,1)

old_block="""        env:\n          TEST_GITHUB_TOKEN: ${{ github.token }}\n        run: |\n          $ErrorActionPreference='Stop'\n          $installer=(Resolve-Path 'control-plane/install/KEVIN-CONTROL-PLANE-v1.3-REVIEW-CONTRACT-REPAIR.ps1').Path\n          $token=$env:TEST_GITHUB_TOKEN\n          Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue\n          Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue\n          Remove-Item Env:TEST_GITHUB_TOKEN -ErrorAction SilentlyContinue\n          $token | gh auth login --hostname github.com --with-token\n          if($LASTEXITCODE -ne 0){throw 'Could not establish stored GitHub CLI credential for fixture.'}\n\n"""
new_block="""        env:\n          GH_TOKEN: ${{ github.token }}\n          KEVIN_GH_AUTH_MODE: env\n        run: |\n          $ErrorActionPreference='Stop'\n          $installer=(Resolve-Path 'control-plane/install/KEVIN-CONTROL-PLANE-v1.3-REVIEW-CONTRACT-REPAIR.ps1').Path\n\n"""
if workflow.count(old_block)!=1: raise SystemExit(f'workflow auth block count={workflow.count(old_block)}')
workflow=workflow.replace(old_block,new_block,1)

installer_path.write_text(installer,encoding='utf-8')
workflow_path.write_text(workflow,encoding='utf-8')
print('PATCH_INSTALLER_CI_AUTH_OK')
