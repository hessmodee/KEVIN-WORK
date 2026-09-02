param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ExpectedOpenClawVersion = '2026.7.1-2'
$Protected = @('exec','process','write','edit','apply_patch','browser','sessions_spawn','sessions_send','conversations_send','cron')
$KnownControl = @('get_goal','create_goal','update_goal','update_plan','progress_card','session_status','sessions_list','sessions_history','read')

function Get-TextSha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    } finally { $sha.Dispose() }
}
function Get-Prop([object]$Object,[string]$Name) {
    if ($null -eq $Object) { return $null }
    $prop = $Object.PSObject.Properties[$Name]
    # PowerShell otherwise enumerates arrays across the function boundary.
    if ($null -ne $prop) { return ,$prop.Value }
    return $null
}
function Get-StringArray([object]$Value) {
    if ($null -eq $Value) { return ,@() }
    if ($Value -isnot [array]) { throw 'tool policy list must be an array' }
    $items = @($Value)
    foreach ($item in $items) { if ($item -isnot [string]) { throw 'tool policy list item must be string' } }
    return ,@($items | Sort-Object -Unique)
}
function Get-PolicySummary([object]$Policy) {
    if ($null -eq $Policy) { $Policy = [pscustomobject]@{} }
    $profile = [string](Get-Prop $Policy 'profile')
    if (-not $profile) { $profile = 'UNSET' }
    elseif ($profile -notin @('minimal','coding','messaging','full')) { $profile = 'OTHER' }
    $allow = Get-StringArray (Get-Prop $Policy 'allow')
    $alsoAllow = Get-StringArray (Get-Prop $Policy 'alsoAllow')
    $deny = Get-StringArray (Get-Prop $Policy 'deny')
    if ($allow.Count -gt 0 -and $alsoAllow.Count -gt 0) { throw 'allow and alsoAllow cannot coexist' }
    $effectiveAllow = @($allow) + @($alsoAllow)
    return [ordered]@{
        present = (@($Policy.PSObject.Properties).Count -gt 0)
        profile = $profile
        allow_count = $allow.Count
        also_allow_count = $alsoAllow.Count
        deny_count = $deny.Count
        allow_sha256 = Get-TextSha256 (ConvertTo-Json -InputObject $allow -Compress)
        also_allow_sha256 = Get-TextSha256 (ConvertTo-Json -InputObject $alsoAllow -Compress)
        deny_sha256 = Get-TextSha256 (ConvertTo-Json -InputObject $deny -Compress)
        known_control_allowed = @($KnownControl | Where-Object { $effectiveAllow -contains $_ })
        protected_explicitly_allowed = @($Protected | Where-Object { $effectiveAllow -contains $_ })
        protected_explicitly_denied = @($Protected | Where-Object { $deny -contains $_ })
    }
}
function Get-FixedRuntime {
    if (-not $env:APPDATA) { throw 'APPDATA unavailable' }
    $pkg = Join-Path $env:APPDATA 'npm\node_modules\openclaw\package.json'
    $cli = Join-Path $env:APPDATA 'npm\node_modules\openclaw\dist\index.js'
    if (-not (Test-Path -LiteralPath $pkg -PathType Leaf) -or -not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'fixed OpenClaw runtime missing' }
    $version = [string](Get-Content -LiteralPath $pkg -Raw | ConvertFrom-Json).version
    if ($version -ne $ExpectedOpenClawVersion) { throw ('unexpected OpenClaw version ' + $version) }
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction Stop }
    return [pscustomobject]@{ node = $node.Source; cli = $cli; version = $version }
}
function ConvertTo-FixedArg([AllowEmptyString()][string]$Value) {
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $quote = [string][char]34
    $slash = [string][char]92
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append($quote)
    $slashes = 0
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $ch = $Value[$i]
        if ($ch -eq [char]92) { $slashes++; continue }
        if ($ch -eq [char]34) {
            if ($slashes -gt 0) { [void]$sb.Append(($slash * ($slashes * 2))) }
            [void]$sb.Append($slash); [void]$sb.Append($quote); $slashes = 0; continue
        }
        if ($slashes -gt 0) { [void]$sb.Append(($slash * $slashes)); $slashes = 0 }
        [void]$sb.Append($ch)
    }
    if ($slashes -gt 0) { [void]$sb.Append(($slash * ($slashes * 2))) }
    [void]$sb.Append($quote)
    return $sb.ToString()
}
function Invoke-FixedReadOnly([object]$Runtime,[string[]]$Arguments,[int]$TimeoutSeconds = 60) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Runtime.node
    $psi.Arguments = ((@($Runtime.cli) + @($Arguments) | ForEach-Object { ConvertTo-FixedArg ([string]$_) }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw 'fixed OpenClaw process start failed' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill() } catch {}
        $process.WaitForExit()
        throw 'fixed OpenClaw read-only probe timeout'
    }
    $result = [pscustomobject]@{ code = [int]$process.ExitCode; out = [string]$stdoutTask.Result; err = [string]$stderrTask.Result }
    $process.Dispose()
    return $result
}
function Get-MainEntry([object]$Config) {
    $agents = Get-Prop $Config 'agents'
    $list = Get-Prop $agents 'list'
    if ($null -eq $list) { return $null }
    $rows = @($list | Where-Object { [string](Get-Prop $_ 'id') -eq 'main' })
    if ($rows.Count -gt 1) { throw 'multiple main entries' }
    if ($rows.Count -eq 1) { return $rows[0] }
    return $null
}
function Get-ProviderPolicy([object]$Container,[string]$Provider,[string]$Model) {
    if ($null -eq $Container) { return $null }
    $byProvider = Get-Prop $Container 'byProvider'
    if ($null -eq $byProvider) { return $null }
    $p = $byProvider.PSObject.Properties[$Provider]
    if ($null -ne $p) { return $p.Value }
    $m = $byProvider.PSObject.Properties[$Model]
    if ($null -ne $m) { return $m.Value }
    return $null
}

