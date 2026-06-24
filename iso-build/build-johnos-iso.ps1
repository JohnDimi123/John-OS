<#
.SYNOPSIS
    John OS — one-shot custom ISO builder.
.DESCRIPTION
    Turns an official, licensed Windows 11 ISO into a John OS install ISO:
      1. Extracts the ISO to a writable workspace
      2. Resolves/【converts】 install.wim (handles install.esd)
      3. Mounts the image offline (DISM)
      4. Removes curated consumer appx (debloat) with a keep-guard
      5. (optional) slipstreams drivers + updates
      6. Injects a focused set of offline registry defaults
      7. Copies branding + stages the John OS scripts + SetupComplete.cmd
      8. Commits the image and rebuilds a bootable UEFI ISO with oscdimg

    The FULL, reversible, logged tuning pass runs at first boot via
    SetupComplete.cmd -> scripts\apply-all.ps1. This builder only bakes in the
    debloat, branding, and a minimal set of defaults.

.PARAMETER IsoPath
    Path to your official Windows 11 ISO (e.g. C:\Users\you\Downloads\Win11.iso).
.PARAMETER WorkDir
    Scratch workspace (needs ~25 GB free). Default C:\JohnOS-Build.
.PARAMETER OutputIso
    Where to write the finished ISO. Default <WorkDir>\John-OS.iso.
.PARAMETER Edition
    Windows edition/image name to build. Default 'Windows 11 Pro'.
.PARAMETER Profile
    Balanced | Esports | Creator — passed to apply-all at first boot.
.PARAMETER RepoRoot
    John OS repo root (so the builder can find scripts/ branding/ autounattend/).
    Default = the parent folder of this script.
.PARAMETER DriversPath
    Optional folder of extracted .inf drivers to slipstream (recurses).
.PARAMETER UpdatesPath
    Optional folder of .msu/.cab updates to slipstream (SSU before LCU).
.PARAMETER SkipBranding
    Skip copying wallpaper/lock screen/oemlogo even if present.
.EXAMPLE
    # From an ELEVATED PowerShell on Windows, with the ADK installed:
    .\build-johnos-iso.ps1 -IsoPath "$HOME\Downloads\Win11_24H2.iso" -Profile Balanced
.NOTES
    Requirements: Windows 10/11 build host, RUN AS ADMINISTRATOR, Windows ADK
    (Deployment Tools -> provides oscdimg). DISM ships with Windows.
    Read docs/08-iso-build-process.md for the manual walk-through.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$IsoPath,
    [string]$WorkDir   = 'C:\JohnOS-Build',
    [string]$OutputIso,
    [string]$Edition   = 'Windows 11 Pro',
    [ValidateSet('Balanced','Esports','Creator')][string]$Profile = 'Balanced',
    [string]$RepoRoot  = (Split-Path $PSScriptRoot -Parent),
    [string]$DriversPath,
    [string]$UpdatesPath,
    [switch]$SkipBranding
)

$ErrorActionPreference = 'Stop'
# robocopy/reg/oscdimg return non-zero on benign conditions (e.g. robocopy=1 on
# success). On PowerShell 7.4+ that would otherwise throw under -EA Stop, so we
# opt out of native-command error mapping and check exit codes ourselves.
$PSNativeCommandUseErrorActionPreference = $false

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Info($m){ Write-Host "    $m" -ForegroundColor Gray }
function Ok($m){ Write-Host "    [OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "    [!] $m" -ForegroundColor Yellow }

# ---------- Pre-flight ------------------------------------------------------
Step 'Pre-flight checks'

# Admin
$pr = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this from an ELEVATED PowerShell prompt (Run as administrator).'
}
Ok 'Elevated session'

if (-not (Test-Path $IsoPath)) { throw "ISO not found: $IsoPath" }
Ok "ISO: $IsoPath"

# Locate oscdimg (Windows ADK Deployment Tools)
$oscdimg = Get-ChildItem -Path `
    'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools',
    'C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools' `
    -Recurse -Filter 'oscdimg.exe' -ErrorAction SilentlyContinue |
    Where-Object FullName -match 'amd64' | Select-Object -First 1 -ExpandProperty FullName
