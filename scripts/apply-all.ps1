<#
.SYNOPSIS
    John OS — master orchestrator. Applies the full tuning layer in order.
.DESCRIPTION
    Runs every John OS tuning script for the chosen profile. Creates a System
    Restore point first. Honors -WhatIf end-to-end (preview without changes).
    Safe to re-run (idempotent). Use 99-restore-defaults.ps1 to revert.
.PARAMETER Profile
    Balanced (default) | Esports | Creator.
.PARAMETER DisableVBS
    Esports only — passes through to security script as a documented opt-in.
.PARAMETER SetDns
    Optional: Cloudflare | Google | Quad9 | None (default).
.PARAMETER Unattended
    Suppress interactive prompts (used by SetupComplete.cmd during image build).
.PARAMETER Skip
    Comma-separated step numbers to skip, e.g. -Skip 01,04.
.EXAMPLE
    .\apply-all.ps1 -Profile Balanced -WhatIf      # preview everything
.EXAMPLE
    .\apply-all.ps1 -Profile Esports -SetDns Cloudflare
.NOTES
    Read README.md and docs/ before running on a system you care about.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced',
    [switch]$DisableVBS,
    [ValidateSet('Cloudflare','Google','Quad9','None')][string]$SetDns='None',
    [switch]$Unattended,
    [string[]]$Skip=@()
)

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'apply-all — full tuning layer' $Profile
Write-JohnLog "WhatIf preview: $([bool]$WhatIfPreference) | Unattended: $([bool]$Unattended)" 'INFO'

# --- Pre-flight: System Restore point ---------------------------------------
if (-not $WhatIfPreference) {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "John OS $Profile (pre-tuning)" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-JohnLog "System Restore point created." 'OK'
    } catch { Write-JohnLog "Could not create restore point: $($_.Exception.Message). Continuing." 'WARN' }
} else { Write-JohnLog "WhatIf: skipping restore-point creation." 'WHATIF' }

# --- Step plan --------------------------------------------------------------
$common = @{ Profile = $Profile }
if ($WhatIfPreference) { $common['WhatIf'] = $true }

$steps = @(
    @{ Id='01'; Name='Debloat apps';        Script='01-debloat-apps.ps1';        Args=$common },
    @{ Id='02'; Name='Services';            Script='02-services.ps1';            Args=$common },
    @{ Id='03'; Name='Registry performance';Script='03-registry-performance.ps1';Args=$common },
    @{ Id='04'; Name='Network';             Script='04-network-optimization.ps1';Args=($common + @{ SetDns=$SetDns }) },
    @{ Id='05'; Name='Power plan';          Script='05-power-plan.ps1';          Args=$common },
    @{ Id='06'; Name='Security hardening';  Script='06-security-hardening.ps1';  Args=($common + @{ DisableVBS=[bool]$DisableVBS }) },
    @{ Id='07'; Name='Gaming features';     Script='07-gaming-features.ps1';     Args=$common },
    @{ Id='08'; Name='Privacy & telemetry'; Script='08-privacy-telemetry.ps1';   Args=$common },
    @{ Id='09'; Name='Scheduled tasks';     Script='09-scheduled-tasks.ps1';     Args=$common }
)

$failed = @()
foreach ($s in $steps) {
    if ($Skip -contains $s.Id) { Write-JohnLog "Skipping step $($s.Id) ($($s.Name)) by request." 'SKIP'; continue }
    Write-Host ''
    Write-JohnLog ">>> Step $($s.Id): $($s.Name)" 'INFO'
    $path = Join-Path $PSScriptRoot $s.Script
    if (-not (Test-Path $path)) { Write-JohnLog "Missing script: $($s.Script)" 'ERROR'; $failed += $s.Id; continue }
    $stepArgs = $s.Args                      # splatting requires a variable, not an expression
    try { & $path @stepArgs }
    catch { Write-JohnLog "Step $($s.Id) error: $($_.Exception.Message)" 'ERROR'; $failed += $s.Id }
}

# --- Summary ----------------------------------------------------------------
Write-Host ''
if ($failed.Count -eq 0) {
    Write-JohnLog "ALL STEPS COMPLETE for profile '$Profile'." 'OK'
} else {
    Write-JohnLog "Completed with issues in steps: $($failed -join ', '). Review the log above." 'WARN'
}
Write-JohnLog "Log: $JohnOSLog | Backups: $JohnOSBackups" 'INFO'
Write-JohnLog "Revert anytime: .\99-restore-defaults.ps1" 'INFO'
if (-not $WhatIfPreference -and -not $Unattended) {
    Write-JohnLog "A reboot is recommended to apply all changes." 'INFO'
}
