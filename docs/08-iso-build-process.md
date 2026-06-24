# John OS — ISO Build Process & Roadmap

A step-by-step, reproducible workflow to turn an **official Windows 11 ISO** into a John OS installation ISO. Everything is done with **Microsoft-supported tooling** (DISM, ADK, oscdimg) so the result remains genuine, Secure-Boot-compatible, and serviceable.

> 🚀 **Want the automated version?** The entire workflow below is wrapped in a single runnable script: [`../iso-build/build-johnos-iso.ps1`](../iso-build/build-johnos-iso.ps1). See [`../iso-build/QUICKSTART.md`](../iso-build/QUICKSTART.md). This document is the manual reference behind that script.

> **Legality:** You must supply your own genuine Windows 11 ISO (from Microsoft) and a valid license. This project redistributes **no Microsoft binaries**. Building a modified image for personal/lab use is fine; redistributing modified Microsoft images is not.

---

## 1. Tools required

| Tool | Purpose | Source |
|---|---|---|
| **Official Windows 11 ISO** | Base image | microsoft.com/software-download/windows11 |
| **Windows ADK** (Deployment Tools) | `DISM`, `oscdimg`, **Windows System Image Manager (WSIM)** | Microsoft ADK download |
| **PowerShell 5.1+ / 7** | Run John OS tuning + image scripts | Built-in |
| **DISM** | Mount/service the image offline | In Windows + ADK |
| **oscdimg** | Rebuild bootable UEFI ISO | ADK Deployment Tools |
| **7-Zip / built-in mount** | Extract ISO contents | 7-zip.org |
| A **VM** (Hyper-V/VMware/VirtualBox) | Test before hardware | — |
| *(Optional)* **NTLite** | GUI image editor (commercial) | ntlite.com |
| *(Optional)* **microwin** (Chris Titus WinUtil) | Open-source guided build | github |

> John OS's canonical path is **scripted DISM + WSIM** (auditable, free, reproducible). NTLite/microwin are listed as optional GUIs for those who prefer them.

---

## 2. High-level workflow

```
Official Win11 ISO
      │  extract
      ▼
sources\install.wim  ──► pick edition (Pro) ──► mount offline (DISM)
      │
      ├─ remove provisioned appx (debloat)
      ├─ disable optional features (SMBv1 verify, IE, etc.)
      ├─ load offline registry hives → inject tuning/telemetry keys
      ├─ /Add-Driver  (integrate drivers)
      ├─ /Add-Package (integrate cumulative + .NET updates)
      ├─ copy branding (wallpaper, lockscreen, oemlogo, theme)
      ├─ copy scripts\  → $OEM$  and  SetupComplete.cmd
      ▼
commit + unmount (DISM /Commit)
      │
      ├─ place autounattend.xml at ISO root
      ▼
oscdimg → John-OS.iso  (bootable, UEFI+Secure Boot)
      │
      ▼
Test in VM  ──►  deploy to hardware
```

---

## 3. Step-by-step

### Step 0 — Workspace
```powershell
$Root   = "C:\JohnOS"
$ISO    = "$Root\Win11.iso"
$Src    = "$Root\src"        # extracted ISO
$Mount  = "$Root\mount"      # offline image mount
New-Item -ItemType Directory -Force $Src,$Mount | Out-Null
```

### Step 1 — Extract the official ISO
Mount the ISO and copy all contents to `$Src` (read/write copy). If `sources\install.esd` exists instead of `install.wim`, convert it:
```powershell
# List editions in the ESD
Dism /Get-WimInfo /WimFile:$Src\sources\install.esd
# Export the Pro edition (index may vary) to a WIM
Dism /Export-Image /SourceImageFile:$Src\sources\install.esd /SourceIndex:6 `
     /DestinationImageFile:$Src\sources\install.wim /Compress:max /CheckIntegrity
