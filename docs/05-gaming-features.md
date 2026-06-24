# John OS — Gaming Features

John OS ships the full modern Windows gaming stack enabled and tuned, with vendor-specific guidance for NVIDIA, AMD, and Intel, and verified compatibility for every major launcher and anti-cheat.

Configured by [`scripts/07-gaming-features.ps1`](../scripts/07-gaming-features.ps1).

---

## 1. Core gaming stack

| Feature | State | Notes |
|---|---|---|
| **DirectX 12 Ultimate** | Enabled (in OS) | DXR ray tracing, Mesh Shaders, VRS, Sampler Feedback. |
| **DirectX 9/11 legacy** | Supported via VC redist + d3d compat | Older titles run. |
| **DirectStorage 1.2** | Runtime present | NVMe fast asset streaming + **GPU decompression**; benefits supported titles dramatically on Gen4 NVMe. |
| **Auto HDR** | On (HDR displays) | Adds HDR to SDR DX11/12 games; toggleable per game. |
| **Game Mode** | **On** | Prioritizes the foreground game, suppresses background interruptions/Windows Update restarts during play. |
| **Hardware-Accelerated GPU Scheduling (HAGS)** | On | Lower CPU overhead/latency (see perf doc §2.4). |
| **Variable Refresh Rate (VRR)** | On | OS-level VRR for windowed/borderless DX titles. |
| **Optimizations for windowed games** | On (24H2) | Near-exclusive-fullscreen latency for borderless windowed. |
| **Game Bar** | On | Reflex latency overlay, performance widget, captures. |

### 1.1 Auto HDR & HDR
- HDR enabled automatically on capable displays; **Windows HDR Calibration** app recommended for accurate output.
- Auto HDR toggle exposed per-game; off for titles with native HDR.

### 1.2 DirectStorage notes (honest)
- DirectStorage needs **the game to implement it** and an **NVMe SSD**; GPU decompression needs a DX12 GPU. It's not a global "make all games load faster" switch — but John OS ensures the runtime and storage are ready so supported titles get the full benefit.

---

## 2. Game Mode optimization

- **On** by default.
- Pairs with Game Mode's ability to **defer Windows Update reboots and driver installs** while gaming.
- Esports profile additionally elevates the foreground game to **High** priority (not Realtime).
- Notifications & Focus Assist auto-engage in fullscreen.

---

## 3. NVIDIA optimization

**Driver:** latest **Game Ready** (or **Studio** for Creator) DCH/WHQL via the **NVIDIA App** (successor to GeForce Experience + Control Panel).

| Setting (NVIDIA Control Panel / App) | John OS recommendation | Why |
|---|---|---|
| **Low Latency Mode** | **Ultra** (or On) for esports; On for general | Caps the render queue → lower input lag. Prefer **Reflex** in-game when available (superior). |
| **NVIDIA Reflex** (in-game) | **On / On+Boost** | Best-in-class latency reduction; overrides driver low-latency. |
| Power management mode | **Prefer maximum performance** (esports) / Optimal (balanced) | Avoids clock down-spikes mid-match. |
| Vertical sync | **Off** (use G-SYNC + cap) | See §6 sync strategy. |
| **G-SYNC** | On (full screen + windowed) for VRR displays | Tear-free without V-Sync latency. |
| Texture filtering quality | High performance (esports) / Quality (visual) | Profile-dependent. |
| Shader cache size | Driver default / large on fast SSD | Fewer recompiles → less stutter. |
| Threaded optimization | Auto | |
| Image Scaling / DLSS | Use **DLSS** in-game where available | Big FPS uplift on RTX. |
| PhysX | GPU | |
| Display: resolution/refresh | Native + **max refresh** confirmed enabled | People forget to enable 144/240 Hz. |
| In-driver telemetry / "experiments" | Off | Privacy. |

> **DDU clean install** recommended when upgrading across major driver branches or switching GPU vendors.

---

## 4. AMD optimization

**Driver:** latest **AMD Software: Adrenalin Edition** (WHQL) + latest **AMD chipset drivers** (critical for Ryzen scheduling/CPPC).

| Setting (Adrenalin) | John OS recommendation | Why |
|---|---|---|
| **Radeon Anti-Lag / Anti-Lag 2** | **On** | Reduces input latency (analogous to Reflex). Anti-Lag 2 is in-game integrated; safer than the old global Anti-Lag+ which previously caused anti-cheat bans — use the in-game/2 version. |
| **Radeon Super Resolution / FSR** | Use **FSR in-game** where available | FPS uplift, vendor-agnostic. |
| **Smart Access Memory (SAM)** | **On** (needs Resizable BAR in BIOS) | Performance uplift in many titles. |
| Enhanced Sync | Optional (VRR preferred) | Tearing/latency balance. |
| **FreeSync** | On (VRR displays) | Tear-free without V-Sync lag. |
| Radeon Chill | **Off** for competitive | Caps FPS to save power → adds latency. |
| Radeon Boost | Optional | Dynamic res on motion; off for pure competitive. |
| Texture filtering / Surface format opt. | Performance | |
| **Chipset drivers + CPPC/Preferred Cores** | Installed & enabled | Proper core scheduling on Ryzen (esp. X3D/dual-CCD). |
| Power: PBO | **Left to user/BIOS** — not auto-enabled | John OS doesn't overclock; PBO is user's choice in BIOS. |

> **Anti-cheat caution:** the original global **Anti-Lag+** caused VAC/anti-cheat bans in 2023 because it injected into game code; AMD reworked it. John OS recommends **in-game Anti-Lag 2 / Anti-Lag** and warns against deprecated injection-based versions.