if ($SelfTest) {
    # Exercise parsed JSON too: callers must preserve 0/1/N collection shape.
    foreach ($json in @('{}','{"allow":[]}','{"allow":["get_goal"]}','{"allow":["get_goal","exec"]}')) {
        $p = $json | ConvertFrom-Json
        $s = Get-PolicySummary $p
        $v = Get-Prop $p 'allow'
        $expectedCount = if ($null -eq $v) { 0 } else { $v.Count }
        if ($s.allow_count -ne $expectedCount) { throw 'JSON array cardinality lost' }
        $expectedJson = if ($expectedCount -eq 0) { '[]' } elseif ($expectedCount -eq 1) { '["get_goal"]' } else { '["exec","get_goal"]' }
        if ($s.allow_sha256 -ne (Get-TextSha256 $expectedJson)) { throw 'JSON array hash shape lost' }
    }
    if ((Get-PolicySummary $null).present) { throw 'null policy must be absent' }
    if ((Get-PolicySummary ([pscustomobject]@{})).present) { throw 'empty policy must be absent' }
    $singletonConfig = '{"agents":{"list":[{"id":"main"}]}}' | ConvertFrom-Json
    if ((Get-MainEntry $singletonConfig).id -ne 'main') { throw 'singleton agent list lost' }
    foreach ($json in @('{"allow":"exec"}','{"allow":42}','{"allow":{}}','{"allow":[42]}','{"deny":"write"}')) {
        $blocked = $false
        try { Get-PolicySummary ($json | ConvertFrom-Json) | Out-Null } catch { $blocked = $true }
        if (-not $blocked) { throw 'malformed list accepted' }
    }
    $policy = [pscustomobject]@{ allow = @('get_goal','exec'); deny = @('write') }
    $summary = Get-PolicySummary $policy
    if ($summary.allow_count -ne 2 -or @($summary.protected_explicitly_allowed).Count -ne 1 -or $summary.protected_explicitly_allowed[0] -ne 'exec') { throw 'summary selftest failed' }
    $bad = [pscustomobject]@{ allow = @('get_goal'); alsoAllow = @('read') }
    $blocked = $false
    try { Get-PolicySummary $bad | Out-Null } catch { $blocked = $true }
    if (-not $blocked) { throw 'allow/alsoAllow negative failed' }
    Write-Host 'KEVIN MAIN TOOL POLICY DIAGNOSTIC v1 SELFTEST PASS read_only=true fixed_main=true raw_config_output=false arbitrary_command=false'
    exit 0
}