Remove-Item $Src\sources\install.esd
```

### Step 2 — Mount the install image (offline servicing)
```powershell
Dism /Mount-Image /ImageFile:$Src\sources\install.wim /Index:1 /MountDir:$Mount
```

### Step 3 — Debloat (remove provisioned appx)
```powershell
# Uses the curated list (see scripts/01-debloat-apps.ps1 $RemoveList)
$RemoveList = Get-Content "$Root\johnos\debloat-list.txt"
Get-AppxProvisionedPackage -Path $Mount |
  Where-Object { $pkg = $_; $RemoveList | Where-Object { $pkg.DisplayName -like $_ } } |
  ForEach-Object { Dism /Image:$Mount /Remove-ProvisionedAppxPackage /PackageName:$($_.PackageName) }
```
> Keep WebView2/Store/Xbox/Gaming Services/VCRedist/.NET (debloat doc §2).

### Step 4 — Optional features
```powershell
Dism /Image:$Mount /Disable-Feature /FeatureName:MicrosoftWindowsPowerShellV2 /Remove
Dism /Image:$Mount /Disable-Feature /FeatureName:WorkFolders-Client /Remove
Dism /Image:$Mount /Disable-Feature /FeatureName:Printing-XPSServices-Features /Remove
# Verify SMB1 is absent (security)
Dism /Image:$Mount /Get-Features | Select-String SMB1
# Keep .NET 3.5 available for old games
Dism /Image:$Mount /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$Src\sources\sxs
```

### Step 5 — Inject registry tuning (offline hives)
Load the offline hives, apply documented keys, unload:
```powershell
reg load HKLM\OFF_SOFT  $Mount\Windows\System32\config\SOFTWARE
reg load HKLM\OFF_SYS   $Mount\Windows\System32\config\SYSTEM
reg load HKLM\OFF_NTU   $Mount\Users\Default\NTUSER.DAT   # default profile → applies to new users

# Example: telemetry + Spotlight off in the default user hive
reg add "HKLM\OFF_SOFT\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\OFF_SOFT\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
reg add "HKLM\OFF_SYS\ControlSet001\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f
# ...full set mirrors scripts/03 & scripts/08...

reg unload HKLM\OFF_SOFT
reg unload HKLM\OFF_SYS
reg unload HKLM\OFF_NTU
```
> Offline injection makes these the **defaults for every new user**, so they don't depend on a logon script.

### Step 6 — Integrate drivers
```powershell
# Recurse a folder of extracted INF drivers (chipset, NIC, storage, GPU)
Dism /Image:$Mount /Add-Driver /Driver:$Root\drivers /Recurse
```
> Inject **chipset, storage (NVMe/RAID), and network** drivers so the installer has them on bare metal. GPU drivers are better installed post-OOBE from the vendor, but can be slipstreamed too.

### Step 7 — Integrate updates
```powershell
# Latest Servicing Stack Update first, then the Cumulative Update (.msu/.cab)
Dism /Image:$Mount /Add-Package /PackagePath:$Root\updates\SSU.msu
Dism /Image:$Mount /Add-Package /PackagePath:$Root\updates\LCU.msu
Dism /Image:$Mount /Cleanup-Image /StartComponentCleanup /ResetBase   # shrink WinSxS
```
> Slipstreaming the latest CU means a freshly installed John OS is patched on first boot — **good for security**. Windows Update remains fully enabled afterward.

### Step 8 — Branding & scripts ($OEM$ + SetupComplete)
```powershell
# Wallpaper / lock screen / OEM logo / theme into the image
Copy-Item $Root\branding\JohnOS-4k.jpg  $Mount\Windows\Web\Wallpaper\JohnOS\ -Force
Copy-Item $Root\branding\JohnOS-lock.jpg $Mount\Windows\Web\Screen\ -Force
Copy-Item $Root\branding\oemlogo.bmp     $Mount\Windows\System32\ -Force

# Tuning scripts staged for post-install
New-Item -ItemType Directory -Force "$Mount\Windows\Setup\Scripts" | Out-Null
Copy-Item $Root\scripts\*  "$Mount\ProgramData\JohnOS\scripts\" -Recurse -Force

