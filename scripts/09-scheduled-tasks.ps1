<#
.SYNOPSIS
    John OS — disable telemetry/CEIP/feedback scheduled tasks only.
.DESCRIPTION
    Disables a CURATED list of telemetry tasks. Explicitly does NOT touch
    maintenance, Defender, Windows Update, .NET NGEN, SSD defrag/TRIM, or
    System Restore tasks. Disabled tasks are re-enabled by 99-restore-defaults.
.PARAMETER Profile
    Balanced | Esports | Creator.
.EXAMPLE
    .\09-scheduled-tasks.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Scheduled tasks (telemetry only)' $Profile

# Telemetry / CEIP / feedback tasks — safe to disable.
$Disable = @(
    @{P='\Microsoft\Windows\Application Experience'; N='Microsoft Compatibility Appraiser'},
    @{P='\Microsoft\Windows\Application Experience'; N='ProgramDataUpdater'},
    @{P='\Microsoft\Windows\Application Experience'; N='StartupAppTask'},
    @{P='\Microsoft\Windows\Customer Experience Improvement Program'; N='Consolidator'},
    @{P='\Microsoft\Windows\Customer Experience Improvement Program'; N='UsbCeip'},
    @{P='\Microsoft\Windows\Autochk'; N='Proxy'},
    @{P='\Microsoft\Windows\Feedback\Siuf'; N='DmClient'},
    @{P='\Microsoft\Windows\Feedback\Siuf'; N='DmClientOnScenarioDownload'},
    @{P='\Microsoft\Windows\Windows Error Reporting'; N='QueueReporting'},
    @{P='\Microsoft\Windows\Maps'; N='MapsToastTask'},
    @{P='\Microsoft\Windows\Maps'; N='MapsUpdateTask'}
)

# Hard protect-list — never disable these (performance/security/servicing).
$ProtectNames = @(
    'ScheduledDefrag','.NET Framework NGEN','SR','MpScheduledScan',
    'Windows Defender','UpdateOrchestrator','Scheduled Start'
)

foreach ($t in $Disable) {
    if ($ProtectNames | Where-Object { $t.N -like "*$_*" }) {
        Write-JohnLog "guard: refusing to disable protected task '$($t.N)'" 'WARN'; continue
    }
    $task = Get-ScheduledTask -TaskPath ($t.P + '\') -TaskName $t.N -ErrorAction SilentlyContinue
    if (-not $task) { Write-JohnLog "task not present: $($t.P)\$($t.N)" 'SKIP'; continue }
    if ($task.State -eq 'Disabled') { Write-JohnLog "already disabled: $($t.N)" 'SKIP'; continue }
    if ($PSCmdlet.ShouldProcess("$($t.P)\$($t.N)",'Disable-ScheduledTask')) {
        try { Disable-ScheduledTask -TaskPath ($t.P + '\') -TaskName $t.N -ErrorAction Stop | Out-Null
              Write-JohnLog "disabled task: $($t.N)" 'OK' }
        catch { Write-JohnLog "could not disable $($t.N): $($_.Exception.Message)" 'WARN' }
    } else { Write-JohnLog "would disable task: $($t.N)" 'WHATIF' }
}

Write-JohnLog "Scheduled-task trim complete. Maintenance/Defender/Update/NGEN/Defrag KEPT." 'OK'
