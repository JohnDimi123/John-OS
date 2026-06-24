# John OS — Performance Optimizations

Every optimization below is **safe, reversible, and stability-tested**. Each entry notes the **mechanism**, the **expected effect**, and any **trade-off**. Where a tweak is commonly recommended online but is risky or snake-oil, it is listed in §11 **"Rejected tweaks"** with the reason.

> Reality check: most FPS in a GPU-bound game comes from the GPU and its driver. OS tuning mainly improves **1% lows, frame pacing, input latency, boot/load times, and CPU-bound headroom** — not raw average FPS on a high-end GPU. John OS optimizes the things the OS can actually control and is honest about the rest.

---

## 1. Windows services

Services are tuned by **profile**. The authoritative, scripted list is in [`scripts/02-services.ps1`](../scripts/02-services.ps1). Philosophy: **prefer `Manual` (trigger-start) over `Disabled`** so Windows can still start a service on demand if something needs it — this avoids the breakage that pure "disable everything" lists cause.

### 1.1 Safe to disable
| Service (display name) | Service name | Action | Why |
|---|---|---|---|
| Connected User Experiences and Telemetry | `DiagTrack` | **Disable** | Primary telemetry uploader; not needed for any game. |
| Device Management WAP Push | `dmwappushservice` | **Disable** | Telemetry transport. |
| Remote Registry | `RemoteRegistry` | **Disable** | Security hardening; remote attack surface. |
| Windows Media Player Network Sharing | `WMPNetworkSvc` | **Disable** | DLNA sharing, irrelevant to gaming. |
| Retail Demo | `RetailDemo` | **Disable** | Store demo mode. |
| Downloaded Maps Manager | `MapsBroker` | **Disable** | Offline maps. |
| Geolocation | `lfsvc` | **Disable** | Privacy; gaming doesn't need location. |
| Fax | `Fax` | **Disable** | — |
| Parental Controls | `WpcMonSvc` | **Disable** (if no child accounts) | — |
| Payments / NFC (`SEMgrSvc`) | `SEMgrSvc` | **Manual** | Wallet/NFC. |
| Print Spooler | `Spooler` | **Disable only if no printer** | Also closes PrintNightmare-class surface. Keep on if you print. |

### 1.2 Set to Manual (trigger-start) — not disabled
| Service | Service name | Why Manual not Disabled |
|---|---|---|
| Superfetch / SysMain | `SysMain` | On modern Win11 + NVMe it does more than prefetch (memory compression heuristics). **Keep enabled or Manual** — see note. |
| Diagnostic Policy Service | `DPS` | Some troubleshooters need it. |
| Diagnostic Service Host | `WdiServiceHost` | On-demand diagnostics. |
| Program Compatibility Assistant | `PcaSvc` | Needed for some older game installers. |
| Touch Keyboard / Handwriting | `TabletInputService` | Manual for desktops; keep for tablets/2-in-1. |
| Connected Devices Platform | `CDPSvc` | Nearby share / cross-device. |
| Phone Service | `PhoneSvc` | — |
| Windows Insider | `wisvc` | — |

> **SysMain note:** Older "gaming" guides disable SysMain reflexively. On Windows 11 with an SSD this rarely helps and can slightly *hurt* launch times because the modern service also manages memory compression. John OS **keeps SysMain enabled in Balanced/Creator**, and only offers Manual in Esports for users who measure a benefit. This is a deliberate departure from cargo-cult advice.

### 1.3 Always retained (never touch)
`Audiosrv`, `AudioEndpointBuilder` (audio), `Themes` (visual styles — disabling breaks dark mode/theming), `WSearch` (Search — keep, just trim indexed locations), `BFE`/`mpssvc` (firewall), `WinDefend`/`Sense`/`WdNisSvc` (Defender), `wuauserv`/`UsoSvc`/`BITS` (Windows Update), `EventLog`, `Power`, `Schedule`, `PlugPlay`, `Dhcp`/`Dnscache`/`NlaSvc` (networking), `gpsvc`, `ProfSvc`, `CryptSvc`/`TrustedInstaller`, `SecurityHealthService`.

