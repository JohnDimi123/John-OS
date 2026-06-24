# John OS — Recommended Defaults for Competitive Gaming

The **Esports profile** turns these on. This is the "lowest, most consistent latency" configuration for FPS/MOBA/fighting-game players. Every item is safe and reversible; the one security trade-off (VBS) is opt-in and flagged.

---

## 1. The competitive default stack (at a glance)

| Domain | Default | Why |
|---|---|---|
| Mouse acceleration | **Off** (Enhance pointer precision unchecked) | 1:1 raw aim. |
| Mouse polling rate | **1000 Hz+** (set on the mouse / vendor SW) | More frequent position updates → lower aim latency. |
| Mouse sensitivity in Windows | **6/11 (default), no scaling** | Avoids Windows-side pointer scaling artifacts. |
| Power plan | **Ultimate Performance**, CPU min **100%** | Clocks pinned, no down-spikes. |
| USB selective suspend | **Disabled** | Input devices never sleep. |
| Game Mode | **On** | Foreground priority, fewer interruptions. |
| Foreground process priority | **High** (not Realtime) | More CPU for the game, safely. |
| HAGS (GPU scheduling) | **On** | Lower CPU overhead/latency. |
| V-Sync | **Off** | Removes V-Sync latency. |
| VRR (G-SYNC/FreeSync) | **On** + FPS cap just below refresh | Tear-free, low-latency (or uncapped for pure minimum latency). |
| Reflex / Anti-Lag | **On / On+Boost** (in-game) | Best latency reduction available. |
| Display refresh | **Max** (144/240/360 Hz confirmed enabled) | The biggest latency lever people forget. |
| Fullscreen mode | **Exclusive fullscreen** where the game offers it | Lowest-latency present path. |
| Network | **Wired**, Nagle off on gaming NIC, fast DNS | Consistent low ping. |
| Notifications / Focus Assist | **Suppress while gaming** | No alt-tab hitches. |
| Background recording (Game Bar) | **Off** (manual clips only) | No capture overhead unless you want it. |
| Xbox Game Bar overlay | **On** (for Reflex latency widget) | Measure latency; minimal cost. |
| SystemResponsiveness | **10** (0 optional with audio warning) | Foreground bias. |
| VBS / HVCI | **Optional Off** (opt-in, documented) | ~0–10% CPU-bound FPS; security trade-off. |
| Audio | Low-latency, exclusive-mode allowed, comms ducking off | Snappy positional audio. |
| Wallpaper/transparency | Static wallpaper, transparency off | Trim DWM overhead. |

---

## 2. Sync strategy detail (most-asked question)

**For VRR monitors (G-SYNC / FreeSync) — recommended:**
1. Enable VRR in the GPU panel **and** Windows.
2. **V-Sync OFF in-game.**
3. **Cap FPS ~3 below refresh** (141@144, 157@160, 237@240) via **Reflex** (auto), in-game limiter, or RTSS.
→ Tear-free + low latency + inside the VRR window.

**For pure minimum latency (no VRR, hardcore):**
- V-Sync off, **uncapped** (or very high cap). Accept tearing for the absolute lowest input lag. Many pro CS2/Valorant players run this way.

**Avoid:** in-game V-Sync ON without VRR (adds latency); double V-Sync (driver + game).

---

## 3. Mouse & input checklist

- Windows pointer speed at the **6th notch (default)**, "Enhance pointer precision" **off** (John OS sets this — perf doc §2.6).
- Set polling rate (500–1000 Hz, or 2k–8k on capable mice — diminishing returns, more CPU) in the **mouse vendor software**, not Windows.
- Disable any OS-level mouse "smoothing"; in-game raw input **on**.
- Keyboard: NKRO if available; no software macros that inject (anti-cheat risk).
- **USB:** plug mouse/keyboard into the **rear motherboard ports** (direct to chipset), selective suspend off (John OS power plan handles this).

---

## 4. Display checklist

- Set **native resolution** and **maximum refresh rate** in Settings → Display → Advanced display (people forget the refresh dropdown).
- Run the monitor's lowest-latency picture mode; disable monitor-side processing (overdrive at the vendor-recommended level, no "dynamic contrast").
- HDR off for competitive unless the title's HDR is genuinely low-latency (SDR is usually simpler/faster for esports).
- One high-refresh primary display active during ranked play; secondary monitors fine but avoid mismatched-refresh DWM quirks.

---

## 5. Network checklist (online competitive)

- **Wired Ethernet**, gigabit, NIC power management off (John OS sets this).
- **Nagle's algorithm off** on the gaming NIC (perf doc §9) → lower small-packet latency.
- Pick a **nearby server/region**; verify route health with **WinMTR/PingPlotter**.
- Fast DNS (1.1.1.1 / 8.8.8.8) optional.
- Close bandwidth hogs (cloud sync, updates, other devices streaming) during ranked — John OS suppresses background downloads in Game Mode but household traffic is on you.
- QoS on the router for the gaming PC if your network is shared.

---

## 6. System checklist (apply once)

Run the Esports profile:
```powershell
.\scripts\apply-all.ps1 -Profile Esports
# It will PROMPT before disabling VBS and explain the security trade-off.
```
This applies: Ultimate Performance, foreground-priority defaults, HAGS, mouse-accel off, notifications-suppressed, recording-off, NIC/Nagle tuning, transparency off, and (with consent) VBS off.

---

## 7. Per-genre quick presets

| Genre | Sync | Cap | Priority focus |
|---|---|---|---|
| **Tactical FPS** (CS2, Valorant) | VRR+cap or uncapped | high/uncapped | Max FPS, lowest latency, exclusive fullscreen |
| **BR / hero shooter** (Apex, Fortnite, Overwatch) | VRR+cap | ~3 under refresh | Stable 1% lows; Reflex on |
| **MOBA** (LoL, Dota 2) | VRR+cap | refresh-locked | Frame consistency > peak FPS |
| **Fighting** (SF6, Tekken) | **V-Sync may be needed** for the engine; exclusive fullscreen | engine-locked (often 60) | Consistent frame delivery; wired pad/stick |
| **Racing/sim** | VRR+cap | ~3 under | Smooth frametimes; wheel USB no-suspend |

---

## 8. What competitive defaults do NOT do

- Don't overclock (that's a BIOS/user decision).
- Don't disable Secure Boot/TPM (breaks Vanguard/FACEIT).
- Don't run injectors/macros/memory tools (bans).
- Don't set Realtime priority (freeze risk).
- Don't disable Defender/Firewall/Windows Update.

The Esports profile is **fast because of disciplined, latency-aware defaults** — not because it crosses any safety or anti-cheat line.

---

This completes the documentation set. See the **checklists** in [`/checklists`](../checklists) and the **scripts** in [`/scripts`](../scripts) to apply John OS.