# SetupComplete.cmd runs automatically at the end of Setup, before first logon
@'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\JohnOS\scripts\apply-all.ps1" -Profile Balanced -Unattended
'@ | Set-Content "$Mount\Windows\Setup\Scripts\SetupComplete.cmd" -Encoding ASCII
```

### Step 9 — Commit & unmount
```powershell
Dism /Unmount-Image /MountDir:$Mount /Commit
Dism /Cleanup-Wim
```

### Step 10 — Add the answer file & rebuild the ISO
```powershell
Copy-Item $Root\autounattend\autounattend.xml $Src\autounattend.xml -Force

# Rebuild bootable UEFI+BIOS ISO with oscdimg (paths from the ADK)
$oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
& "$oscdimg\oscdimg.exe" -m -o -u2 -udfver102 `
  -bootdata:"2#p0,e,b$Src\boot\etfsboot.com#pEF,e,b$Src\efi\microsoft\boot\efisys.bin" `
  $Src "$Root\John-OS.iso"
```

### Step 11 — Test, then deploy
- Boot `John-OS.iso` in a **VM with Secure Boot + TPM enabled** (Hyper-V Gen 2). Verify OOBE, debloat, tuning, branding, launcher install.
- Validate anti-cheat-relevant state: `Confirm-SecureBootUEFI`, `Get-Tpm`, driver signature enforcement.
- Only then write to USB (Rufus, **keep GPT/UEFI, Secure Boot on**) and install on hardware.

---

## 4. Unattended installation (autounattend.xml)

Built in **WSIM** against the install image; shipped in [`autounattend/autounattend.xml`](../autounattend/autounattend.xml). It:
- Accepts EULA, sets language/region/keyboard.
- Partitions (GPT/UEFI: EFI + MSR + Windows + optional recovery).
- Selects the **Pro** edition/index.
- Skips OOBE upsell pages; sets privacy toggles to John OS defaults (location off, tailored ads off, diagnostics minimal).
- Creates a **local admin** + a **standard daily** account (recommended), or supports Microsoft account.
- Runs `FirstLogonCommands` → kicks the John OS tuning + optional winget app install.

> See the answer file's header comments for each setting. The file is a **starter template** — adjust disk layout and accounts to your hardware before mass deployment.

---

## 5. Post-install automation

Two hooks do the work after Setup:

| Hook | Runs as | Does |
|---|---|---|
| `SetupComplete.cmd` | SYSTEM, before first logon | Applies tuning (`apply-all.ps1 -Profile … -Unattended`), OEM info, theme defaults, scheduled-task trim. |
| `FirstLogonCommands` (in autounattend) | First user logon | Applies per-user theme/wallpaper, optional **winget** install of chosen launchers + utilities. |

Example first-logon winget bootstrap (optional, user-curated):
```powershell
winget install --silent --accept-package-agreements --accept-source-agreements `
  Valve.Steam REALiX.HWiNFO Guru3D.RTSS CXWorld.CapFrameX 7zip.7zip Microsoft.PowerToys
```

---

## 6. Update integration strategy (recap)

- **Slipstream** the latest SSU+LCU into the image (Step 7) so day-one is patched.
- Leave **Windows Update fully enabled** post-install; John OS only sets active hours + feature-update deferral (not security-update deferral).
- Driver updates via vendor tools, not WU's optional channel.

---

## 7. Build roadmap (milestones)

| Phase | Deliverable | Exit criteria |
|---|---|---|
| **P0 — Spec** | This repo (done) | Specs + scripts reviewed. |
| **P1 — Scripted live tuning** | `apply-all.ps1` runs clean on a stock Win11 VM | All scripts idempotent, `-WhatIf` accurate, restore works. |
| **P2 — Offline image** | `install.wim` debloated + branded | Boots in VM, launchers work, anti-cheat checks pass. |
| **P3 — Unattended ISO** | `John-OS.iso` end-to-end | Hands-off install → tuned desktop in VM. |
| **P4 — Hardware validation** | Real-PC install | Drivers, Secure Boot/TPM, 3 profiles validated. |
| **P5 — Benchmarks** | Before/after report | Methodology in [`docs/09`](09-benchmark-goals.md). |
| **P6 — Release** | Signed checklist + docs | Risk review ([`docs/10`](10-risk-and-compatibility.md)) signed off. |

Continue to [`docs/09-benchmark-goals.md`](09-benchmark-goals.md).