### 1.4 Gaming-critical services — explicitly kept
| Service | Service name | Why kept |
|---|---|---|
| Xbox Live Auth Manager | `XblAuthManager` | Game Pass, some titles, achievements. |
| Xbox Live Game Save | `XblGameSave` | Cloud saves. |
| Xbox Accessory Management | `XboxGipSvc` | Controller support. |
| Xbox Live Networking | `XboxNetApiSvc` | Multiplayer/NAT. |
| Gaming Services | `GamingServices`, `GamingServicesNet` | Game Pass / Store games install layer. |
| GameDVR & Broadcast user svc | `BcastDVRUserService` | Game Bar capture & Reflex stats overlay. |

> Many "debloat" scripts kill Xbox services and then users can't launch Game Pass titles or use the Game Bar latency overlay. John OS keeps them.

---

## 2. Registry optimizations

All values are applied by [`scripts/03-registry-performance.ps1`](../scripts/03-registry-performance.ps1) with `.reg` backups. Each is individually reversible.

### 2.1 CPU scheduling & foreground priority
```
[HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl]
"Win32PrioritySeparation"=dword:00000026
```
- **Effect:** `0x26` (38) selects *short, variable quantums with a strong foreground boost* — gives the active game more CPU time relative to background threads. Default desktop value is `0x2`.
- **Trade-off:** none meaningful for a single-foreground-app gaming workload. Reverts to `0x2` on restore.

### 2.2 Multimedia Class Scheduler (MMCSS) — Games task
```
[HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games]
"GPU Priority"=dword:00000008
"Priority"=dword:00000006
"Scheduling Category"="High"
"SFIO Priority"="High"
```
- **Effect:** Tells MMCSS to give threads that join the "Games" task class high GPU and CPU scheduling priority and high storage I/O priority. Games that register with MMCSS (most do via DirectX) benefit in frame pacing.
- These are **the Microsoft-documented defaults' tuned values**, not invented keys.

### 2.3 System responsiveness
```
[HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"SystemResponsiveness"=dword:0000000a   ; decimal 10
"NetworkThrottlingIndex"=dword:ffffffff
```
- **`SystemResponsiveness=10`** reserves only 10% of CPU for low-priority/background tasks (default 20%), favoring the foreground game. John OS uses **10, not 0** — `0` can starve audio/streaming threads and cause crackle. (Esports profile may set 0 with a warning.)
- **`NetworkThrottlingIndex=0xFFFFFFFF`** disables the multimedia network throttle (which caps non-multimedia network packet processing to ~10k/s). Beneficial for high-throughput online play and streaming. Safe; the throttle exists for media playback smoothness, irrelevant here.

### 2.4 GPU scheduling (HAGS)
```
[HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers]
"HwSchMode"=dword:00000002
```
- **Effect:** Enables **Hardware-Accelerated GPU Scheduling**, letting the GPU manage its own VRAM/queue, which can reduce CPU overhead and lower latency on supported GPUs (NVIDIA Pascal+/Turing+, AMD RDNA+, recent Intel). Equivalent to the Settings toggle.
- **Trade-off:** On rare driver/GPU combos HAGS can cause stutter; it is **per-profile and reversible**. Balanced = ON.

### 2.5 Memory management
```
[HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"DisablePagingExecutive"=dword:00000001
"LargeSystemCache"=dword:00000000
"ClearPageFileAtShutdown"=dword:00000000
```
- **`DisablePagingExecutive=1`** keeps kernel-mode drivers/code resident in RAM instead of paging to disk. Safe and beneficial **with ≥16 GB RAM**; John OS only applies it when ≥16 GB is detected.
- **`LargeSystemCache=0`** (default for workstations) — correct for gaming; `1` favors file-server caching and can starve game working sets.
- **`ClearPageFileAtShutdown=0`** — leaving this 0 keeps shutdowns fast (1 zeroes the pagefile on every shutdown, slow, no benefit for a single-user gaming PC).

> **Pagefile is kept enabled.** John OS sets a **system-managed or fixed pagefile**, never disables it. Disabling the pagefile is a top community myth that causes random crashes when a game's commit charge spikes, and breaks crash-dump diagnostics.

