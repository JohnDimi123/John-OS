# John OS — Included Utilities

John OS preinstalls a **small, curated, lightweight** toolset. Selection criteria: **free or open-source, low overhead, reputable, anti-cheat-safe, and genuinely useful for gamers.** Nothing here runs a heavy background agent by default; monitoring overlays are **opt-in** because some inject into games.

Installed via winget in post-install automation (see [`docs/08-iso-build-process.md`](08-iso-build-process.md)). The list below uses winget package IDs where available.

---

## 1. Hardware monitoring

| Tool | winget ID | Why |
|---|---|---|
| **HWiNFO64** | `REALiX.HWiNFO` | Gold-standard sensors: per-core clocks, temps, voltages, power, VRM, fan, GPU hotspot. Lightweight, read-only. The one monitoring tool everyone should have. |
| **CrystalDiskInfo** | `CrystalDewWorld.CrystalDiskInfo` | SSD/HDD SMART health, temperature, wear. Early warning for failing drives. |
| **CPU-Z** | `CPUID.CPU-Z` | Quick CPU/RAM/mobo identification, memory timings, validation. |
| **GPU-Z** | `TechPowerUp.GPU-Z` | GPU clocks, VRAM, **Resizable BAR state**, sensor sanity check. |

> HWiNFO can feed RTSS for an in-game OSD (opt-in, §2).

---

## 2. FPS & frametime monitoring

| Tool | winget ID | Why |
|---|---|---|
| **MSI Afterburner + RivaTuner (RTSS)** | `Guru3D.RTSS` / Afterburner from MSI | The classic on-screen display: FPS, frametimes, temps, usage. **Overlay is opt-in** (injects into games — widely tolerated, but disable if a strict anti-cheat objects). |
| **CapFrameX** | `CXWorld.CapFrameX` | Best **frametime / 1% & 0.1% low** capture + analysis; uses Intel **PresentMon** under the hood. The right way to actually *measure* John OS's frame-pacing gains. |
| **PresentMon** (Intel) | `Intel.PresentMon` | Microsoft/Intel official frame-time/latency capture; powers benchmarking. |

> For pure latency numbers, **NVIDIA Reflex Analyzer** (compatible mouse + G-SYNC monitor) or the **Game Bar latency widget** are the most accurate without extra hardware.

---

## 3. GPU control & drivers

John OS prefers **vendor-official** driver tools over third-party "driver updaters" (which are the usual source of wrong/malware-bundled drivers):

| Tool | Source | Why |
|---|---|---|
| **NVIDIA App** | `Nvidia.NvidiaApp` | Official driver updates + per-game optimization + Control Panel. Replaces GeForce Experience. |
| **AMD Software: Adrenalin** | `AMD.AMDSoftwareAdrenalinEdition` (or AMD site) | Official AMD driver + tuning. |
| **Intel Arc Control / Driver & Support Assistant** | `Intel.IntelDriverAndSupportAssistant` | Official Intel GPU/chipset updates. |
| **DDU – Display Driver Uninstaller** | `Wagnardsoft.DisplayDriverUninstaller` | Clean driver removal in Safe Mode before vendor swaps/major upgrades. |

> **Driver-updater stance:** John OS does **not** bundle Snappy/DriverBooster-style mass updaters as a default. Wrong drivers cause more instability than they fix. The included path is: chipset driver from the **board vendor**, GPU driver from the **GPU vendor**, everything else from **Windows Update WHQL**. (Snappy Driver Installer Origin is mentioned as an open-source option for *offline* fresh installs only.)

---

## 4. Network diagnostics

| Tool | winget ID | Why |
|---|---|---|
| **WinMTR** | `WinMTR` (or from project) | Continuous traceroute + packet loss per hop — the go-to for diagnosing lag/routing to a game server. |
| **PingPlotter Free** | `PingPlotter.PingPlotter` | Visual latency/loss over time to a target server. |
| **TCPView** (Sysinternals) | `Microsoft.Sysinternals.TCPView` | See exactly what's connecting where — catch a background app eating bandwidth. |
| Built-in `pathping`, `ping`, `Test-NetConnection`, `Get-NetAdapterStatistics` | OS | Scripted diagnostics in John OS's repair toolkit. |

---

## 5. System repair & maintenance

| Tool | Source | Why |
|---|---|---|
| **John OS Repair Toolkit** (bundled script) | this repo | One-click wrappers: `DISM /Online /Cleanup-Image /RestoreHealth`, `sfc /scannow`, `chkdsk` scheduling, pending-update reset, network reset, power-plan re-apply, **and `99-restore-defaults.ps1`**. |
| **Sysinternals Suite** | `Microsoft.Sysinternals.Suite` | Autoruns (audit startups), Process Explorer (better Task Manager), Process Monitor (deep troubleshooting). |
| **Windows Memory Diagnostic / `mdsched`** | OS | RAM testing (point users to MemTest86 for thorough offline testing). |
| **CrystalDiskInfo** | (above) | Drive health early warning. |
| **7-Zip** | `7zip.7zip` | Lightweight archiver (mods, tools). |

---

## 6. Quality-of-life (lightweight, optional)

| Tool | winget ID | Why |
|---|---|---|
| **PowerToys** | `Microsoft.PowerToys` | FancyZones (window tiling), Run, keyboard remap, **Awake** (keep-awake without changing power plan). Microsoft-official, lightweight. |
| **Steam** | `Valve.Steam` | Most users want it; offered, not forced. |
| **Visual C++ Redist (all)** | `Microsoft.VCRedist.*` | Ensures every game's runtime dep is present. |
| **.NET Desktop Runtimes** | `Microsoft.DotNet.DesktopRuntime.*` | Runtime coverage. |

---

## 7. Explicitly NOT bundled (and why)

| Excluded | Reason |
|---|---|
| Mass "driver updater" suites (DriverBooster, etc.) | Wrong-driver instability, adware/PUA history. |
| "RAM optimizer" / "game booster" one-clickers | Snake-oil; standby-flushing causes stutter (perf doc §11). |
| Registry "cleaners" | Negligible benefit, real breakage risk. |
| Cheat Engine / memory editors | Anti-cheat bans; not a system utility. |
| Timer-resolution forcing tools at boot | Marginal/risky; some anti-cheat-flagged. |
| Cracked/"pro" versions of anything | Security + legal. |

---

## 8. Footprint summary

All bundled defaults are **read-only monitors or on-demand tools** — none adds a persistent heavyweight service. The only always-resident additions are the GPU vendor's own driver service (which you'd install anyway) and, if the user opts in, the RTSS overlay. This keeps John OS's "fewer background processes" promise intact (see [`docs/04-debloating.md`](04-debloating.md) §7).

Continue to [`docs/07-branding-and-ui.md`](07-branding-and-ui.md).
