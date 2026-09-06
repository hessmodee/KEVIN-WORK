param(
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# Fixed identities from Matt's private 2026-09-06 recovery evidence.
$ExpectedCurrentSha = '29383A6B9A8C4B5FA00B394AC169C8DDF7F3EE8829762D0F5BBA271C606C6BEA'
$TrustedExactFiveSha = 'DBF596CF1E317D40A51E9E98FA50D63D1009CEC880C37E9D99F83C6E65E2ACF4'
$OpenClawRoot = Join-Path $env:USERPROFILE '.openclaw'
$Workspace = Join-Path $OpenClawRoot 'workspace'
$ConfigPath = Join-Path $OpenClawRoot 'openclaw.json'
$BackupRoot = Join-Path $Workspace 'reports\maintenance\backups'

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','') }
    finally { $sha.Dispose() }
}
function Get-Sha256Text([string]$Text) {
    return (Get-Sha256Bytes $Utf8.GetBytes($Text))
}
function Get-FileSha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Read-Json([string]$Path) {
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}
function Escape-PointerSegment([string]$Segment) {
    return $Segment.Replace('~','~0').Replace('/','~1')
}
function Unescape-PointerSegment([string]$Segment) {
    return $Segment.Replace('~1','/').Replace('~0','~')
}
function Get-ScalarType([object]$Value) {
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return 'string' }
    if ($Value -is [bool]) { return 'bool' }
    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or
        $Value -is [uint16] -or $Value -is [uint32] -or $Value -is [uint64]) { return 'integer' }
    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) { return 'number' }
    return 'scalar'
}
function Get-ValueJson([object]$Value) {
    if ($null -eq $Value) { return 'null' }
    return ($Value | ConvertTo-Json -Depth 60 -Compress)
}
function Add-Leaf([hashtable]$Map, [string]$Pointer, [string]$Kind, [object]$Value) {
    $json = if ($Kind -eq 'empty_object') { '{}' } elseif ($Kind -eq 'empty_array') { '[]' } else { Get-ValueJson $Value }
    $Map[$Pointer] = [pscustomobject]@{
        kind = $Kind
        type = if ($Kind -eq 'leaf') { Get-ScalarType $Value } else { $Kind }
        json = $json
        sha256 = (Get-Sha256Text $json).ToUpperInvariant()
        value = $Value
    }
}
function Flatten-Json([object]$Value, [hashtable]$Map, [string]$Pointer = '$') {
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [bool] -or
        $Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or
        $Value -is [uint16] -or $Value -is [uint32] -or $Value -is [uint64] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        Add-Leaf $Map $Pointer 'leaf' $Value
        return
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $keys = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
        if ($keys.Count -eq 0) { Add-Leaf $Map $Pointer 'empty_object' $null; return }
        foreach ($key in $keys) {
            $child = $Pointer + '/' + (Escape-PointerSegment $key)
            Flatten-Json $Value[$key] $Map $child
        }
        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @($Value)
        if ($items.Count -eq 0) { Add-Leaf $Map $Pointer 'empty_array' $null; return }
        for ($i = 0; $i -lt $items.Count; $i++) {
            Flatten-Json $items[$i] $Map ($Pointer + '/' + $i)
        }
        return
    }

    $props = @($Value.PSObject.Properties | Where-Object { $_.MemberType -in @('NoteProperty','Property') } | Sort-Object Name)
    if ($props.Count -eq 0) { Add-Leaf $Map $Pointer 'empty_object' $null; return }
    foreach ($prop in $props) {
        $child = $Pointer + '/' + (Escape-PointerSegment ([string]$prop.Name))
        Flatten-Json $prop.Value $Map $child
    }
}
function Mask-PathSegment([string]$Segment) {
    if ($Segment -match '@' -or $Segment -match '^[0-9]{7,}$' -or
        $Segment -match '^[A-Fa-f0-9]{24,}$' -or
        $Segment -match '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$' -or
        $Segment.Length -gt 80) {
        return '[key#' + (Get-Sha256Text $Segment).Substring(0,10) + ']'
    }
    if ($Segment -match '^[A-Za-z0-9_.:-]{1,80}$') { return $Segment }
    return '[key#' + (Get-Sha256Text $Segment).Substring(0,10) + ']'
}
function Get-SafeDisplayPath([string]$Pointer) {
    if ($Pointer -eq '$') { return '$' }
    $parts = $Pointer.Substring(2).Split('/')
    $display = '$'
    foreach ($raw in $parts) {
        $part = Unescape-PointerSegment $raw
        if ($part -match '^[0-9]+$') { $display += '[' + $part + ']' }
        else { $display += '.' + (Mask-PathSegment $part) }
    }
    return $display
}
function Get-PathClass([string]$DisplayPath) {
    if ($DisplayPath -match '(?i)(token|secret|password|credential|api.?key|cookie|jwt|oauth|private.?key)') { return 'SENSITIVE_PATH' }
    if ($DisplayPath -match '^\$\.meta\.') { return 'META' }
    if ($DisplayPath -match '^\$\.tools(\.|\[)') { return 'TOOL_POLICY' }
    if ($DisplayPath -match '^\$\.agents(\.|\[)') { return 'AGENT_RUNTIME' }
    if ($DisplayPath -match '^\$\.models(\.|\[)') { return 'MODEL_RUNTIME' }
    if ($DisplayPath -match '^\$\.plugins(\.|\[)') { return 'PLUGIN_RUNTIME' }
    if ($DisplayPath -match '^\$\.gateway(\.|\[)') { return 'GATEWAY_RUNTIME' }
    if ($DisplayPath -match '^\$\.(cron|hooks|channels|session|sessions)(\.|\[)') { return 'RUNTIME_OTHER' }
    return 'OTHER'
}
function Get-SafeValue([string]$DisplayPath, [object]$Record) {
    if ($null -eq $Record -or [string]$Record.kind -ne 'leaf') { return '' }
    $value = $Record.value
    if ($null -eq $value) { return 'null' }

    # Only reveal bounded, known non-secret operational values. Everything else stays hashed.
    if ($DisplayPath -match '^\$\.meta\.(lastTouchedAt|lastTouchedVersion)$') {
        $s = [string]$value
        if ($s.Length -le 100 -and $s -notmatch '(?i)(token|secret|password|credential)') { return $s }
    }
    if ($DisplayPath -match '(?i)(\.tools\.(profile|allow|alsoAllow|deny)(\[\d+\])?|\.model|\.models\[\d+\]\.id|\.plugins\.allow\[\d+\]|\.plugins\.entries\.[A-Za-z0-9_.:-]+\.enabled)$') {
        $s = [string]$value
        if ($s.Length -le 120 -and $s -match '^[A-Za-z0-9_./:*+-]{1,120}$') { return $s }
    }
    if ($DisplayPath -match '(?i)(contextTokens|contextWindow|maxTokens|num_ctx|\.gateway\.port)$') {
        if ($value -is [byte] -or $value -is [int16] -or $value -is [int32] -or $value -is [int64] -or
            $value -is [uint16] -or $value -is [uint32] -or $value -is [uint64]) { return [string]$value }
    }
    if ($DisplayPath -match '^\$\.gateway\.bind$') {
        $s = [string]$value
        if ($s -match '^(loopback|localhost|local|lan|auto)$') { return $s }
    }
    if ($DisplayPath -match '(?i)\.api$') {
        $s = [string]$value
        if ($s -match '^[A-Za-z0-9_.:-]{1,60}$') { return $s }
    }
    if ($DisplayPath -match '(?i)\.baseUrl$|\.baseURL$') {
        $s = [string]$value
        if ($s -match '^http://(127\.0\.0\.1|localhost):[0-9]{2,5}/?$') { return $s }
    }
    return ''
}
function Find-TrustedConfigCopy {
    $candidates = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $OpenClawRoot -PathType Container) {
        Get-ChildItem -LiteralPath $OpenClawRoot -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -le 2097152 -and $_.Name -match '(?i)^openclaw\.json' } |
            ForEach-Object { [void]$candidates.Add($_.FullName) }
    }
    if (Test-Path -LiteralPath $BackupRoot -PathType Container) {
        Get-ChildItem -LiteralPath $BackupRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -le 2097152 -and $_.Name -match '(?i)(openclaw|config)' } |
            Select-Object -First 5000 |
            ForEach-Object { [void]$candidates.Add($_.FullName) }
    }
    foreach ($path in @($candidates | Select-Object -Unique)) {
        try { if ((Get-FileSha $path) -ceq $TrustedExactFiveSha) { return $path } } catch {}
    }
    return ''
}
function Get-DiffRows([object]$Before, [object]$After) {
    $beforeMap = @{}
    $afterMap = @{}
    Flatten-Json $Before $beforeMap
    Flatten-Json $After $afterMap
    $keys = @($beforeMap.Keys + $afterMap.Keys | Sort-Object -Unique)
    $rows = @()
    foreach ($key in $keys) {
        $b = if ($beforeMap.ContainsKey($key)) { $beforeMap[$key] } else { $null }
        $a = if ($afterMap.ContainsKey($key)) { $afterMap[$key] } else { $null }
        if ($null -ne $b -and $null -ne $a -and [string]$b.sha256 -ceq [string]$a.sha256 -and [string]$b.type -ceq [string]$a.type) { continue }
        $display = Get-SafeDisplayPath $key
        $change = if ($null -eq $b) { 'ADDED' } elseif ($null -eq $a) { 'REMOVED' } else { 'CHANGED' }
        $rows += [pscustomobject]@{
            change = $change
            path = $display
            class = Get-PathClass $display
            before_type = if ($null -eq $b) { 'absent' } else { [string]$b.type }
            after_type = if ($null -eq $a) { 'absent' } else { [string]$a.type }
            before_hash = if ($null -eq $b) { '' } else { ([string]$b.sha256).Substring(0,12) }
            after_hash = if ($null -eq $a) { '' } else { ([string]$a.sha256).Substring(0,12) }
            before_safe = Get-SafeValue $display $b
            after_safe = Get-SafeValue $display $a
        }
    }
    return @($rows)
}
function Format-DiffRows([object[]]$Rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($row in $Rows) {
        $line = 'DIFF|' + $row.change + '|' + $row.class + '|' + $row.path +
            '|before=' + $row.before_type + ':' + $row.before_hash +
            '|after=' + $row.after_type + ':' + $row.after_hash
        if ($row.before_safe) { $line += '|before_safe=' + $row.before_safe }
        if ($row.after_safe) { $line += '|after_safe=' + $row.after_safe }
        [void]$lines.Add($line)
    }
    return @($lines)
}
function Invoke-SelfTest {
    $before = @{
        meta = @{lastTouchedAt='old';lastTouchedVersion='1';other='DO_NOT_PRINT_META_SECRET'}
        gateway = @{bind='loopback';auth=@{token='SUPER_SECRET_BEFORE'}}
        agents = @{list=@(@{id='main';model='ollama-chat-16k/qwen2.5:14b'})}
        models = @{providers=@{'ollama-chat-16k'=@{models=@(@{id='qwen2.5:14b';contextTokens=16384;params=@{num_ctx=16384}})}}}
    }
    $after = $before | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $after.meta.lastTouchedAt='new'
    $after.gateway.auth.token='SUPER_SECRET_AFTER'
    $after.models.providers.'ollama-chat-16k'.models[0].contextTokens=32768
    $rows = Get-DiffRows $before $after
    $text = (Format-DiffRows $rows) -join "`n"
    if ($text -match 'SUPER_SECRET|DO_NOT_PRINT') { throw 'Secret value leaked from diagnostic output' }
    if ($text -notmatch '\$\.gateway\.auth\.token') { throw 'Sensitive changed path was not reported' }
    if ($text -notmatch 'after_safe=32768') { throw 'Safe numeric model value was not reported' }
    if ($text -notmatch 'after_safe=new') { throw 'Safe touch metadata was not reported' }
    if ($rows.Count -ne 3) { throw ('Unexpected self-test diff count ' + $rows.Count) }
    Write-Host 'KEVIN CONFIG DRIFT DIAGNOSTIC SELFTEST PASS read_only=true secrets_redacted=true exact_paths=true safe_hints=true'
}

