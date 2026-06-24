# John OS — Optimization Checklist

Tick each item. References point to the detailed rationale. **Bold = applied by a script** (no manual work). ⚠️ = trade-off, read the reference. Items left at default on purpose are listed in §"Intentionally NOT changed".

> Preview everything first: `./scripts/apply-all.ps1 -Profile Balanced -WhatIf`

---

## Boot & startup
- [ ] **Trim auto-start apps** (debloat removes consumer auto-starts) — `01`
- [ ] **Startup delay disabled** (`StartupDelayInMSec=0`) — `03`
- [ ] **Telemetry/CEIP scheduled tasks disabled** (not maintenance/Defender/NGEN) — `09`
- [ ] Decide on Fast Startup (on by default; off if dual-booting Linux) — perf doc §7
- [ ] Boot to interactive measured before/after — bench doc §3

## CPU scheduling
- [ ] **`Win32PrioritySeparation = 0x26`** (foreground boost) — `03`
- [ ] **MMCSS Games task** (GPU Priority 8, Priority 6, High/High) — `03`
- [ ] **Power throttling off** (AC) — `03`/`05`
- [ ] **Core parking off** via Ultimate Performance plan — `05`
- [ ] Foreground game → **High** priority (Esports) — `07`
- [ ] (Skip) manual core affinity — leave to Thread Director/CPPC

## GPU scheduling
- [ ] **HAGS on** (`HwSchMode=2`) — `03`
- [ ] **VRR on** (Windows) — `07`
- [ ] **"Optimizations for windowed games" on** (24H2) — `07`
- [ ] Per-app GPU = High-performance for game exe (hybrid laptops) — `07`
- [ ] MPO left default (only disable as flicker workaround) — perf doc §5

## Memory
- [ ] **`DisablePagingExecutive=1`** (if ≥16 GB) — `03`
- [ ] **`LargeSystemCache=0`** — `03`
- [ ] **`ClearPageFileAtShutdown=0`** — `03`
- [ ] Pagefile **enabled** (system-managed/fixed) — perf doc §3
- [ ] (Reject) RAM cleaners / standby flushers — perf doc §11

## Power
- [ ] **Ultimate Performance imported + selected (AC)** — `05`
- [ ] **USB selective suspend disabled** — `05`
- [ ] **PCIe ASPM off** — `05`
- [ ] CPU max 100%; min 100% (Esports) / 5% (Balanced) — `05`
- [ ] ⚠️ Laptops: balanced **DC** profile retained — `05`/risk R11

## Network
- [ ] **`NetworkThrottlingIndex=0xFFFFFFFF`** — `03`/`04`
- [ ] **`SystemResponsiveness=10`** — `03`
- [ ] **Nagle off on gaming NIC** (`TcpAckFrequency`/`TCPNoDelay`) — `04`
- [ ] **NIC power management off** — `04`
- [ ] TCP autotuning **left normal** (do NOT disable) — `04`
- [ ] RSS enabled — `04`
- [ ] Optional fast DNS / DoH — `04`
- [ ] Wired connection for competitive — `11`

## Storage / SSD
- [ ] **TRIM verified** (`DisableDeleteNotify=0`) — `02` §8
- [ ] **Scheduled "Optimize Drives" kept** (TRIM for SSD) — `02`/`04`
- [ ] **NTFS last-access disabled** — `03`
- [ ] **Search index: exclude game folders & shader caches** — `02`
- [ ] DirectStorage runtime present — `05`
- [ ] (Reject) disable pagefile / 3rd-party "SSD optimizers" — perf doc §11

## Input / latency
- [ ] **Mouse acceleration off** (`MouseSpeed/Threshold1/2=0`) — `03`
- [ ] Polling 1000 Hz+ (vendor SW) — `11`
- [ ] Reflex/Anti-Lag on (in-game) — `05`/`11`
- [ ] V-Sync off + VRR cap below refresh — `11`

## Visual / UX
- [ ] **Curated visual effects** (heavy animations off, ClearType kept) — `02` §10
- [ ] Transparency off (Esports) — `07`/`11`
- [ ] **Notifications suppressed in fullscreen** (Game Mode/Focus) — `02`/`11`

## Gaming features
- [ ] **Game Mode on** — `07`
- [ ] HAGS on; VRR on; Auto HDR (HDR displays) — `07`
- [ ] Vendor driver current (NVIDIA App / Adrenalin / Intel) — `05`/`06`
- [ ] Resizable BAR / SAM on (BIOS) — `05`
- [ ] Launchers verified (Steam/Epic/EA/Ubi/Battle.net/Riot/Xbox/GOG) — `05`

---

## Intentionally NOT changed (and why)
- [ ] TDR delay/level — safety feature (perf §2.9)
- [ ] CPU C-states/idle — heat/power, no FPS gain (perf §11)
- [ ] TCP autotuning — disabling hurts throughput (perf §9)
- [ ] SysMain (kept enabled, Balanced) — SSD myth (perf §1.2)
- [ ] Realtime priority — freeze risk (perf §4)
- [ ] UAC level — security (sec §9)
- [ ] Pagefile — stability (perf §3)

---

## Verify
- [ ] Run benchmarks (CapFrameX/PresentMon, LatencyMon, boot time) — `09`
- [ ] Acceptance criteria met, no regressions — `09` §5
- [ ] `99-restore-defaults.ps1` tested on a copy — `10` §6

*(Reference codes = `docs/0X-*.md` / `scripts/0X-*.ps1`.)*