if (-not $oscdimg) {
    throw "oscdimg.exe not found. Install the Windows ADK (Deployment Tools): https://learn.microsoft.com/windows-hardware/get-started/adk-install"
}
Ok "oscdimg: $oscdimg"

# Repo assets
$ScriptsDir = Join-Path $RepoRoot 'scripts'
$UnattendXml= Join-Path $RepoRoot 'autounattend\autounattend.xml'
$DebloatList= Join-Path $PSScriptRoot 'debloat-list.txt'
foreach ($p in @($ScriptsDir,$UnattendXml,$DebloatList)) {
    if (-not (Test-Path $p)) { throw "Missing repo asset: $p (is -RepoRoot correct?)" }
}
Ok "Repo assets found under $RepoRoot"

# Free space (~25 GB)
$drive = (Split-Path $WorkDir -Qualifier)
$free  = [math]::Round((Get-PSDrive $drive.TrimEnd(':')).Free/1GB,1)
if ($free -lt 25) { Warn "Only ${free} GB free on $drive — recommend >=25 GB. Continuing." }
else { Ok "${free} GB free on $drive" }

$Src   = Join-Path $WorkDir 'src'
$Mount = Join-Path $WorkDir 'mount'
if (-not $OutputIso) { $OutputIso = Join-Path $WorkDir 'John-OS.iso' }
$null = New-Item -ItemType Directory -Force $WorkDir,$Src,$Mount

# ---------- Extract ISO -----------------------------------------------------
Step 'Extracting the Windows ISO'
$img = Mount-DiskImage -ImagePath $IsoPath -PassThru
try {
    $vol = ($img | Get-Volume).DriveLetter
    Info "Mounted at ${vol}:  -> copying to $Src"
    robocopy "${vol}:\" $Src /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed copying the ISO (exit $LASTEXITCODE)." }
} finally {
    Dismount-DiskImage -ImagePath $IsoPath | Out-Null
}
# Make the copied files writable (ISO copies are read-only)
attrib -R "$Src\*.*" /S /D 2>$null
Ok 'ISO extracted'

# ---------- Resolve install.wim (convert from .esd if needed) ---------------
Step 'Resolving install image'
$wim = Join-Path $Src 'sources\install.wim'
$esd = Join-Path $Src 'sources\install.esd'
if (-not (Test-Path $wim) -and (Test-Path $esd)) {
    Info 'install.esd found — locating requested edition and converting to .wim'
    $idx = (Get-WindowsImage -ImagePath $esd | Where-Object ImageName -eq $Edition |
            Select-Object -First 1).ImageIndex
    if (-not $idx) {
        Get-WindowsImage -ImagePath $esd | Format-Table ImageIndex,ImageName -Auto | Out-String | Write-Host
        throw "Edition '$Edition' not found in install.esd (see list above; pass -Edition exactly)."
    }
    Info "Exporting index $idx ('$Edition') -> install.wim (this takes a while)"
    Export-WindowsImage -SourceImagePath $esd -SourceIndex $idx -DestinationImagePath $wim -CompressionType Max | Out-Null
    Remove-Item $esd -Force
}
if (-not (Test-Path $wim)) { throw "No install.wim/.esd found under $Src\sources." }

$index = (Get-WindowsImage -ImagePath $wim | Where-Object ImageName -eq $Edition |
          Select-Object -First 1).ImageIndex
if (-not $index) {
    Get-WindowsImage -ImagePath $wim | Format-Table ImageIndex,ImageName -Auto | Out-String | Write-Host
    throw "Edition '$Edition' not found in install.wim (see list above)."
}
Ok "Building edition '$Edition' (index $index)"

# ---------- Mount image (with guaranteed cleanup) ---------------------------
Step 'Mounting the image (offline servicing)'
Mount-WindowsImage -ImagePath $wim -Index $index -Path $Mount | Out-Null
Ok "Mounted at $Mount"

