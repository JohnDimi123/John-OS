# John OS — Full Technical Specification

**Version:** 1.0
**Base OS:** Windows 11 (24H2 / build 26100 or later)
**Document status:** Reference specification

---

## 1. Overview

John OS is a customized Windows 11 image plus a reproducible configuration layer. It is **not** a fork of Windows and does **not** modify protected system binaries, the kernel, or the bootloader in ways that break Secure Boot or anti-cheat. It is best understood as:

```
Genuine Windows 11 (Pro)  +  Offline image customization  +  Post-install tuning layer  =  John OS
```

The entire configuration is expressed as **idempotent PowerShell scripts** and a **WSIM answer file**, so any John OS install can be reproduced, audited, or reverted.

---

## 2. Base image selection

| Decision | Choice | Rationale |
|---|---|---|
| Edition | **Windows 11 Pro** | Group Policy, Hyper-V, BitLocker, and `AllowTelemetry` controls Home lacks. (Enterprise/LTSC is an optional advanced path — see §2.1.) |
| Channel | **General Availability (24H2+)** | Newest gaming stack: DirectStorage 1.2, Auto HDR, improved scheduler, WDDM 3.x. |
| Architecture | **x64** | ARM64 is out of scope for desktop gaming. |
| Activation | User-supplied genuine license | No tampering with activation. |

### 2.1 Optional: Windows 11 IoT Enterprise LTSC
For builders who want the leanest base, **IoT Enterprise LTSC** ships without most consumer apps and without the Store. John OS supports it as an advanced profile, but the **default and recommended base is Pro** because:
- The Microsoft Store and Xbox/Gaming Services are needed for Game Pass and some titles.
- LTSC receives feature updates slowly, lagging the gaming stack.

---

## 3. System architecture layers

```
┌─────────────────────────────────────────────────────────────┐
│  Branding layer                                             │
│  Wallpaper · lock screen · boot (BGRT) logo · theme · icons │
├─────────────────────────────────────────────────────────────┤
│  Application layer                                          │
│  Game launchers · monitoring utilities · GPU control panels │
├─────────────────────────────────────────────────────────────┤
│  Tuning layer  (reversible, scripted)                       │
│  Services · registry · power · network · scheduled tasks    │
├─────────────────────────────────────────────────────────────┤
│  Security layer  (always-on baseline)                       │
│  Defender · Firewall · SmartScreen · Exploit Protection     │
│  Secure Boot · TPM 2.0 · (optional VBS/HVCI)                │
├─────────────────────────────────────────────────────────────┤
│  Debloat layer  (offline, in image)                         │
│  Provisioned appx removed · telemetry reduced               │
├─────────────────────────────────────────────────────────────┤
│  Base OS:  Windows 11 Pro 24H2 (unmodified kernel)          │
└─────────────────────────────────────────────────────────────┘
```

**Key rule:** lower layers are never broken to satisfy higher ones. The security layer is a floor, not a knob — only VBS/HVCI is user-selectable, and that choice is documented at every touch point.

---

## 4. Minimum and recommended hardware

Windows 11 enforces a hardware floor; John OS keeps it (Secure Boot + TPM are required by modern anti-cheats anyway).

