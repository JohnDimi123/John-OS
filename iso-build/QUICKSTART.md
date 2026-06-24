# John OS — ISO Build Quickstart

You have a licensed Windows 11 ISO and want to build a custom **John OS** ISO to test in a **VM / another PC**. This is the fast path. Full detail: [`../docs/08-iso-build-process.md`](../docs/08-iso-build-process.md).

> ⚠️ This runs on a **Windows** build machine (your current PC is fine). It does **not** touch your current Windows install — it only reads your ISO and writes a new ISO file. Nothing is wiped on the build PC.

---

## What you need (one-time)

| # | Item | How |
|---|---|---|
| 1 | A Windows 10/11 PC to build on | Your current PC works. |
| 2 | **~25 GB free disk space** | For the scratch workspace. |
| 3 | **Windows ADK — "Deployment Tools"** | Download: search "Windows ADK download" → install → tick **Deployment Tools** (gives `oscdimg`). DISM is already in Windows. |
| 4 | This repo on the build PC | `git clone https://github.com/JohnDimi123/John-OS` or download the ZIP and extract. |
| 5 | Your Windows 11 ISO | The one in your Downloads. |

---

## Build it (3 commands)

Open **PowerShell as Administrator**, then:

```powershell
# 1. Go to the repo's iso-build folder (adjust the path to where you cloned it)
cd C:\John-OS\iso-build

# 2. Allow scripts for this session
Set-ExecutionPolicy -Scope Process Bypass -Force

# 3. Build — point -IsoPath at your ISO in Downloads
.\build-johnos-iso.ps1 -IsoPath "$HOME\Downloads\Win11_24H2.iso" -Profile Balanced
```

That's it. The script will:
1. Extract your ISO to `C:\JohnOS-Build\src`
2. Convert `install.esd → install.wim` if needed
3. Mount the image and **debloat** it (keeping Store/Xbox/WebView2/VC++/.NET)
4. Inject safe defaults (telemetry off, dark mode, HAGS, mouse-accel off)
5. Stage the John OS scripts + a `SetupComplete.cmd` that runs the **full tuning** at first boot
6. Rebuild a bootable ISO → **`C:\JohnOS-Build\John-OS.iso`**

Build time: ~15–40 min depending on disk speed (the ESD→WIM conversion is the slow part).

---

## Common options

```powershell
# Different edition (must match exactly — the script lists choices if wrong)
.\build-johnos-iso.ps1 -IsoPath "...\Win11.iso" -Edition "Windows 11 Pro"

# Esports profile (latency-first; prompts about VBS at first boot)
.\build-johnos-iso.ps1 -IsoPath "...\Win11.iso" -Profile Esports

# Slipstream chipset/NIC/storage drivers and the latest cumulative update
.\build-johnos-iso.ps1 -IsoPath "...\Win11.iso" -DriversPath C:\drivers -UpdatesPath C:\updates

# Custom output path / workspace
.\build-johnos-iso.ps1 -IsoPath "...\Win11.iso" -WorkDir D:\Build -OutputIso D:\John-OS.iso
```

---

## Test it (do this BEFORE real hardware)

1. **Hyper-V** (built into Win11 Pro): create a **Generation 2** VM, enable **Secure Boot** and **TPM** (Security tab → Enable Trusted Platform Module), attach `John-OS.iso`, boot.
   - VMware/VirtualBox also work — use **EFI** firmware and enable a **TPM** device.
2. The install runs **unattended** (the `autounattend.xml` answers the prompts).
3. After it lands on the desktop, verify:
   ```powershell
   Get-MpComputerStatus | Select RealTimeProtectionEnabled, IsTamperProtected   # Defender on
   Confirm-SecureBootUEFI                                                        # True
   Get-Tpm | Select TpmPresent, TpmReady                                         # ready
   Get-Content C:\ProgramData\JohnOS\setupcomplete.log                           # tuning log
   ```
4. Launch a game/launcher and an **anti-cheat** title (Valorant/CS2/Fortnite) to confirm compatibility.

---

## Then deploy to the other PC

- Write `John-OS.iso` to a USB stick with **Rufus** → choose **GPT / UEFI**. If `install.wim` is >4 GB and Rufus uses FAT32, let it **split** the WIM (it offers this automatically).
- ⚠️ **Edit `autounattend/autounattend.xml` first** for real hardware: it targets **Disk 0** and will **wipe it**, and it has **placeholder passwords** and a **UTC timezone**. Change those, rebuild, then deploy.

---

## Branding (optional, before building)

The wallpaper ships as an editable vector. To bake it into the image, rasterize it first:

```powershell
# With Inkscape + ImageMagick installed, from the repo root:
inkscape branding\wallpaper-johnos-concept.svg -w 3840 -h 2160 -o branding\JohnOS-4k.jpg
```

Then the builder copies `branding\JohnOS-4k.jpg` (and `oemlogo.bmp`, `JohnOS-lock.jpg` if present) automatically. Missing files are skipped — the build still succeeds without them.

---

## If something goes wrong

- **"oscdimg.exe not found"** → install the Windows ADK **Deployment Tools** feature.
- **"Edition not found"** → the script prints the available editions; copy the exact `ImageName` into `-Edition`.
- **A mount gets stuck** (rare) → the script auto-discards on failure; if needed, run `Dismount-WindowsImage -Path C:\JohnOS-Build\mount -Discard`.
- **Want to start over** → delete `C:\JohnOS-Build` and re-run.

Prefer not to rebuild an ISO at all? You can also just install stock Windows 11 and run [`../scripts/apply-all.ps1`](../scripts/README.md) on it — same tuning, no image engineering.