### 2.6 Input latency — mouse
```
[HKCU\Control Panel\Mouse]
"MouseSpeed"="0"
"MouseThreshold1"="0"
"MouseThreshold2"="0"
```
- Disables **"Enhance pointer precision"** (mouse acceleration). Essential for consistent aim; raw, 1:1 movement. Reversible per-user.

### 2.7 UI snappiness (perceived responsiveness)
```
[HKCU\Control Panel\Desktop]
"MenuShowDelay"="0"            ; default 400 ms
"AutoEndTasks"="1"
[HKCU\Control Panel\Desktop\WindowMetrics]
"MinAnimate"="0"              ; reduce window animations
```
- Cosmetic/perceived-latency only; no FPS effect. Optional and reversible. (Esports profile also disables transparency.)

### 2.8 Power throttling (per-process CPU throttling)
```
[HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling]
"PowerThrottlingOff"=dword:00000001
```
- Disables Windows' opportunistic per-process power throttling so background-tab heuristics never throttle a game. Pairs with the Ultimate Performance plan. On laptops this is **profile-gated** (battery life cost).

### 2.9 Storage I/O — NTFS
```
[HKLM\SYSTEM\CurrentControlSet\Control\FileSystem]
"NtfsDisableLastAccessUpdate"=dword:80000001   ; system-managed, disabled
```
- Stops NTFS from writing a "last accessed" timestamp on every file read — fewer metadata writes, marginally faster file access. Windows 11 default is already `0x80000000` (system-managed); John OS makes the disabled state explicit. Safe.

> **Left at default on purpose:** `TdrDelay` / `TdrLevel` (GPU timeout detection — a safety feature; raising it hides real hangs), and processor `IdleDisable` (disabling C-states cooks laptops for no FPS gain).

---

## 3. Memory management strategy

| Setting | John OS choice | Rationale |
|---|---|---|
| Pagefile | **Enabled**, system-managed (or fixed 1.5× RAM if user prefers) | Stability; commit-charge spikes; crash dumps. |
| `DisablePagingExecutive` | 1 (if ≥16 GB) | Keep kernel resident. |
| Memory compression | **Enabled** (default) | Reduces hard faults; CPU cost negligible on modern cores. |
| Standby list "cleaning" | **Not used** | "RAM cleaners"/standby flushers cause stutter by evicting useful cache. Rejected (§11). |
| ReadyBoost | Disabled | Irrelevant with SSD/NVMe. |

**Result:** lower idle commit, faster faults, no stutter from cache thrash. RAM *savings* come from debloat (fewer background processes), not from RAM cleaners.

---

## 4. CPU scheduling improvements

1. **`Win32PrioritySeparation = 0x26`** — foreground boost (§2.1).
2. **MMCSS Games task tuning** (§2.2).
3. **Core parking disabled** via the Ultimate Performance power plan (cores stay ready, lower wake latency). Done through `powercfg`, not a registry hack.
4. **Power throttling off** (§2.8).
5. **Foreground process priority** (Esports profile): the launched game is set to **High** priority (not Realtime — Realtime can lock the system and is rejected, §11).

> **Not done:** manual core affinity pinning by default. Modern Windows + chipset drivers (especially AMD CPPC/preferred-core and Intel Thread Director) schedule better than static affinity. Affinity is offered only as an *advanced, opt-in* tool, not a default.

---

## 5. GPU scheduling settings

| Setting | John OS | Notes |
|---|---|---|
| Hardware-Accelerated GPU Scheduling (HAGS) | **ON** (Balanced/Esports) | §2.4; lower CPU overhead/latency on supported GPUs. |
| Variable Refresh Rate (Windows) | **ON** | Enables VRR for borderless/windowed DX11/12 where the GPU supports it. |
| Optimizations for windowed games (24H2) | **ON** | New Win11 path giving windowed/borderless games near-exclusive latency. |
| Per-app GPU preference | High-performance for game executables | Set for the active game on hybrid (laptop iGPU+dGPU) systems. |
| MPO (Multi-Plane Overlay) | **Left default ON** | Only disabled as a *bug workaround* if a user reports flicker — not a perf default. |

