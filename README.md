# John OS

> A custom Windows 11–based gaming operating system engineered for maximum FPS, minimum latency, and professional-grade security.

**John OS** is a debloated, hardened, and performance-tuned Windows 11 image built for gaming, esports, streaming, and high-performance workloads — while remaining stable enough for daily use and secure enough for real life.

This repository is the **complete specification and implementation plan**: design documents, reproducible PowerShell tuning scripts, an unattended-install answer file, branding assets, and the ISO build roadmap.

---

## ⚠️ Read this first

- John OS is a **set of customizations applied to a legitimate, licensed Windows 11 installation**. You must supply your own genuine Windows 11 ISO and a valid license. This project distributes **no Microsoft binaries**.
- Every optimization here is chosen to be **safe, reversible, and stability-preserving**. Nothing in this project overclocks hardware, disables Windows Update, removes Microsoft Defender, or uses anti-cheat-flagged tools.
- Some tweaks involve a genuine **security-vs-performance trade-off** (most notably Virtualization-Based Security). These are always called out explicitly so you can make an informed choice.
- Always test in a virtual machine and create a recovery image before deploying to real hardware.

---

## Design philosophy

| Principle | What it means in John OS |
|---|---|
| **Built on Windows 11** | 100% compatible base; no kernel patching, no pirated components. |
| **Debloated, not broken** | Remove consumer cruft and telemetry, keep everything games and launchers need. |
| **Performance-first** | Every safe lever for FPS, latency, frame pacing, boot and load times is pulled. |
| **Secure by default** | Defender, Firewall, SmartScreen, Secure Boot, TPM, exploit protection all stay on. |
| **Stable for daily use** | No hardware-damaging or update-breaking tweaks. Fully reversible. |
| **Honest about results** | Realistic benchmark expectations, not marketing numbers. |

---

## Repository layout

```
John-OS/
├── README.md                       ← you are here
├── docs/
│   ├── 01-technical-specification.md
│   ├── 02-performance-optimizations.md
│   ├── 03-security.md
│   ├── 04-debloating.md
│   ├── 05-gaming-features.md
│   ├── 06-included-utilities.md
│   ├── 07-branding-and-ui.md
│   ├── 08-iso-build-process.md
│   ├── 09-benchmark-goals.md
│   ├── 10-risk-and-compatibility.md
│   └── 11-competitive-gaming-defaults.md
├── checklists/
│   ├── optimization-checklist.md
│   ├── security-checklist.md
│   └── debloat-checklist.md
├── scripts/
│   ├── README.md
│   ├── apply-all.ps1               ← master orchestrator
│   ├── 01-debloat-apps.ps1
│   ├── 02-services.ps1
│   ├── 03-registry-performance.ps1
│   ├── 04-network-optimization.ps1
│   ├── 05-power-plan.ps1
│   ├── 06-security-hardening.ps1
│   ├── 07-gaming-features.ps1
│   ├── 08-privacy-telemetry.ps1
│   ├── 09-scheduled-tasks.ps1
│   └── 99-restore-defaults.ps1     ← revert path
├── autounattend/
│   └── autounattend.xml            ← unattended OOBE answer file
└── branding/
    ├── branding-concept.md
    └── wallpaper-johnos-concept.svg
```

---

## Deliverables index

| Deliverable | Document |
|---|---|
| Full technical specification | [`docs/01-technical-specification.md`](docs/01-technical-specification.md) |
| Performance optimizations | [`docs/02-performance-optimizations.md`](docs/02-performance-optimizations.md) |
| Security profile | [`docs/03-security.md`](docs/03-security.md) |
| Debloating plan | [`docs/04-debloating.md`](docs/04-debloating.md) |
| Gaming features | [`docs/05-gaming-features.md`](docs/05-gaming-features.md) |
| Included utilities | [`docs/06-included-utilities.md`](docs/06-included-utilities.md) |
| Branding & UI concept | [`docs/07-branding-and-ui.md`](docs/07-branding-and-ui.md) |
| ISO build roadmap | [`docs/08-iso-build-process.md`](docs/08-iso-build-process.md) |
| Benchmark goals | [`docs/09-benchmark-goals.md`](docs/09-benchmark-goals.md) |
| Risk & compatibility analysis | [`docs/10-risk-and-compatibility.md`](docs/10-risk-and-compatibility.md) |
| Competitive gaming defaults | [`docs/11-competitive-gaming-defaults.md`](docs/11-competitive-gaming-defaults.md) |
| Optimization checklist | [`checklists/optimization-checklist.md`](checklists/optimization-checklist.md) |
| Security checklist | [`checklists/security-checklist.md`](checklists/security-checklist.md) |
| Debloat checklist | [`checklists/debloat-checklist.md`](checklists/debloat-checklist.md) |

---

## Editions

John OS ships as three tuning **profiles** built from the same image. The profile is just a switch passed to the tuning scripts — the underlying OS is identical.

| Profile | Target user | Key difference |
|---|---|---|
| **John OS — Balanced** | Daily driver + gaming | All safe tweaks; **VBS/HVCI stays ON**. Best security. |
| **John OS — Esports** | Competitive FPS players | Adds latency-focused defaults; **VBS/HVCI optional OFF** (documented trade-off). |
| **John OS — Creator** | Streaming + gaming | Keeps capture/encoder stacks, balanced power, NVENC/AMF tuned. |

---

## Quick start (for builders)

1. Read [`docs/08-iso-build-process.md`](docs/08-iso-build-process.md).
2. Acquire an official Windows 11 ISO and the Windows ADK.
3. Mount the install image, apply offline debloat + branding.
4. Drop the `scripts/` folder and `autounattend/autounattend.xml` into the image.
5. Rebuild the bootable ISO with `oscdimg`.
6. Test in Hyper-V/VMware, then deploy.

The tuning scripts can also be run **on an existing Windows 11 install** to convert it into a John OS configuration without rebuilding an ISO:

```powershell
# From an elevated PowerShell prompt
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\apply-all.ps1 -Profile Balanced -WhatIf   # preview
.\scripts\apply-all.ps1 -Profile Balanced           # apply
```

> `-WhatIf` previews every change without writing anything. Always preview first.

---

## License & trademarks

The documentation and scripts in this repository are released under the MIT License (see `LICENSE`). "Windows 11", "Xbox", "DirectX", and "DirectStorage" are trademarks of Microsoft Corporation. NVIDIA, AMD, Intel, Steam, Epic Games, Battle.net, Riot, Ubisoft, and EA names are trademarks of their respective owners. John OS is an independent customization project and is **not affiliated with or endorsed by Microsoft** or any other vendor.