try {
    # ---------- Debloat ------------------------------------------------------
    Step 'Debloat — removing curated consumer appx'
    $remove = Get-Content $DebloatList | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { $_.Trim() }
    $keepGuard = @('WindowsStore','DesktopAppInstaller','GamingApp','GamingServices','XboxIdentityProvider',
                   'WebViewHost','VCLibs','DotNet','UI.Xaml','SecHealthUI','WindowsTerminal')
    $prov = Get-AppxProvisionedPackage -Path $Mount
    foreach ($pat in $remove) {
        if ($keepGuard | Where-Object { $pat -match $_ }) { Warn "guard: skipping protected '$pat'"; continue }
        $prov | Where-Object DisplayName -like $pat | ForEach-Object {
            try { Remove-AppxProvisionedPackage -Path $Mount -PackageName $_.PackageName | Out-Null
                  Info "removed $($_.DisplayName)" }
            catch { Warn "skip $($_.DisplayName): $($_.Exception.Message)" }
        }
    }
    Ok 'Debloat pass complete (Store/Xbox/WebView2/VC++/.NET kept)'

    # ---------- Drivers (optional) ------------------------------------------
    if ($DriversPath -and (Test-Path $DriversPath)) {
        Step 'Slipstreaming drivers'
        Add-WindowsDriver -Path $Mount -Driver $DriversPath -Recurse | Out-Null
        Ok "Drivers added from $DriversPath"
    }

    # ---------- Updates (optional) ------------------------------------------
    if ($UpdatesPath -and (Test-Path $UpdatesPath)) {
        Step 'Slipstreaming updates (SSU before LCU)'
        Get-ChildItem $UpdatesPath -Include *.msu,*.cab -Recurse |
            Sort-Object { $_.Name -notmatch 'SSU' } | ForEach-Object {
            try { Add-WindowsPackage -Path $Mount -PackagePath $_.FullName | Out-Null; Info "added $($_.Name)" }
            catch { Warn "update $($_.Name): $($_.Exception.Message)" }
        }
        Info 'Cleaning up component store'
        & dism.exe /Image:$Mount /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
        Ok 'Updates slipstreamed'
    }

    # ---------- Offline registry defaults -----------------------------------
    Step 'Injecting offline registry defaults'
    & reg.exe load HKLM\OFF_SOFT "$Mount\Windows\System32\config\SOFTWARE" | Out-Null
    & reg.exe load HKLM\OFF_SYS  "$Mount\Windows\System32\config\SYSTEM"   | Out-Null
    & reg.exe load HKLM\OFF_DEF  "$Mount\Users\Default\NTUSER.DAT"         | Out-Null
    try {
        # Privacy / telemetry (machine)
        reg add 'HKLM\OFF_SOFT\Policies\Microsoft\Windows\DataCollection' /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
        reg add 'HKLM\OFF_SOFT\Policies\Microsoft\Windows\CloudContent'   /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f | Out-Null
        # Performance (machine, offline SYSTEM uses ControlSet001)
        reg add 'HKLM\OFF_SYS\ControlSet001\Control\GraphicsDrivers' /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
        reg add 'HKLM\OFF_SYS\ControlSet001\Control\PriorityControl' /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null
        reg add 'HKLM\OFF_SYS\ControlSet001\Control\FileSystem' /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 2147483649 /f | Out-Null
        # Telemetry services off (offline)
        reg add 'HKLM\OFF_SYS\ControlSet001\Services\DiagTrack' /v Start /t REG_DWORD /d 4 /f | Out-Null
        reg add 'HKLM\OFF_SYS\ControlSet001\Services\dmwappushservice' /v Start /t REG_DWORD /d 4 /f | Out-Null
        # Per-new-user defaults (default user hive)
        reg add 'HKLM\OFF_DEF\Control Panel\Mouse' /v MouseSpeed /d 0 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Control Panel\Mouse' /v MouseThreshold1 /d 0 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Control Panel\Mouse' /v MouseThreshold2 /d 0 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Software\Microsoft\GameBar' /v AutoGameModeEnabled /t REG_DWORD /d 1 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' /v Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' /v AppsUseLightTheme /t REG_DWORD /d 0 /f | Out-Null
        reg add 'HKLM\OFF_DEF\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' /v SystemUsesLightTheme /t REG_DWORD /d 0 /f | Out-Null
        Ok 'Offline defaults written (telemetry off, dark mode, HAGS, foreground boost, mouse accel off)'
    } finally {
        [gc]::Collect(); Start-Sleep 1
        & reg.exe unload HKLM\OFF_DEF  | Out-Null
        & reg.exe unload HKLM\OFF_SYS  | Out-Null
        & reg.exe unload HKLM\OFF_SOFT | Out-Null
    }

    # ---------- Branding -----------------------------------------------------
    if (-not $SkipBranding) {
        Step 'Applying branding'
        $brand = Join-Path $RepoRoot 'branding'
        $wp = Join-Path $Mount 'Windows\Web\Wallpaper\JohnOS'
        $null = New-Item -ItemType Directory -Force $wp
        foreach ($f in 'JohnOS-4k.jpg','JohnOS-lock.jpg','oemlogo.bmp') {
            $s = Join-Path $brand $f
            if (Test-Path $s) { Copy-Item $s $wp -Force; Info "copied $f" }
        }
        if (Test-Path (Join-Path $brand 'oemlogo.bmp')) {
            Copy-Item (Join-Path $brand 'oemlogo.bmp') (Join-Path $Mount 'Windows\System32\oemlogo.bmp') -Force
        }
        Warn 'Rasterize branding/wallpaper-johnos-concept.svg -> JohnOS-4k.jpg / oemlogo.bmp first (see branding/branding-concept.md). Missing files are skipped.'
        Ok 'Branding step done'
    }

    # ---------- Stage scripts + SetupComplete.cmd ---------------------------
    Step 'Staging John OS tuning scripts + first-boot automation'
    $dst = Join-Path $Mount 'ProgramData\JohnOS\scripts'
    $null = New-Item -ItemType Directory -Force $dst
    Copy-Item "$ScriptsDir\*" $dst -Recurse -Force
    $setupScriptsDir = Join-Path $Mount 'Windows\Setup\Scripts'
    $null = New-Item -ItemType Directory -Force $setupScriptsDir
    @"
@echo off
REM John OS first-boot tuning (runs as SYSTEM at the end of Setup)
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\JohnOS\scripts\apply-all.ps1" -Profile $Profile -Unattended >> "C:\ProgramData\JohnOS\setupcomplete.log" 2>&1
"@ | Set-Content (Join-Path $setupScriptsDir 'SetupComplete.cmd') -Encoding ASCII
    Ok "Scripts staged; SetupComplete.cmd will run apply-all -Profile $Profile"

    # ---------- Commit -------------------------------------------------------
    Step 'Committing image'
    Dismount-WindowsImage -Path $Mount -Save | Out-Null
    Ok 'Image committed'
}
catch {
    Warn "Build failed: $($_.Exception.Message)"
    Warn 'Discarding the image mount to leave no stuck mountpoint...'
    Dismount-WindowsImage -Path $Mount -Discard -ErrorAction SilentlyContinue | Out-Null
    throw
}

