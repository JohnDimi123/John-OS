<#
.SYNOPSIS
    John OS — security hardening (Defender stays ON; gaming-aware tuning).
.DESCRIPTION
    Keeps Microsoft Defender, Firewall, SmartScreen, and the vulnerable-driver
    blocklist fully ENABLED. Tunes Defender to be gaming-friendly (idle/off-hours
    scans, low CPU priority) WITHOUT weakening protection. Enables Controlled
    Folder Access with a curated launcher allow-list. Handles VBS/HVCI as a
    documented, opt-in trade-off (Esports only).
.PARAMETER Profile
    Balanced | Esports | Creator.
.PARAMETER DisableVBS
    Esports ONLY. If supplied, prompts before disabling VBS/HVCI and records the
    choice. Everything else (Secure Boot, TPM, Defender, Firewall) stays on.
.EXAMPLE
    .\06-security-hardening.ps1 -Profile Esports -DisableVBS -WhatIf
.NOTES
    This script will NOT disable Defender, the Firewall, Windows Update, Secure
    Boot, or TPM under any flag. Rationale: docs/03-security.md.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced',
    [switch]$DisableVBS
)

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Security hardening' $Profile

# --- Defender: confirm ON, then gaming-aware tuning (no weakening) -----------
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    Write-JohnLog "Defender real-time: $($mp.RealTimeProtectionEnabled); Tamper: $($mp.IsTamperProtected)" 'INFO'
} catch { Write-JohnLog "Could not query Defender status: $($_.Exception.Message)" 'WARN' }

if ($PSCmdlet.ShouldProcess('Microsoft Defender','Gaming-aware tuning (protection kept ON)')) {
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false             # ensure ON
        Set-MpPreference -EnableLowCpuPriority $true                   # scans yield to foreground
        Set-MpPreference -ScanOnlyIfIdleEnabled $true                  # don't scan mid-match
        Set-MpPreference -ScanScheduleTime 120                         # 02:00 local (minutes past midnight)
        Set-MpPreference -PUAProtection Enabled
        Set-MpPreference -MAPSReporting Advanced                       # cloud protection ON
        Set-MpPreference -SubmitSamplesConsent SendSafeSamples
        Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
        Write-JohnLog "Defender tuned for gaming; real-time + cloud protection remain ON." 'OK'
    } catch { Write-JohnLog "Defender tuning note: $($_.Exception.Message)" 'WARN' }
} else { Write-JohnLog "would tune Defender (keeping protection ON)" 'WHATIF' }

Write-JohnLog "NOTE: John OS ships NO broad Defender exclusions. Shader-cache exclusions are opt-in." 'INFO'

# --- Firewall: ensure ON for all profiles -----------------------------------
if ($PSCmdlet.ShouldProcess('Windows Firewall','Ensure ON (all profiles), inbound block')) {
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True `
            -DefaultInboundAction Block -DefaultOutboundAction Allow -ErrorAction Stop
        Set-NetFirewallProfile -Profile Public -LogBlocked True -ErrorAction SilentlyContinue
        Write-JohnLog "Firewall ON for Domain/Public/Private; inbound default block." 'OK'
    } catch { Write-JohnLog "Firewall note: $($_.Exception.Message)" 'WARN' }
}

# --- SmartScreen + vulnerable driver blocklist ------------------------------
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' `
    'EnableSmartScreen' 1 'DWord' $PSCmdlet
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config' `
    'VulnerableDriverBlocklistEnable' 1 'DWord' $PSCmdlet

# --- Controlled Folder Access (ransomware) with curated allow-list ----------
if ($PSCmdlet.ShouldProcess('Controlled Folder Access','Enable + allow launchers')) {
    try {
        Set-MpPreference -EnableControlledFolderAccess Enabled
        $allow = @(
            "$env:ProgramFiles(x86)\Steam\steam.exe",
            "$env:ProgramFiles\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe",
            "$env:ProgramFiles\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe",
            "$env:ProgramFiles(x86)\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe",
            "$env:ProgramFiles(x86)\Battle.net\Battle.net.exe",
            "$env:ProgramFiles\Riot Games\Riot Client\RiotClientServices.exe"
        ) | Where-Object { Test-Path $_ }
        foreach ($a in $allow) { Add-MpPreference -ControlledFolderAccessAllowedApplications $a -ErrorAction SilentlyContinue }
        Write-JohnLog "Controlled Folder Access ON; allow-listed $($allow.Count) launcher(s)." 'OK'
    } catch { Write-JohnLog "CFA note: $($_.Exception.Message)" 'WARN' }
}

# --- LSA Protection (credential theft defense) ------------------------------
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'RunAsPPL' 1 'DWord' $PSCmdlet

# --- Report Secure Boot / TPM (never disabled by John OS) -------------------
try { Write-JohnLog "Secure Boot: $([bool](Confirm-SecureBootUEFI))" 'INFO' } catch { Write-JohnLog "Secure Boot state unknown (BIOS/Legacy?)." 'WARN' }
try { Write-JohnLog "TPM present/ready: $((Get-Tpm).TpmPresent)/$((Get-Tpm).TpmReady)" 'INFO' } catch {}

# --- VBS / HVCI: documented opt-in trade-off (Esports only) -----------------
$hvci = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
if ($Profile -ne 'Esports' -or -not $DisableVBS) {
    # Ensure VBS/HVCI ON for Balanced/Creator.
    Set-RegValue $hvci 'Enabled' 1 'DWord' $PSCmdlet
    Write-JohnLog "VBS/HVCI kept ON (full kernel code-integrity protection)." 'OK'
} else {
    Write-JohnLog "-------------------------------------------------------------" 'WARN'
    Write-JohnLog "VBS/HVCI DISABLE requested (Esports). SECURITY TRADE-OFF:" 'WARN'
    Write-JohnLog " - Removes hypervisor-enforced kernel code integrity." 'WARN'
    Write-JohnLog " - Secure Boot, TPM, Defender, Firewall REMAIN ON." 'WARN'
    Write-JohnLog " - Typical gain: ~0-10% in CPU-bound titles; ~0 GPU-bound." 'WARN'
    $ok = $true
    if (-not $WhatIfPreference) {
        $ans = Read-Host "Type 'DISABLE' to confirm, anything else to keep VBS ON"
        $ok = ($ans -eq 'DISABLE')
    }
    if ($ok -and $PSCmdlet.ShouldProcess('VBS/HVCI','Disable (Esports opt-in)')) {
        Set-RegValue $hvci 'Enabled' 0 'DWord' $PSCmdlet
        # Note: fully disabling VBS may also require bcdedit hypervisorlaunchtype off on some systems.
        Write-JohnLog "VBS/HVCI disabled by explicit opt-in. Choice recorded." 'WARN'
        "VBS disabled by user on $(Get-Date) (Esports profile)" | Add-Content (Join-Path $JohnOSRoot 'vbs-choice.txt')
    } else {
        Set-RegValue $hvci 'Enabled' 1 'DWord' $PSCmdlet
        Write-JohnLog "Kept VBS/HVCI ON (no confirmation given)." 'OK'
    }
}

Write-JohnLog "Security hardening complete. Defender/Firewall/SmartScreen/blocklist ON." 'OK'
