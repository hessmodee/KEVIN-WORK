param(
    [ValidateSet('snapshot','hardware','processes','services','storage','tasks','network','software','event_health')]
    [string]$Operation = 'snapshot',
    [switch]$SelfTest
)

# Kevin OS Observer v0.1
# GREEN / READ-ONLY observation primitive candidate.
# No arbitrary shell, no caller-selected command/argv/path, no mutation of OS state.
# Detailed evidence stays local. A sanitized summary is written separately for safe telemetry use.

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$ws = $PSScriptRoot
$reportRoot = Join-Path $ws 'reports\os-awareness'
$localPath = Join-Path $reportRoot 'latest-local.json'
$publicPath = Join-Path $reportRoot 'latest-public.json'
$allowed = @('snapshot','hardware','processes','services','storage','tasks','network','software','event_health')

New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null

function Write-JsonAtomic([string]$Path,[object]$Object) {
    $tmp = $Path + '.tmp-' + $PID + '-' + [guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText($tmp,($Object | ConvertTo-Json -Depth 40),$utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Safe-Call([scriptblock]$Script,[object]$Fallback) {
    try { return (& $Script) } catch { return $Fallback }
}

function Get-Hardware {
    $os = Safe-Call { Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime } $null
    $cs = Safe-Call { Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,TotalPhysicalMemory,NumberOfProcessors,NumberOfLogicalProcessors } $null
    $cpu = @(Safe-Call { Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed } @())
    $memory = @(Safe-Call { Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,Capacity,Speed,ConfiguredClockSpeed } @())
    $gpu = @(Safe-Call { Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,AdapterRAM,VideoModeDescription } @())
    [ordered]@{
        os = $os
        computer = $cs
        cpu = $cpu
        memory_modules = $memory
        gpu = $gpu
    }
}

function Get-ProcessesSafe {
    $rows = @()
    foreach($p in @(Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 150)) {
        $start = $null
        try { $start = $p.StartTime.ToString('o') } catch {}
        $cpu = 0
        try { if($null -ne $p.CPU){$cpu=[double]$p.CPU} } catch {}
        $rows += [pscustomobject]@{
            name = [string]$p.ProcessName
            id = [int]$p.Id
            working_set_bytes = [int64]$p.WorkingSet64
            cpu_seconds = $cpu
            start_time = $start
        }
    }
    return @($rows)
}

function Get-ServicesSafe {
    return @(Safe-Call {
        Get-CimInstance Win32_Service |
            Sort-Object Name |
            Select-Object -First 300 Name,DisplayName,State,StartMode
    } @())
}

function Get-StorageSafe {
    $logical = @(Safe-Call {
        Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
            Select-Object DeviceID,VolumeName,FileSystem,Size,FreeSpace
    } @())
    $physical = @(Safe-Call {
        Get-CimInstance Win32_DiskDrive |
            Select-Object Model,InterfaceType,MediaType,Size
    } @())
    [ordered]@{ logical = $logical; physical = $physical }
}

function Get-TasksSafe {
    return @(Safe-Call {
        Get-ScheduledTask |
            Sort-Object TaskPath,TaskName |
            Select-Object -First 400 TaskName,TaskPath,State
    } @())
}

function Get-NetworkSafe {
    $adapters = @(Safe-Call {
        Get-NetAdapter |
            Sort-Object Name |
            Select-Object Name,InterfaceDescription,Status,LinkSpeed
    } @())
    $profiles = @(Safe-Call {
        Get-NetConnectionProfile |
            Select-Object Name,InterfaceAlias,NetworkCategory,IPv4Connectivity,IPv6Connectivity
    } @())
    [ordered]@{ adapters = $adapters; profiles = $profiles }
}

function Get-SoftwareSafe {
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $rows = @()
    foreach($path in $paths) {
        foreach($x in @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue)) {
            if([string]::IsNullOrWhiteSpace([string]$x.DisplayName)){continue}
            $rows += [pscustomobject]@{
                name = [string]$x.DisplayName
                version = [string]$x.DisplayVersion
                publisher = [string]$x.Publisher
                install_date = [string]$x.InstallDate
            }
        }
    }
    return @($rows | Sort-Object name,version -Unique | Select-Object -First 600)
}

function Get-EventHealthSafe {
    $since = (Get-Date).AddHours(-24)
    $system = @(Safe-Call {
        Get-WinEvent -FilterHashtable @{LogName='System';Level=@(1,2);StartTime=$since} -MaxEvents 150 |
            Select-Object TimeCreated,ProviderName,Id,LevelDisplayName
    } @())
    $application = @(Safe-Call {
        Get-WinEvent -FilterHashtable @{LogName='Application';Level=@(1,2);StartTime=$since} -MaxEvents 150 |
            Select-Object TimeCreated,ProviderName,Id,LevelDisplayName
    } @())
    [ordered]@{ window_hours = 24; system = $system; application = $application }
}

function Build-Section([string]$Name) {
    switch($Name) {
        'hardware' { return Get-Hardware }
        'processes' { return @(Get-ProcessesSafe) }
        'services' { return @(Get-ServicesSafe) }
        'storage' { return Get-StorageSafe }
        'tasks' { return @(Get-TasksSafe) }
        'network' { return Get-NetworkSafe }
        'software' { return @(Get-SoftwareSafe) }
        'event_health' { return Get-EventHealthSafe }
        default { throw 'operation not allowlisted' }
    }
}

function Count-Array($x) { return @($x).Count }

function Build-PublicSummary([object]$Local) {
    $hardware = $null
    if($Local.sections.PSObject.Properties.Name -contains 'hardware'){$hardware=$Local.sections.hardware}
    $processCount = 0; if($Local.sections.PSObject.Properties.Name -contains 'processes'){$processCount=Count-Array $Local.sections.processes}
    $serviceCount = 0; if($Local.sections.PSObject.Properties.Name -contains 'services'){$serviceCount=Count-Array $Local.sections.services}
    $taskCount = 0; if($Local.sections.PSObject.Properties.Name -contains 'tasks'){$taskCount=Count-Array $Local.sections.tasks}
    $softwareCount = 0; if($Local.sections.PSObject.Properties.Name -contains 'software'){$softwareCount=Count-Array $Local.sections.software}
    $systemErrors = 0; $appErrors = 0
    if($Local.sections.PSObject.Properties.Name -contains 'event_health'){
        $systemErrors=Count-Array $Local.sections.event_health.system
        $appErrors=Count-Array $Local.sections.event_health.application
    }
    $memoryBytes = 0
    if($hardware -and $hardware.computer){$memoryBytes=[int64]$hardware.computer.TotalPhysicalMemory}
    [ordered]@{
        schema = 1
        kind = 'kevin-os-awareness-public-summary'
        generated_at = [string]$Local.generated_at
        authority = 'GREEN'
        read_only = $true
        operation = [string]$Local.operation
        counts = [ordered]@{
            processes = $processCount
            services = $serviceCount
            scheduled_tasks = $taskCount
            installed_software = $softwareCount
            system_critical_or_error_24h = $systemErrors
            application_critical_or_error_24h = $appErrors
        }
        hardware_summary = [ordered]@{
            total_physical_memory_bytes = $memoryBytes
            cpu_count = if($hardware){Count-Array $hardware.cpu}else{0}
            gpu_count = if($hardware){Count-Array $hardware.gpu}else{0}
            memory_module_count = if($hardware){Count-Array $hardware.memory_modules}else{0}
        }
        privacy = 'No command lines, environment variables, credentials, user documents, IP addresses, MAC addresses, serial numbers, event messages, registry secrets, or arbitrary file contents are included.'
    }
}

function Invoke-SelfTest {
    if($allowed.Count -ne 9){throw 'allowlist count mismatch'}
    foreach($x in @('snapshot','hardware','processes','services','storage','tasks','network','software','event_health')){
        if(-not($allowed -contains $x)){throw ('missing operation '+$x)}
    }
    $bad=$false
    try { Build-Section 'arbitrary_shell' | Out-Null } catch { $bad=$true }
    if(-not $bad){throw 'unknown operation did not fail closed'}
    Write-Host 'KEVIN OS OBSERVER v0.1 SELFTEST PASS operations=9 read_only=true arbitrary_shell=false caller_command=false credentials=false mutation=false'
}

if($SelfTest){Invoke-SelfTest;exit 0}
if(-not($allowed -contains $Operation)){throw 'operation not allowlisted'}

$sections = [ordered]@{}
if($Operation -eq 'snapshot'){
    foreach($name in @('hardware','processes','services','storage','tasks','network','software','event_health')){
        $sections[$name] = Build-Section $name
    }
}else{
    $sections[$Operation] = Build-Section $Operation
}

$local = [pscustomobject]@{
    schema = 1
    kind = 'kevin-os-awareness-local-evidence'
    generated_at = (Get-Date).ToString('o')
    authority = 'GREEN'
    read_only = $true
    operation = $Operation
    sections = [pscustomobject]$sections
}
Write-JsonAtomic $localPath $local
$public = Build-PublicSummary $local
Write-JsonAtomic $publicPath $public
Write-Host ('KEVIN OS OBSERVER DONE operation='+$Operation)
Write-Host ('Local evidence = '+$localPath)
Write-Host ('Public summary = '+$publicPath)