if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($env:OS -ne 'Windows_NT') { throw 'Run this read-only diagnostic on Kevin''s Windows host' }
if ((Get-FileSha $ConfigPath) -cne $ExpectedCurrentSha) { throw ('SAFE STOP: current config identity changed: ' + (Get-FileSha $ConfigPath)) }
$trustedPath = Find-TrustedConfigCopy
if (-not $trustedPath) { throw 'SAFE STOP: trusted DBF596 exact-five config copy not found in bounded backups' }
if ((Get-FileSha $trustedPath) -cne $TrustedExactFiveSha) { throw 'SAFE STOP: trusted config identity changed while reading' }

$current = Read-Json $ConfigPath
$trusted = Read-Json $trustedPath
$rows = Get-DiffRows $trusted $current

Write-Host ('KEVIN_CONFIG_DRIFT_DIAG_READY current=' + $ExpectedCurrentSha.Substring(0,12) + ' trusted=' + $TrustedExactFiveSha.Substring(0,12) + ' changed_paths=' + $rows.Count + ' read_only=true')
foreach ($line in (Format-DiffRows $rows)) { Write-Host $line }

$classes = @($rows | Group-Object class | Sort-Object Name | ForEach-Object { $_.Name + '=' + $_.Count })
Write-Host ('SUMMARY|' + ($classes -join '|'))
if ($rows.Count -eq 0) { Write-Host 'VERDICT|SEMANTICALLY_IDENTICAL' }
elseif (@($rows | Where-Object { $_.class -ne 'META' }).Count -eq 0) { Write-Host 'VERDICT|META_ONLY_DRIFT' }
else { Write-Host 'VERDICT|NON_META_SEMANTIC_DRIFT_REQUIRES_REVIEW' }
