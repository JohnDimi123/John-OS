<#
.SYNOPSIS
    John OS — remove curated consumer Appx packages (debloat).
.DESCRIPTION
    Removes a CURATED list of consumer apps for the current user and from the
    provisioned image (so new users don't get them). Keeps everything games and
    launchers depend on (Store, Xbox/Gaming Services, WebView2, VC++/.NET, etc.).
    Fully reversible: removed apps can be reinstalled from the Store or winget.
.PARAMETER Profile
    Balanced | Esports | Creator. Creator keeps content-creation apps.
.EXAMPLE
    .\01-debloat-apps.ps1 -Profile Balanced -WhatIf
.NOTES
    See docs/04-debloating.md for rationale and the full keep-list.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Debloat — consumer apps' $Profile

# --- Apps removed in ALL profiles ------------------------------------------
$Remove = @(
    'Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch',
    'Microsoft.GetHelp','Microsoft.Getstarted',
    'Microsoft.MicrosoftOfficeHub','Microsoft.Office.OneNote',
    'Microsoft.MicrosoftSolitaireCollection','Microsoft.Todos',
    'Microsoft.MixedReality.Portal','Microsoft.People',
    'Microsoft.SkypeApp','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps',
    'MicrosoftCorporationII.MicrosoftFamily','Microsoft.PowerAutomateDesktop',
    'MicrosoftCorporationII.QuickAssist','MicrosoftTeams','MSTeams',
    'Microsoft.549981C3F5F10'   # Cortana
)

# --- Apps removed only in non-Creator profiles -----------------------------
if ($Profile -ne 'Creator') {
    $Remove += @(
        'Microsoft.MicrosoftStickyNotes','Clipchamp.Clipchamp',
        'Microsoft.ZuneVideo','Microsoft.ZuneMusic',
        'microsoft.windowscommunicationsapps','Microsoft.YourPhone'
    )
}

# --- NEVER remove (safety guard) -------------------------------------------
$Keep = @(
    'Microsoft.DesktopAppInstaller','Microsoft.WindowsStore','Microsoft.StorePurchaseApp',
    'Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.XboxGamingOverlay',
    'Microsoft.XboxGameOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.Xbox.TCUI','Microsoft.Win32WebViewHost','Microsoft.WebpPlatform',
    'Microsoft.VCLibs','Microsoft.NET','Microsoft.UI.Xaml','Microsoft.WindowsTerminal',
    'Microsoft.Windows.Photos','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad',
    'Microsoft.ScreenSketch','Microsoft.SecHealthUI','Microsoft.WindowsStore'
)

function Test-Keep([string]$name){ foreach($k in $Keep){ if($name -like "$k*"){return $true} } return $false }

$removed = 0
foreach ($pkg in $Remove) {
    if (Test-Keep $pkg) { Write-JohnLog "guard: refusing to remove protected '$pkg'" 'WARN'; continue }

    # Per-user installed package
    Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.PackageFullName,'Remove-AppxPackage')) {
            try { Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop
                  Write-JohnLog "removed (user): $($_.Name)" 'OK'; $removed++ }
            catch { Write-JohnLog "skip (user) $($_.Name): $($_.Exception.Message)" 'WARN' }
        } else { Write-JohnLog "would remove (user): $($_.Name)" 'WHATIF' }
    }

    # Provisioned (affects new users)
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like "$pkg*" | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.PackageName,'Remove-AppxProvisionedPackage')) {
            try { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null
                  Write-JohnLog "removed (provisioned): $($_.DisplayName)" 'OK' }
            catch { Write-JohnLog "skip (prov) $($_.DisplayName): $($_.Exception.Message)" 'WARN' }
        } else { Write-JohnLog "would remove (provisioned): $($_.DisplayName)" 'WHATIF' }
    }
}

Write-JohnLog "Debloat pass complete. Apps removed (user): $removed" 'OK'
Write-JohnLog "Kept all game/launcher plumbing (Store, Xbox/Gaming Services, WebView2, VC++/.NET)." 'INFO'