---

## 6. Power plan configuration

John OS imports and selects the **Ultimate Performance** plan (a real Microsoft plan, normally hidden):

```powershell
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
```

Then applies (see [`scripts/05-power-plan.ps1`](../scripts/05-power-plan.ps1)):

| Power setting | Value (AC) | Why |
|---|---|---|
| Processor min state | 100% (Esports) / 5% (Balanced) | Esports keeps clocks pinned for lowest latency; Balanced allows idle down-clock for heat/noise. |
| Processor max state | 100% | Full performance available. |
| Core parking (min cores) | 100% | All cores unparked, low wake latency. |
| PCI Express ASPM | Off | No link-state power saving on the GPU bus → consistent latency. |
| USB selective suspend | Disabled | Mouse/keyboard never suspended → no input hitches. |
| Hard disk sleep | Never (AC) | Avoid spin-down hitches (mostly relevant to HDDs). |
| Monitor/sleep | User-chosen | Not forced; respects user. |

> **Laptops:** John OS keeps a **separate balanced DC (battery) profile** and only pins Ultimate Performance on AC. Pinning 100% min-state on battery destroys runtime and adds heat with no FPS benefit when thermally throttled.

---

## 7. Boot-time optimizations

| Lever | Mechanism | Expected effect |
|---|---|---|
| Fewer startup apps | Debloat removes auto-start consumer apps; `Startup` folder & `Run` keys trimmed | Largest single boot win. |
| Fewer auto services | §1 service trimming (Manual/Disabled) | Fewer things racing at boot. |
| Disable startup delay | `Serialize\StartupDelayInMSec=0` (HKCU Explorer) | Startup apps launch without the 10 s artificial delay. |
| Fast Startup | **Left ON by default**, but documented | Hybrid shutdown speeds boot; can be turned off if dual-booting Linux (clock/filesystem issues). |
| Modern Standby vs S3 | Left to firmware | Not forced. |
| Boot logo (BGRT) | Branding layer (cosmetic) | No speed effect. |
| Trim scheduled tasks | §9 in debloat | Fewer logon-time tasks. |

**Realistic:** on an NVMe SSD, cold boot to interactive desktop typically drops from ~20–30 s (stock, post-update) to ~10–15 s, mostly from removing auto-start apps and telemetry services. HDD systems see larger absolute gains.

---

## 8. Game load-time & SSD/storage optimizations

| Lever | Action | Effect |
|---|---|---|
| **TRIM** | Verify enabled: `fsutil behavior query DisableDeleteNotify` should be `0` | Sustains SSD write performance. |
| **Scheduled "defrag"** | **Kept enabled** for SSDs — on SSDs it issues TRIM/retrim, not mechanical defrag | Myth-buster: don't disable "Optimize Drives" for SSDs; it does the right thing. |
| **DirectStorage** | Runtime present; GPU decompression path available | Faster asset streaming/loads in supported titles. |
| **Search indexing** | Keep service; **exclude game install folders & shader caches** from the index | Stops the indexer churning over huge game directories. |
| **Storage Sense** | Optional, conservative (temp files only) | Reclaim space without touching game data. |
| **Write caching** | Enabled (default) | Throughput. |
| **Game library drive** | Guidance: dedicated NVMe for the Steam/Epic library | Avoids contention with OS drive. |
| **NTFS last-access** | Disabled (§2.9) | Fewer metadata writes. |

> **Not done:** disabling the pagefile, disabling Prefetch/Superfetch wholesale (§1.2 note), or aligning/"optimizing" SSDs with third-party tools (Windows handles it).

---

## 9. Network stack optimizations for online gaming

Applied by [`scripts/04-network-optimization.ps1`](../scripts/04-network-optimization.ps1). Focus on **latency consistency**, not headline bandwidth.