---

## 5. Intel optimization

**Graphics driver:** latest **Intel Arc & Iris Xe** WHQL (Arc benefits enormously from new drivers). **Chipset/ME** drivers current. For 12th–14th gen, **Intel APO (Application Optimization)** where supported.

| Setting | John OS recommendation | Why |
|---|---|---|
| **Resizable BAR** | **On** (BIOS) | **Essential** for Arc GPUs — large gains; recommended for all. |
| Intel APO / DTT | Enabled where supported | Per-app scheduling tuning on recent CPUs. |
| Arc Control: power | Performance | |
| XeSS | Use in-game | Upscaling FPS uplift. |
| Intel **Application Optimization** (CPU) | On (supported titles/CPUs) | Steers threads for better 1% lows. |
| iGPU vs dGPU (hybrid laptops) | Per-app High-performance → dGPU | Ensures games use the discrete GPU. |
| E-core/P-core scheduling | **Leave to Thread Director** | Don't manually park E-cores by default; let the scheduler work (Win11 + APO is tuned for it). |

---

## 6. Display & sync strategy (vendor-agnostic)

The John OS default for **smooth + low-latency**:
1. Enable the monitor's **max refresh rate** (Settings → Display → Advanced display).
2. Enable **VRR** (G-SYNC/FreeSync) in the GPU panel and Windows.
3. **V-Sync OFF** in-game.
4. **Cap FPS just below refresh** (e.g., 3 fps under: 141 for 144 Hz, 157 for 160 Hz, 237 for 240 Hz) using **Reflex** (auto-caps), the in-game limiter, or RTSS. This keeps you inside the VRR window with minimal latency and no tearing.
5. For pure-latency esports without VRR: **V-Sync off, uncapped (or very high cap)**, accept tearing for minimum lag.

---

## 7. Resizable BAR / Smart Access Memory

- Enabled in **UEFI/BIOS** (Above 4G Decoding + Re-Size BAR). John OS documents the steps per major board vendor; it cannot toggle BIOS from the OS.
- Verify in OS: NVIDIA App / Adrenalin / Arc Control report ReBAR state; `dxdiag` and GPU-Z confirm.
- Recommended **On** for all modern GPUs (mandatory-grade benefit on Intel Arc).

---

## 8. Launcher support (verified)

All major PC launchers install and run on John OS with no special handling beyond keeping WebView2/Edge/Store (see debloat doc §2):

| Launcher | Status | Dependency kept |
|---|---|---|
| **Steam** | ✅ | — |
| **Epic Games Store** | ✅ | — |
| **Battle.net** | ✅ | — |
| **Riot Client** (LoL, Valorant) | ✅ | Secure Boot + TPM (Vanguard) |
| **Ubisoft Connect** | ✅ | WebView2 |
| **EA App** | ✅ | WebView2 |
| **Xbox app / Game Pass** | ✅ | Xbox services + Gaming Services + Store |
| **GOG Galaxy** | ✅ | — |
| **Amazon Games / Prime** | ✅ | — |

Optional first-boot installer (winget) can deploy the user's chosen launchers automatically — see [`docs/08`](08-iso-build-process.md) post-install automation.

---

## 9. Anti-cheat compatibility (critical)

John OS is built so **kernel-level anti-cheats work out of the box**. This is a core design constraint and the reason several "extreme" tweaks are rejected.

| Anti-cheat | Used by (examples) | John OS requirements satisfied |
|---|---|---|
| **Riot Vanguard** | Valorant, LoL | **Secure Boot ON + TPM 2.0 ON** (mandatory on Win11) ✅; driver signature enforcement on ✅. |
| **Easy Anti-Cheat (EAC)** | Fortnite, Apex, many | Services intact, signed drivers, no kernel tampering ✅. |
| **BattlEye** | PUBG, R6 Siege, DayZ, Destiny 2 | Same ✅. |
| **Activision Ricochet** | Call of Duty | Secure Boot recommended/required ✅. |
| **FACEIT AC** | CS2 (FACEIT) | **Secure Boot required** ✅; TPM ✅. |
| **ESEA** | CS2 | Kernel driver loads (signature enforcement on) ✅. |
| **VAC** | CS2, Steam titles | No injection-based tweaks; deprecated Anti-Lag+ avoided ✅. |

**Anti-cheat design rules enforced by John OS:**
- ✅ Secure Boot + TPM **stay on** (never disabled "for FPS").
- ✅ Driver signature enforcement **stays on**; no test-signing.
- ✅ Xbox/Gaming services kept (some titles check them).
- ❌ No memory-editing/timer-hack utilities, no injection-based overlays beyond vendor-sanctioned ones.
- ⚠️ **Process Lasso / aggressive affinity tools** can occasionally be flagged by strict anti-cheats — John OS ships them **off by default** and warns before use.
- ⚠️ RivaTuner/RTSS overlay is widely tolerated but John OS notes that overlays inject and to disable them if a specific title's anti-cheat objects.

> The result: a heavily optimized OS that still passes Vanguard, FACEIT, and EAC checks — because the optimizations never cross the lines those systems watch.

---

## 10. Streaming & capture (Creator profile)

- Hardware encoders kept and tuned: **NVENC** (NVIDIA), **AMF** (AMD), **Quick Sync** (Intel).
- **OBS Studio** recommended; Game Bar capture kept.
- Audio: low-latency WASAPI; loopback capture supported.
- Dual-PC or single-PC NVENC guidance documented; encoder offloads CPU so gaming FPS is preserved while streaming.

Continue to [`docs/06-included-utilities.md`](06-included-utilities.md).
