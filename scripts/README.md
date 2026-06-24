# John OS — Tuning Scripts

Idempotent, reversible PowerShell that applies the John OS configuration to a Windows 11 system (live, or staged into an image via `SetupComplete.cmd`).

> ⚠️ **Run from an elevated PowerShell prompt.** Always **preview with `-WhatIf` first.** These scripts change system settings; read the linked docs before applying to a machine you care about.

---

## TL;DR

```powershell
# 1. Allow scripts for this session only
Set-ExecutionPolicy -Scope Process Bypass -Force

# 2. PREVIEW every change (writes nothing)
.\apply-all.ps1 -Profile Balanced -WhatIf

# 3. Apply
.\apply-all.ps1 -Profile Balanced

# 4. Revert to Windows defaults at any time
.\99-restore-defaults.ps1
```

Profiles: `Balanced` (default, VBS on), `Esports` (latency-first, VBS optional off), `Creator` (keeps capture stack).

---

## What each script does

| Script | Purpose | Key safety notes |
|---|---|---|
| `lib/common.ps1` | Shared helpers: admin check, logging, **backup-before-change** registry writes, service helper. | Dot-sourced by all scripts. |
| `apply-all.ps1` | Orchestrates all steps in order; makes a **System Restore point** first. | `-WhatIf`, `-Skip`, `-Unattended`. |
| `01-debloat-apps.ps1` | Removes curated consumer Appx (user + provisioned). | Hard **keep-guard** for Store/Xbox/WebView2/VC++/.NET. |
| `02-services.ps1` | Trims services to **Manual-first**. | Hard **protect-list**: Defender/Firewall/Update/audio/Search/Xbox. |
| `03-registry-performance.ps1` | Foreground/MMCSS/HAGS/memory/input keys. | Documented keys only; `.reg` backups. RAM-gated. |
| `04-network-optimization.ps1` | Nagle off on gaming NIC, throttle off, NIC no-sleep, optional DNS. | Keeps TCP autotuning **normal** (intentional). |
| `05-power-plan.ps1` | Ultimate Performance on AC; balanced on battery. | Laptop-aware (DC stays battery-friendly). |
| `06-security-hardening.ps1` | Keeps Defender/Firewall/SmartScreen/blocklist **ON**; CFA + LSA on. | VBS off only via Esports `-DisableVBS` **prompt**. |
| `07-gaming-features.ps1` | Game Mode, HAGS, VRR/Auto HDR hints, background-DVR off. | Creator keeps capture stack. |
| `08-privacy-telemetry.ps1` | Telemetry min, ad ID/Spotlight/activity off. | Defender **cloud protection kept on** by default. |
| `09-scheduled-tasks.ps1` | Disables telemetry/CEIP tasks only. | **Protect-list**: defrag/NGEN/Defender/Update/SR. |
| `99-restore-defaults.ps1` | Reverts services, tasks, registry, power, security baseline. | Replays `.reg` backups; re-asserts Defender/VBS on. |

---

## Safety model

- **`-WhatIf` everywhere** — every state change runs through `ShouldProcess`. Preview shows exactly what would change.
- **Backups** — each touched registry key is exported to `%ProgramData%\JohnOS\backups\*.reg` before it's modified.
- **Restore point** — `apply-all.ps1` creates one before doing anything.
- **Protect-lists / keep-guards** — scripts refuse to disable Defender, Firewall, Windows Update, Secure Boot, TPM, audio, Search, or Xbox/Gaming services even if mis-edited.
- **Idempotent** — re-running skips already-correct values (`SKIP` in the log).
- **Logging** — everything is written to `%ProgramData%\JohnOS\logs\johnos-YYYYMMDD.log`.

---

## Running individual steps

Every script is standalone and supports the same `-Profile`/`-WhatIf`:

```powershell
.\03-registry-performance.ps1 -Profile Esports -WhatIf
.\04-network-optimization.ps1 -Profile Balanced -SetDns Cloudflare
.\06-security-hardening.ps1   -Profile Esports -DisableVBS   # prompts before disabling VBS
```

Skip steps in the orchestrator:
```powershell
.\apply-all.ps1 -Profile Creator -Skip 01,04   # skip debloat + network
```

---

## Requirements

- Windows 11 (24H2+ recommended), **PowerShell 5.1+** (PS7 works).
- **Elevated** session (Administrator).
- For image staging: copy `scripts/` to `C:\ProgramData\JohnOS\scripts\` and call `apply-all.ps1 -Unattended` from `SetupComplete.cmd` (see [`docs/08-iso-build-process.md`](../docs/08-iso-build-process.md)).

---

## These scripts will NOT

- Disable/remove Microsoft Defender or the Firewall.
- Disable Windows Update or block security definitions.
- Disable Secure Boot, TPM, or driver-signature enforcement.
- Disable the pagefile or apply "RAM cleaners".
- Set Realtime process priority, touch TDR, or disable CPU C-states.
- Apply whole-drive Defender exclusions.

See [`docs/02-performance-optimizations.md`](../docs/02-performance-optimizations.md) §11 for the full list of rejected tweaks and why.