$configPath = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { throw 'fixed OpenClaw config missing' }
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$main = Get-MainEntry $config
$agents = Get-Prop $config 'agents'
$defaults = Get-Prop $agents 'defaults'
$model = Get-Prop $main 'model'
if ($null -eq $model) { $model = Get-Prop $defaults 'model' }
if ($model -isnot [string]) { $model = Get-Prop $model 'primary' }
$model = [string]$model
if (-not $model) { $model = 'UNKNOWN' }
$parts = $model -split '/',2
$provider = if ($parts.Count -eq 2) { $parts[0] } else { 'UNKNOWN' }
$rootTools = Get-Prop $config 'tools'
$mainTools = Get-Prop $main 'tools'
$rootProvider = Get-ProviderPolicy $rootTools $provider $model
$mainProvider = Get-ProviderPolicy $mainTools $provider $model
$runtime = Get-FixedRuntime
$validate = Invoke-FixedReadOnly $runtime @('config','validate','--json')
if ($validate.code -ne 0) { throw 'OpenClaw config validation failed' }
$explain = Invoke-FixedReadOnly $runtime @('sandbox','explain','--agent','main','--json')
$explainOk = ($explain.code -eq 0)
if ($explainOk) { try { $null = $explain.out | ConvertFrom-Json } catch { $explainOk = $false } }
$sandbox = Get-Prop $main 'sandbox'
$sandboxMode = [string](Get-Prop $sandbox 'mode'); if (-not $sandboxMode) { $sandboxMode = 'UNSET' }
$workspaceAccess = [string](Get-Prop $sandbox 'workspaceAccess'); if (-not $workspaceAccess) { $workspaceAccess = 'UNSET' }
$rootSummary = Get-PolicySummary $rootTools
$mainSummary = Get-PolicySummary $mainTools
$rootProviderSummary = Get-PolicySummary $rootProvider
$mainProviderSummary = Get-PolicySummary $mainProvider
$explainHashText = if ($explainOk) { [string]$explain.out } else { '' }
$out = [ordered]@{
    schema = 1
    kind = 'kevin-main-tool-policy-diagnostic'
    state = 'READ_ONLY_DIAGNOSIS'
    safe_for_public_repo = $true
    openclaw_version = $runtime.version
    config_sha256 = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
    main_entry_present = ($null -ne $main)
    model_family = $(if ($model -match '(?i)qwen2\.5') { 'QWEN2_5' } else { 'OTHER' })
    model_id_sha256 = Get-TextSha256 $model
    provider_id_sha256 = Get-TextSha256 $provider
    root = $rootSummary
    main = $mainSummary
    root_provider = $rootProviderSummary
    main_provider = $mainProviderSummary
    sandbox = [ordered]@{ mode = $sandboxMode; workspace_access = $workspaceAccess; explain_ok = $explainOk; explain_sha256 = Get-TextSha256 $explainHashText }
    risk = [ordered]@{ broad_profile = ($rootSummary.profile -in @('coding','full') -or $mainSummary.profile -in @('coding','full')); protected_explicit_allow = (@($rootSummary.protected_explicitly_allowed).Count -gt 0 -or @($mainSummary.protected_explicitly_allowed).Count -gt 0) }
    truth_boundary = 'Fixed main/config + fixed sandbox explain only. No raw config, list contents outside small policy-owned known sets, paths, credentials, prompts, messages, or arbitrary command output are emitted.'
}
$out | ConvertTo-Json -Depth 20