# ---------- Answer file + rebuild ISO --------------------------------------
Step 'Adding autounattend.xml and rebuilding the ISO'
Copy-Item $UnattendXml (Join-Path $Src 'autounattend.xml') -Force

$etfs = Join-Path $Src 'boot\etfsboot.com'
$efi  = Join-Path $Src 'efi\microsoft\boot\efisys.bin'
$bootdata = "2#p0,e,b$etfs#pEF,e,b$efi"
& $oscdimg -m -o -u2 -udfver102 -bootdata:$bootdata $Src $OutputIso
if (-not (Test-Path $OutputIso)) { throw 'oscdimg did not produce an ISO.' }

Step 'DONE'
Ok "John OS ISO: $OutputIso"
Write-Host @"

Next steps:
  1. Test in a VM FIRST (Hyper-V Gen 2 with Secure Boot + TPM enabled, or
     VMware/VirtualBox with EFI + TPM). Boot the ISO; it installs unattended.
  2. Verify: launchers run, anti-cheat title launches, Defender/Firewall on,
     Confirm-SecureBootUEFI = True, Get-Tpm ready.
  3. Only then write to USB with Rufus (GPT/UEFI). If install.wim > 4 GB and you
     use a FAT32 USB, let Rufus split it.
  4. The full tuning + log appears at C:\ProgramData\JohnOS\ after first boot.

Reminder: edit autounattend.xml (disk target wipes Disk 0, change passwords,
timezone) before deploying to real hardware. See docs/08-iso-build-process.md.
"@ -ForegroundColor Cyan