| Component | Minimum (Win11 floor) | Recommended for John OS gaming | Esports target |
|---|---|---|---|
| CPU | 2-core, 1 GHz, 64-bit, on [Win11 support list](https://learn.microsoft.com/windows-hardware/design/minimum/supported/windows-11-supported-processors) | 6-core+ (Ryzen 5 / Core i5 13th gen+) | 8-core, high single-thread |
| RAM | 4 GB | 16 GB | 32 GB |
| Storage | 64 GB | NVMe SSD, 1 TB | Gen4 NVMe SSD |
| GPU | DirectX 12, WDDM 2.0 | DX12 Ultimate, 8 GB VRAM | High-refresh-capable |
| Firmware | UEFI, Secure Boot capable | UEFI + Secure Boot ON | + Resizable BAR |
| TPM | TPM 2.0 | TPM 2.0 enabled | TPM 2.0 enabled |
| Display | 720p | 1080p 144 Hz+ | 1080p/1440p 240–360 Hz |
| Network | — | Wired Gigabit | Wired, low-latency |

---

## 5. Configuration profiles

A single image, three behavioral profiles selected at tuning time (`-Profile` switch in `apply-all.ps1`):

### 5.1 Balanced (default)
- All safe performance tweaks.
- **VBS/HVCI ON** — full security.
- Power: Ultimate Performance on AC, balanced on battery (laptops).
- Game Mode on, HAGS on, Reflex/Anti-Lag where supported.
- Target: indistinguishable-from-stock stability with measurable boot, RAM, and latency gains.

### 5.2 Esports
- Everything in Balanced, plus:
- Latency-first defaults: mouse acceleration off, 1000 Hz polling guidance, V-Sync off + VRR cap, exclusive fullscreen preferred.
- **VBS/HVCI optional OFF** (explicit prompt; documents the ~0–10% trade-off).
- Background recording/captures off, notifications suppressed during play.
- Process priority elevation for the foreground game.

### 5.3 Creator
- Everything in Balanced, plus:
- Capture/encoder stacks retained and tuned (NVENC/AMF/QSV).
- Game Bar + Xbox capture kept; OBS-friendly defaults.
- Slightly more conservative on background-service trimming (audio/USB stability for capture devices).

---

## 6. Reversibility & safety model

| Mechanism | Purpose |
|---|---|
| `-WhatIf` on every script | Dry-run preview of all changes. |
| `99-restore-defaults.ps1` | Re-enables services, restores registry defaults, removes John OS power plan. |
| Pre-change **System Restore point** | `apply-all.ps1` creates one automatically before writing. |
| Registry change logging | Each script writes a `.reg` backup of touched keys to `%ProgramData%\JohnOS\backups\`. |
| Recovery image guidance | ISO roadmap instructs capturing a clean recovery `install.wim`. |
| No protected-binary edits | Bootloader, kernel, and Defender binaries are never patched. |

---

## 7. Update strategy

- **Windows Update stays fully functional.** John OS sets the **active-hours** and **"notify before download on metered"** policies and defers *feature* updates (not quality/security) by a configurable window so updates don't interrupt a match — it never disables WU.
- Driver updates flow through **vendor tools** (NVIDIA App, AMD Software, Intel) rather than Windows Update's optional driver channel, which is set to "don't auto-install" to avoid driver regressions mid-season.
- Security definition updates for Defender are **never deferred**.

> Disabling Windows Update is explicitly out of scope — it is the single biggest security mistake in "gaming Windows" builds and John OS rejects it.

---

## 8. Compatibility commitments

John OS guarantees out-of-the-box compatibility with:
- **Anti-cheat:** Easy Anti-Cheat, BattlEye, Riot Vanguard, Activision Ricochet, FACEIT AC, ESEA.
- **Launchers:** Steam, Epic Games, Battle.net, Riot Client, Ubisoft Connect, EA App, Xbox/Game Pass, GOG Galaxy.
- **Runtimes:** DirectX 9/11/12, DirectStorage, Visual C++ 2005–2022 redistributables, .NET Framework 3.5/4.8, .NET 6/7/8 desktop runtimes.
- **Capture/stream:** OBS Studio, NVIDIA/AMD/Intel hardware encoders, Game Bar capture.

See [`docs/10-risk-and-compatibility.md`](10-risk-and-compatibility.md) for the full matrix and the components that must remain in the image.

---

## 9. Non-goals (explicitly excluded)

John OS will **not**:
- Overclock CPU/GPU/RAM or alter voltages/power limits from the OS.
- Disable, neuter, or replace Microsoft Defender.
- Disable or block Windows Update.
- Remove Secure Boot, TPM enforcement, or the bootloader signature chain.
- Bundle pirated software, cracks, or activation bypasses.
- Ship kernel-level "tweak" drivers, timer-resolution hacks that destabilize, or anti-cheat-flagged utilities.
- Disable the pagefile entirely or apply "RAM cleaner" snake-oil.

These are listed because they are the most common ways community "gaming OS" builds become insecure, unstable, or bannable. John OS's value is being fast **without** any of them.
