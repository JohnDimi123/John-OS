<#
    John OS — common helper library
    Dot-sourced by every John OS script. Provides admin check, logging,
    registry backup + safe set, and profile helpers.

    SAFETY: every state-changing helper honors -WhatIf (via $PSCmdlet in the
    calling advanced function) and writes a .reg backup before changing a key.
#>

Set-StrictMode -Version Latest

# ---- Paths -----------------------------------------------------------------
$Global:JohnOSRoot    = Join-Path $env:ProgramData 'JohnOS'
$Global:JohnOSBackups = Join-Path $JohnOSRoot 'backups'
$Global:JohnOSLogDir  = Join-Path $JohnOSRoot 'logs'
$Global:JohnOSLog     = Join-Path $JohnOSLogDir ('johnos-{0:yyyyMMdd}.log' -f (Get-Date))

foreach ($d in @($JohnOSRoot,$JohnOSBackups,$JohnOSLogDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ---- Logging ---------------------------------------------------------------
function Write-JohnLog {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('INFO','WARN','ERROR','OK','SKIP','WHATIF')] [string] $Level = 'INFO'
    )
    $line = '{0:HH:mm:ss} [{1,-6}] {2}' -f (Get-Date), $Level, $Message
    $color = switch ($Level) {
        'OK'     {'Green'}    'WARN' {'Yellow'} 'ERROR' {'Red'}
        'SKIP'   {'DarkGray'} 'WHATIF'{'Cyan'}  default {'Gray'}
    }
    Write-Host $line -ForegroundColor $color
    try { Add-Content -Path $JohnOSLog -Value $line -ErrorAction Stop } catch {}
}

# ---- Admin / environment ---------------------------------------------------
function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'John OS scripts must run from an ELEVATED PowerShell prompt (Run as administrator).'
    }
}

function Test-IsLaptop {
    # Chassis types 8,9,10,11,12,14,18,21,30,31,32 are portable/notebook/tablet.
    try {
        $types = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes
        return [bool]($types | Where-Object { $_ -in 8,9,10,11,12,14,18,21,30,31,32 })
    } catch { return $false }
}

function Get-InstalledRamGB {
    try { return [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB) }
    catch { return 8 }
}

# ---- Registry helpers ------------------------------------------------------
function Backup-RegKey {
    param([Parameter(Mandatory)][string]$Path)   # e.g. HKLM\SYSTEM\...
    $safe = ($Path -replace '[:\\]','_')
    $file = Join-Path $JohnOSBackups ('{0}_{1:yyyyMMddHHmmss}.reg' -f $safe,(Get-Date))
    # reg export is best-effort; missing keys are fine (nothing to restore).
    & reg.exe export $Path $file /y *>$null
    if (Test-Path $file) { Write-JohnLog "backup -> $file" 'INFO' }
}

<#
  Set-RegValue: idempotent, backed-up, WhatIf-aware registry write.
  Pass $Cmdlet = $PSCmdlet from the calling advanced function so -WhatIf flows.
#>
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,                       # PS path: 'HKLM:\...'
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord','QWord','String','ExpandString','MultiString','Binary')]
        [string]$Type = 'DWord',
        [Parameter(Mandatory)]$Cmdlet
    )
    # Normalize DWord values so 0xFFFFFFFF / -1 / 4294967295 store + compare the
    # same on Windows PowerShell 5.1 (hex -> Int32) and PowerShell 7 (-> Int64).
    $norm = $Value
    if ($Type -eq 'DWord') { $norm = ([int64]$Value -band 0xFFFFFFFF) }
    elseif ($Type -eq 'QWord') { $norm = [int64]$Value }

    $current = $null
    if (Test-Path $Path) {
        $current = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    }
    $currentNorm = $current
    if ($null -ne $current -and $Type -eq 'DWord') { $currentNorm = ([int64]$current -band 0xFFFFFFFF) }

    if ($null -ne $current -and "$currentNorm" -eq "$norm") {
        Write-JohnLog "unchanged: $Path\$Name = $Value" 'SKIP'; return
    }
    $target = "$Path\$Name = $Value ($Type)"
    if (-not $Cmdlet.ShouldProcess($target,'Set registry value')) {
        Write-JohnLog "would set $target" 'WHATIF'; return
    }
    # Backup the hive key (reg.exe path form) before first change.
    Backup-RegKey ($Path -replace '^HKLM:','HKLM' -replace '^HKCU:','HKCU' -replace '^HKLM\\','HKLM\' )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $norm -PropertyType $Type -Force | Out-Null
    Write-JohnLog "set $target" 'OK'
}

function Set-ServiceStartup {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Automatic','Manual','Disabled','AutomaticDelayedStart')]$StartupType,
        [Parameter(Mandatory)]$Cmdlet
    )
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-JohnLog "service not present: $Name" 'SKIP'; return }
    if (-not $Cmdlet.ShouldProcess("$Name","Set startup -> $StartupType")) {
        Write-JohnLog "would set service $Name -> $StartupType" 'WHATIF'; return
    }
    try {
        if ($StartupType -eq 'AutomaticDelayedStart') {
            Set-Service -Name $Name -StartupType Automatic -ErrorAction Stop
            & sc.exe config $Name start= delayed-auto *>$null
        } else {
            Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        }
        Write-JohnLog "service $Name -> $StartupType" 'OK'
    } catch { Write-JohnLog "could not set $Name ($($_.Exception.Message))" 'WARN' }
}

function Write-JohnBanner {
    param([string]$Title,[string]$Profile)
    Write-Host ''
    Write-Host ('  ' + ('=' * 58)) -ForegroundColor DarkCyan
    Write-Host ("   JOHN OS  ·  $Title") -ForegroundColor Cyan
    if ($Profile) { Write-Host ("   Profile: $Profile") -ForegroundColor DarkCyan }
    Write-Host ('  ' + ('=' * 58)) -ForegroundColor DarkCyan
    Write-Host ''
}
