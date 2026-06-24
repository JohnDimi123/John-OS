<#
.SYNOPSIS
    John OS — performance registry tuning (documented keys only, backed up).
.DESCRIPTION
    Applies foreground/MMCSS/HAGS/memory/input registry optimizations. Every
    value is documented in docs/02-performance-optimizations.md, backed up to
    %ProgramData%\JohnOS\backups before change, and reversible.
.PARAMETER Profile
    Balanced | Esports | Creator.
.EXAMPLE
    .\03-registry-performance.ps1 -Profile Balanced -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Registry — performance' $Profile

$ramGB = Get-InstalledRamGB
Write-JohnLog "Detected RAM: ${ramGB} GB; Profile: $Profile" 'INFO'

# --- CPU scheduling: foreground boost --------------------------------------
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' `
    'Win32PrioritySeparation' 0x26 'DWord' $PSCmdlet

# --- MMCSS Games task -------------------------------------------------------
$games = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
Set-RegValue $games 'GPU Priority'        8       'DWord'  $PSCmdlet
Set-RegValue $games 'Priority'            6       'DWord'  $PSCmdlet
Set-RegValue $games 'Scheduling Category' 'High'  'String' $PSCmdlet
Set-RegValue $games 'SFIO Priority'       'High'  'String' $PSCmdlet

# --- System responsiveness + network throttle ------------------------------
$mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
# 10 favors foreground without starving audio; Esports may use 0 (audio caveat).
$resp = if ($Profile -eq 'Esports') { 0 } else { 10 }
if ($resp -eq 0) { Write-JohnLog "SystemResponsiveness=0 (Esports): may affect audio threads under load." 'WARN' }
Set-RegValue $mm 'SystemResponsiveness'   $resp        'DWord' $PSCmdlet
Set-RegValue $mm 'NetworkThrottlingIndex' 0xFFFFFFFF   'DWord' $PSCmdlet

# --- GPU scheduling (HAGS) --------------------------------------------------
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
    'HwSchMode' 2 'DWord' $PSCmdlet

# --- Memory management ------------------------------------------------------
$mem = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
if ($ramGB -ge 16) {
    Set-RegValue $mem 'DisablePagingExecutive' 1 'DWord' $PSCmdlet   # keep kernel resident
} else {
    Write-JohnLog "RAM < 16 GB -> leaving DisablePagingExecutive at default (safe)." 'SKIP'
}
Set-RegValue $mem 'LargeSystemCache'       0 'DWord' $PSCmdlet
Set-RegValue $mem 'ClearPageFileAtShutdown' 0 'DWord' $PSCmdlet
# NOTE: pagefile is intentionally LEFT ENABLED (never disabled).

# --- Power throttling off (per-process) -------------------------------------
if (-not (Test-IsLaptop)) {
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' `
        'PowerThrottlingOff' 1 'DWord' $PSCmdlet
} else {
    Write-JohnLog "Laptop detected -> leaving Power Throttling at default (battery)." 'SKIP'
}

# --- Storage: NTFS last-access off -----------------------------------------
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
    'NtfsDisableLastAccessUpdate' 0x80000001 'DWord' $PSCmdlet

# --- Input: disable mouse acceleration (per-user) --------------------------
$mouse = 'HKCU:\Control Panel\Mouse'
Set-RegValue $mouse 'MouseSpeed'      '0' 'String' $PSCmdlet
Set-RegValue $mouse 'MouseThreshold1' '0' 'String' $PSCmdlet
Set-RegValue $mouse 'MouseThreshold2' '0' 'String' $PSCmdlet

# --- Startup delay + UI snappiness (perceived) -----------------------------
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' `
    'StartupDelayInMSec' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String' $PSCmdlet

if ($Profile -eq 'Esports') {
    # Trim DWM transparency for a hair less overhead.
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
        'EnableTransparency' 0 'DWord' $PSCmdlet
}

Write-JohnLog "Registry performance tuning complete. Backups in $JohnOSBackups." 'OK'
Write-JohnLog "Left at default on purpose: TdrDelay/TdrLevel, CPU C-states, pagefile." 'INFO'
