<#
.SYNOPSIS
    John OS — revert tuning back to Windows defaults.
.DESCRIPTION
    Re-enables trimmed services, re-enables disabled scheduled tasks, restores
    the .reg backups John OS created, removes the Ultimate Performance plan
    selection (back to Balanced), and re-asserts the security baseline (Defender
    on, VBS on). Use this to return a machine to stock behavior.
.EXAMPLE
    .\99-restore-defaults.ps1 -WhatIf
.NOTES
    Registry restore replays the .reg files in %ProgramData%\JohnOS\backups.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param()

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Restore Windows defaults' ''

# --- 1) Replay registry backups (newest per key) ----------------------------
if (Test-Path $JohnOSBackups) {
    $regFiles = Get-ChildItem $JohnOSBackups -Filter '*.reg' -ErrorAction SilentlyContinue
    foreach ($f in $regFiles) {
        if ($PSCmdlet.ShouldProcess($f.Name,'reg import (restore)')) {
            & reg.exe import $f.FullName *>$null
            Write-JohnLog "restored: $($f.Name)" 'OK'
        } else { Write-JohnLog "would restore: $($f.Name)" 'WHATIF' }
    }
} else { Write-JohnLog "No backup folder found; skipping registry restore." 'WARN' }

# --- 2) Re-enable services to Windows defaults ------------------------------
$defaults = @{
    'DiagTrack'='Automatic'; 'dmwappushservice'='Manual'; 'RemoteRegistry'='Disabled';
    'WMPNetworkSvc'='Manual'; 'MapsBroker'='Automatic'; 'lfsvc'='Manual';
    'SysMain'='Automatic'; 'Spooler'='Automatic'; 'WSearch'='Automatic';
    'DPS'='Automatic'; 'WdiServiceHost'='Manual'; 'PcaSvc'='Automatic';
    'TabletInputService'='Manual'; 'Fax'='Manual'
}
foreach ($s in $defaults.Keys) { Set-ServiceStartup -Name $s -StartupType $defaults[$s] -Cmdlet $PSCmdlet }

# --- 3) Re-enable scheduled tasks -------------------------------------------
$tasks = @(
    @{P='\Microsoft\Windows\Application Experience\'; N='Microsoft Compatibility Appraiser'},
    @{P='\Microsoft\Windows\Application Experience\'; N='ProgramDataUpdater'},
    @{P='\Microsoft\Windows\Customer Experience Improvement Program\'; N='Consolidator'},
    @{P='\Microsoft\Windows\Customer Experience Improvement Program\'; N='UsbCeip'},
    @{P='\Microsoft\Windows\Feedback\Siuf\'; N='DmClient'},
    @{P='\Microsoft\Windows\Windows Error Reporting\'; N='QueueReporting'}
)
foreach ($t in $tasks) {
    $task = Get-ScheduledTask -TaskPath $t.P -TaskName $t.N -ErrorAction SilentlyContinue
    if ($task -and $PSCmdlet.ShouldProcess("$($t.P)$($t.N)",'Enable-ScheduledTask')) {
        try { Enable-ScheduledTask -TaskPath $t.P -TaskName $t.N -ErrorAction Stop | Out-Null
              Write-JohnLog "re-enabled task: $($t.N)" 'OK' } catch {}
    }
}

# --- 4) Power plan back to Balanced -----------------------------------------
if ($PSCmdlet.ShouldProcess('Power plan','Activate Balanced (SCHEME_BALANCED)')) {
    powercfg /setactive SCHEME_BALANCED *>$null
    Write-JohnLog "Active power scheme -> Balanced." 'OK'
}

# --- 5) Re-assert security baseline -----------------------------------------
if ($PSCmdlet.ShouldProcess('Security baseline','Defender ON, VBS ON, Firewall ON')) {
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' `
            'Enabled' 1 'DWord' $PSCmdlet
        Write-JohnLog "Security baseline re-asserted (Defender/Firewall/VBS ON)." 'OK'
    } catch { Write-JohnLog "Security re-assert note: $($_.Exception.Message)" 'WARN' }
}

Write-JohnLog "Restore complete. Reboot recommended. Removed apps: reinstall via Store/winget." 'OK'
