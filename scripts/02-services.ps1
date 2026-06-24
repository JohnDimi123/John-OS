<#
.SYNOPSIS
    John OS — service tuning (Manual-first, gaming + security services retained).
.DESCRIPTION
    Sets a CURATED set of non-essential services to Manual/Disabled. Prefers
    Manual (trigger-start) over Disabled so Windows can still start a service on
    demand. NEVER touches Defender, Firewall, Windows Update, audio, Themes,
    Search, or Xbox/Gaming services.
.PARAMETER Profile
    Balanced | Esports | Creator.
.EXAMPLE
    .\02-services.ps1 -Profile Esports -WhatIf
.NOTES
    Rationale: docs/02-performance-optimizations.md section 1.
#>
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Services' $Profile

# Hard protect-list — these are never altered by John OS.
$Protected = @(
    'WinDefend','Sense','WdNisSvc','SecurityHealthService','wscsvc',     # Defender/Security Center
    'mpssvc','BFE',                                                       # Firewall
    'wuauserv','UsoSvc','BITS','DoSvc','TrustedInstaller',                # Windows Update / servicing
    'Audiosrv','AudioEndpointBuilder','Themes','WSearch',                 # audio / theming / search
    'Dhcp','Dnscache','NlaSvc','netprofm','nsi',                          # networking core
    'XblAuthManager','XblGameSave','XboxGipSvc','XboxNetApiSvc',          # Xbox (gaming)
    'GamingServices','GamingServicesNet',                                 # Game Pass
    'CryptSvc','gpsvc','ProfSvc','Power','PlugPlay','Schedule','EventLog'
)

# Disable (safe): telemetry, remote attack surface, irrelevant features.
$Disable = @(
    'DiagTrack','dmwappushservice','RemoteRegistry','WMPNetworkSvc',
    'RetailDemo','MapsBroker','lfsvc','Fax'
)

# Manual (trigger-start): on-demand features.
$Manual = @(
    'DPS','WdiServiceHost','WdiSystemHost','PcaSvc','SEMgrSvc',
    'CDPSvc','PhoneSvc','wisvc','TabletInputService','MessagingService',
    'PimIndexMaintenanceSvc','OneSyncSvc','WpcMonSvc'
)

# Print spooler: disable only if no REAL printer exists (ignore the built-in
# Microsoft virtual printers so we still get the PrintNightmare-class hardening).
$virtual = 'Microsoft Print to PDF','Microsoft XPS Document Writer','Fax','OneNote*'
$realPrinters = Get-Printer -ErrorAction SilentlyContinue | Where-Object {
    $name = $_.Name; -not ($virtual | Where-Object { $name -like $_ })
}
if (-not $realPrinters) { $Disable += 'Spooler'; Write-JohnLog "No physical printer -> Print Spooler will be disabled (security)." 'INFO' }
else { Write-JohnLog "Physical printer detected ($($realPrinters.Name -join ', ')) -> keeping Print Spooler." 'INFO' }

# SysMain: kept enabled in Balanced/Creator (SSD myth); Manual only in Esports.
if ($Profile -eq 'Esports') { $Manual += 'SysMain' }
else { Write-JohnLog "SysMain kept enabled (modern Win11/SSD — see perf doc 1.2)." 'INFO' }

# Creator keeps more device/sync services intact for capture hardware.
if ($Profile -eq 'Creator') {
    $Manual = $Manual | Where-Object { $_ -notin @('CDPSvc','OneSyncSvc','MessagingService') }
}

function Apply($list,$type){
    foreach ($s in ($list | Sort-Object -Unique)) {
        if ($Protected -contains $s) { Write-JohnLog "guard: refusing to touch protected '$s'" 'WARN'; continue }
        Set-ServiceStartup -Name $s -StartupType $type -Cmdlet $PSCmdlet
    }
}

Apply $Disable 'Disabled'
Apply $Manual  'Manual'

Write-JohnLog "Service tuning complete. Gaming + security services left intact." 'OK'
