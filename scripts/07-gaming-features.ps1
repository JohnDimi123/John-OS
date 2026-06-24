<#
.SYNOPSIS
    John OS — enable + tune the Windows gaming stack.
.DESCRIPTION
    Turns on Game Mode, HAGS, VRR, Auto HDR, and the 24H2 "optimizations for
    windowed games" path. Disables background DVR recording (manual clips still
    work). Verifies TRIM. Leaves the GPU vendor driver/panel to the vendor tools.
.PARAMETER Profile
    Balanced | Esports | Creator. Creator keeps capture stack defaults.
.EXAMPLE
    .\07-gaming-features.ps1 -Profile Esports -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Gaming features' $Profile

# --- Game Mode ON -----------------------------------------------------------
Set-RegValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode'   1 'DWord' $PSCmdlet

# --- HAGS (mirrors script 03; safe to repeat) ------------------------------
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 'DWord' $PSCmdlet

# --- GPU "Game DVR" policy: keep Game Bar, disable BACKGROUND recording -----
# Background DVR adds overhead; manual captures still available.
Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2 'DWord' $PSCmdlet
if ($Profile -ne 'Creator') {
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0 'DWord' $PSCmdlet
    Write-JohnLog "Background DVR recording off (manual Game Bar clips still work)." 'INFO'
} else {
    Write-JohnLog "Creator profile: capture stack left enabled for streaming/recording." 'INFO'
}

# --- "Optimizations for windowed games" (24H2): SwapEffectUpgradeEnable=1 ----
# This is the documented per-user token. Auto HDR and VRR depend on the display
# + GPU and are enabled in Settings > System > Display > Graphics (and the GPU
# panel) — the script instructs the user below rather than guessing magic ints.
Set-RegValue 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' `
    'SwapEffectUpgradeEnable=1;' 'String' $PSCmdlet

# --- Verify TRIM (do not "optimize" SSDs with 3rd-party tools) --------------
try {
    $trim = (& fsutil behavior query DisableDeleteNotify) -join ' '
    Write-JohnLog "TRIM status -> $trim  (0 = enabled, good)" 'INFO'
} catch { Write-JohnLog "Could not query TRIM." 'WARN' }

# --- Esports: suppress notifications during fullscreen (Focus Assist) --------
if ($Profile -eq 'Esports') {
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\QuietHours' 'Enable' 1 'DWord' $PSCmdlet
    Write-JohnLog "Focus Assist set to suppress notifications while gaming fullscreen." 'OK'
}

Write-JohnLog "Gaming stack configured. Install GPU drivers via NVIDIA App / Adrenalin / Intel." 'OK'
Write-JohnLog "Reminder: enable max refresh rate + VRR (G-SYNC/FreeSync) in the GPU panel." 'INFO'
Write-JohnLog "Reminder: enable Resizable BAR / SAM in UEFI (esp. Intel Arc)." 'INFO'