| Tweak | Setting | Effect / trade-off |
|---|---|---|
| **Disable Nagle's algorithm** | Per-interface `TcpAckFrequency=1`, `TCPNoDelay=1` | Stops small-packet coalescing → lower latency for twitch games that send tiny packets. Trade-off: marginally more overhead on bulk transfers. Applied to the active gaming NIC. |
| **Network throttling index** | `0xFFFFFFFF` (§2.3) | Removes the 10k pkt/s multimedia cap. |
| **`NetworkThrottlingIndex` companion** | `SystemResponsiveness=10` | Foreground bias. |
| **Reservable bandwidth (QoS)** | Leave default | The "20% reserved bandwidth" claim is a **myth** — Windows only reserves it when an app actually requests QoS, and it's freely usable otherwise. John OS does **not** chase this. |
| **TCP autotuning** | **Left `normal`** | Disabling it (a common bad tweak) *hurts* throughput on modern high-BDP links. Kept on. |
| **Receive Side Scaling (RSS)** | Enabled | Spreads NIC interrupts across cores. |
| **RSC (Receive Segment Coalescing)** | Default | Left alone; modern NICs handle it well. |
| **DNS** | Optional set to a fast resolver (1.1.1.1 / 8.8.8.8 / 9.9.9.9) | Faster name resolution; user-selectable, not forced. DoH supported. |
| **Wi-Fi vs wired** | Guidance: wired for competitive | Lowest, most consistent latency. |
| **Adapter power management** | "Allow the computer to turn off this device" **unchecked** | NIC never sleeps mid-match. |

> All TCP global settings are applied with `netsh`/`Set-NetTCPSetting` and are fully reversible. John OS deliberately avoids the long list of `netsh` "optimizers" floating around that toggle deprecated or harmful flags.

---

## 10. Visual/UX performance settings

- **Performance visual effects:** John OS uses a tuned middle ground — disables heavy animations (window minimize/maximize, fade) but **keeps font smoothing (ClearType) and thumbnails** so the desktop still looks modern. Pure "adjust for best performance" looks dated; John OS's profile is curated.
- **Transparency:** Off in Esports (tiny DWM saving), on in Balanced/Creator (aesthetic).
- **Notifications during gameplay:** Game Mode + Focus Assist auto-suppress notifications when a fullscreen game runs.

---

## 11. Rejected tweaks (and why)

These appear in many "gaming OS" guides. John OS **deliberately excludes** them.

| Rejected tweak | Why rejected |
|---|---|
| Disabling the pagefile | Random out-of-memory crashes; breaks crash dumps. |
| Realtime process priority for games | Can starve OS threads → hard freezes. High is the safe ceiling. |
| Disabling SysMain/Prefetch reflexively | Little/no benefit on SSD; can slow launches. |
| "RAM cleaners" / standby-list flushers | Evict useful cache → more stutter, not less. |
| Disabling TCP autotuning | Hurts throughput on modern links. |
| Forcing `TdrDelay` high / disabling TDR | Masks real GPU hangs → black-screen lockups. |
| Disabling CPU C-states / idle | More heat & power, throttling, no FPS gain. |
| Timer resolution "0.5 ms forcing" tools at boot | Marginal, power-hungry, and some are anti-cheat-flagged. Windows 11 already grants fine timer resolution to foreground games. |
| Deleting Defender / disabling Windows Update | Catastrophic security loss for negligible FPS. |
| Registry "telemetry" deletions of unknown keys | Breakage risk; John OS only touches documented keys. |
| Third-party "debloat-everything" one-clickers run blindly | Unpredictable breakage; John OS's list is curated and reversible. |

---

## 12. Summary table — what John OS actually changes

| Domain | Net effect | Risk |
|---|---|---|
| Services | ~15–25 trimmed to Manual/Disabled; gaming + security services kept | Low (Manual-first) |
| Registry | Foreground/MMCSS/HAGS/memory/input — all documented keys | Low (backed up) |
| Power | Ultimate Performance on AC; balanced on battery | Low |
| Network | Nagle off + throttle off on gaming NIC; autotuning kept | Low |
| Storage | TRIM verified, indexing trimmed, NTFS last-access off | Low |
| Boot | Startup apps/tasks trimmed | Low |
| Visual | Curated effects; notifications suppressed in-game | None |

Continue to [`docs/03-security.md`](03-security.md) for how John OS stays secure through all of this.
