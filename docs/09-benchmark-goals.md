# John OS — Benchmark Goals & Expected Improvements

This document sets **honest, measurable** targets and explains how to verify them. John OS deliberately avoids inflated marketing numbers. Where a metric is hardware-dependent (most are), that's stated.

> **Core truth:** OS tuning cannot add GPU horsepower. On a high-end GPU running a GPU-bound game at high settings, **average FPS barely moves** with any OS tweak — the GPU is already the bottleneck. Where John OS *does* deliver is **1% / 0.1% lows (frame pacing), input latency, boot time, idle RAM/CPU, and CPU-bound headroom** (esports titles, lower-end/older CPUs, heavy multitasking). Those are the goals below.

---

## 1. Target metrics & realistic expectations

Comparison baseline: **stock Windows 11 24H2 Pro**, fully updated, signed into a Microsoft account, with default consumer apps/Spotlight running — i.e., a normal real-world install, not a freshly-imaged lab box.

| Metric | Stock Win11 (typical) | John OS target | Honest expected delta |
|---|---|---|---|
| **Average FPS (GPU-bound, high-end GPU)** | baseline | ≈ baseline | **0–3%** (often within margin of error) |
| **Average FPS (CPU-bound / esports / older CPU)** | baseline | higher | **3–12%**, larger on weak CPUs / with VBS off |
| **1% low FPS (frame pacing)** | baseline | smoother | **5–15%** improvement (the headline real-world win) |
| **0.1% low FPS** | baseline | smoother | **up to ~15–20%** in background-noisy scenarios |
| **End-to-end input latency** | baseline | lower | **−3 to −15 ms** (Reflex/Anti-Lag + HAGS + no accel + capped-VRR) |
| **DPC/ISR latency (LatencyMon)** | varies | tighter | fewer spikes after trimming background services/telemetry |
| **Cold boot → interactive (NVMe)** | ~20–30 s | ~10–15 s | **30–50% faster** (mostly fewer auto-start apps/services) |
| **Idle RAM (committed)** | 3.5–4.5 GB | 1.8–2.8 GB | **~1–1.5 GB freed** |
| **Idle CPU** | 2–5% | <1–2% | quieter, cooler idle |
| **Background processes** | 120–160 | 80–110 | fewer interrupts |
| **Game load times** | baseline | ≈ to faster | DirectStorage titles benefit most; others ≈ baseline |

### The VBS/HVCI line item
- Turning **VBS/HVCI off** (Esports profile, opt-in) typically yields **~0–10%** more FPS in CPU-bound titles, near-zero in GPU-bound ones.
- This is the **only** tweak with a meaningful FPS number attached *and* a security cost. Balanced keeps it on; the choice is the user's and is documented everywhere.

---

## 2. Why "huge FPS gains" claims are wrong (and John OS won't make them)

Builds advertising "+30–50% FPS from a debloated Windows" are almost always:
- Comparing against a **broken/throttling** baseline (thermal-limited, malware-laden, or driver-mismatched), or
- Measuring a **CPU-bound** corner case and generalizing, or
- Counting **VBS-off** + overclock + driver update as if the OS did it.

John OS reports gains **at equal drivers, equal clocks, equal thermals** — so the numbers reflect what the OS layer actually contributes. Under those rules, double-digit *average*-FPS gains only appear in CPU-bound/esports scenarios.

---

## 3. How to measure (reproducible methodology)

**Controls (hold constant across stock vs John OS):**
- Identical hardware, same GPU driver version, same BIOS/clocks, same room temp / cooling.
- Same game build, same settings preset, same benchmark scene or replay.
- Same resolution; test **both** a GPU-bound (4K/high) and CPU-bound (1080p low, or esports title) scenario.
- Disable background updates/downloads during runs; fixed warm-up; ≥3 runs averaged.

**Tools (all in [`docs/06`](06-included-utilities.md)):**
| Metric | Tool |
|---|---|
| FPS, 1% / 0.1% lows, frametimes | **CapFrameX** / **PresentMon** |
| Input latency (end-to-end) | **NVIDIA Reflex Analyzer** (HW) or **Game Bar latency** widget |
| DPC/ISR latency | **LatencyMon** |
| Boot time | `Measure-Boot` via Event Log (Diagnostics-Performance ID 100) or **bootim**/xbootmgr |
| Idle RAM/CPU/process count | Task Manager / `Get-Process` / Process Explorer, sampled at steady idle |
| Storage | **CrystalDiskMark** (before/after, same drive/fill level) |
| Network | **WinMTR**/**PingPlotter** to the same game server |

**Boot-time capture example:**
```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} |
  Select-Object -First 5 TimeCreated, @{N='BootMs';E={$_.Properties[0].Value}}
```

---

## 4. Per-profile benchmark goals

| Profile | Primary KPIs | Secondary |
|---|---|---|
| **Balanced** | Boot time, idle RAM/CPU, 1% lows, latency — **all with VBS on** | Avg FPS ≈ stock |
| **Esports** | Lowest input latency, best 1% lows, max CPU-bound FPS (VBS optional off) | Frametime variance ↓ |
| **Creator** | Stable frametimes **while streaming** (NVENC), encoder CPU offload | Avg FPS ≈ stock with encode running |

---

## 5. Acceptance criteria (a build "passes" if…)

1. **No regressions:** every tested game launches, anti-cheat passes (Vanguard/EAC/FACEIT), no new stutter or crashes vs stock.
2. **Boot:** ≥25% faster cold boot on NVMe vs the stock baseline.
3. **Idle:** ≥1 GB lower committed RAM at steady idle; idle CPU ≤2%.
4. **Frame pacing:** measurable 1%-low improvement in at least the CPU-bound test (≥5%).
5. **Latency:** measurable end-to-end latency reduction with Reflex/Anti-Lag + John OS defaults vs stock defaults.
6. **Security intact:** Defender on, Firewall on, Secure Boot + TPM on, Windows Update functional. (VBS state matches the chosen profile.)
7. **Reversible:** `99-restore-defaults.ps1` returns the system to stock behavior.

A build that gets big FPS numbers but **fails #1 or #6 is rejected** — stability and security are non-negotiable acceptance gates.

---

## 6. Reporting template

Each validated build ships a one-page report:

```
John OS Benchmark Report — <date> — <CPU/GPU/RAM/SSD> — driver <ver>
Baseline: Stock Win11 24H2  |  Build: John OS <profile> (VBS <on/off>)

Game            Scene      Res/Preset   Avg FPS   1% low   0.1% low   Latency
-------------------------------------------------------------------------------
CS2             FACEIT     1080p low    stk→jos   stk→jos  stk→jos    stk→jos
Cyberpunk 2077  built-in   4K high      stk→jos   stk→jos  stk→jos    n/a
...

Boot (cold, s):  stk → jos        Idle RAM (GB): stk → jos
Idle CPU (%):    stk → jos        Processes:     stk → jos
Notes: thermals equal, driver equal, clocks equal. Anti-cheat: PASS.
```

Continue to [`docs/10-risk-and-compatibility.md`](10-risk-and-compatibility.md).
