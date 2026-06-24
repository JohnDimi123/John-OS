<#
.SYNOPSIS
    John OS — privacy & telemetry reduction (without weakening Defender).
.DESCRIPTION
    Sets telemetry to the edition minimum, turns off advertising ID, tailored
    experiences, activity-history upload, Spotlight/"suggested apps", and online
    speech. DELIBERATELY keeps Defender cloud-delivered protection on by default.
.PARAMETER Profile
    Balanced | Esports | Creator.
.PARAMETER ReduceCloudProtection
    Optional. If set, also lowers Defender MAPS reporting for max privacy. This
    WEAKENS cloud detection and is OFF by default with a warning.
.EXAMPLE
    .\08-privacy-telemetry.ps1 -Profile Balanced -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced',
    [switch]$ReduceCloudProtection
)

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Privacy & telemetry' $Profile

# --- Diagnostic data to edition minimum -------------------------------------
$dc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
Set-RegValue $dc 'AllowTelemetry' 0 'DWord' $PSCmdlet               # 0=Security (Pro/Ent honor it)
Set-RegValue $dc 'DoNotShowFeedbackNotifications' 1 'DWord' $PSCmdlet

# --- Advertising ID + tailored experiences ----------------------------------
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 0 'DWord' $PSCmdlet

# --- Activity history (Timeline) upload off ---------------------------------
$sys = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
Set-RegValue $sys 'EnableActivityFeed' 0 'DWord' $PSCmdlet
Set-RegValue $sys 'PublishUserActivities' 0 'DWord' $PSCmdlet
Set-RegValue $sys 'UploadUserActivities' 0 'DWord' $PSCmdlet

# --- Spotlight / suggested apps / consumer features -------------------------
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($v in 'SilentInstalledAppsEnabled','OemPreInstalledAppsEnabled','PreInstalledAppsEnabled',
                'SubscribedContent-310093Enabled','SubscribedContent-338388Enabled',
                'SubscribedContent-338389Enabled','SystemPaneSuggestionsEnabled',
                'RotatingLockScreenOverlayEnabled','SoftLandingEnabled') {
    Set-RegValue $cdm $v 0 'DWord' $PSCmdlet
}
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 'DWord' $PSCmdlet
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1 'DWord' $PSCmdlet

# --- Online speech + inking/typing personalization --------------------------
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Speech' 'AllowSpeechModelUpdate' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1 'DWord' $PSCmdlet
Set-RegValue 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1 'DWord' $PSCmdlet

# --- Telemetry services (defense in depth with script 02) -------------------
Set-ServiceStartup -Name 'DiagTrack'        -StartupType Disabled -Cmdlet $PSCmdlet
Set-ServiceStartup -Name 'dmwappushservice' -StartupType Disabled -Cmdlet $PSCmdlet

# --- Optional: lower Defender cloud reporting (OFF by default) ---------------
if ($ReduceCloudProtection) {
    Write-JohnLog "WARNING: reducing Defender MAPS/cloud reporting WEAKENS cloud detection." 'WARN'
    if ($PSCmdlet.ShouldProcess('Defender MAPS','Set to Basic (privacy > cloud detection)')) {
        try { Set-MpPreference -MAPSReporting Basic -SubmitSamplesConsent NeverSend
              Write-JohnLog "Defender cloud reporting reduced by explicit request." 'WARN' }
        catch { Write-JohnLog "MAPS change note: $($_.Exception.Message)" 'WARN' }
    }
} else {
    Write-JohnLog "Defender cloud-delivered protection LEFT ON (privacy hardened elsewhere)." 'OK'
}

Write-JohnLog "Privacy/telemetry reduction complete." 'OK'
