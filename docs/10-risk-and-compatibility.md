# John OS — Risk Analysis & Compatibility Considerations

A frank look at what can go wrong, how John OS mitigates it, and what stays compatible. Read this before deploying to hardware.

---

## 1. Risk register

| # | Risk | Likelihood | Impact | Mitigation in John OS |
|---|---|---|---|---|
| R1 | **Anti-cheat ban** from a flagged tweak/tool | Low (by design) | Severe (account loss) | No memory editors/timer hacks/injection tools; Secure Boot+TPM kept; deprecated AMD Anti-Lag+ avoided; Process Lasso/overlays off by default with warnings. |
| R2 | **Over-debloat breaks launchers** (EA/Ubisoft/Game Pass) | Medium if uncurated | High | Curated keep-list (WebView2, Edge, Store, Xbox/Gaming Services, VC++/.NET). John OS removes noise, not plumbing. |
| R3 | **Security weakened** (Defender/Firewall/WU off) | Low | Severe | Those are a non-negotiable floor; Tamper Protection on; only VBS is an opt-in trade-off. |
| R4 | **Windows Update broken** by aggressive service/task kills | Low | High | WU services/tasks explicitly retained; updates slipstreamed; deferral ≠ disable. |
| R5 | **Bad/auto driver** causes instability | Medium | Medium | Vendor-direct drivers; WU optional-driver auto-install off; DDU guidance; no mass driver-updater bundled. |
| R6 | **Pagefile disabled** → random crashes | N/A (rejected) | High | John OS never disables the pagefile. |
| R7 | **VBS off** lowers kernel exploit defense | Opt-in only | Medium | Off only in Esports with explicit consent; everything else stays on; documented at every touch point. |
| R8 | **Defender exclusion** hides real malware | Low | High | No broad exclusions by default; shader-cache exclusion is narrow + opt-in; never whole drives. |
| R9 | **Unstable registry/timer tweaks** | N/A (rejected) | Medium | Only documented keys; TDR/C-states/Realtime-priority left alone. |
| R10 | **Image/servicing corruption** from editing protected files | Low | High | No patching of bootloader/system DLLs; `/ResetBase` done cleanly; SFC/DISM baseline preserved. |
| R11 | **Laptop battery/thermals** from desktop power profile | Medium on laptops | Medium | Ultimate Performance only on AC; balanced DC profile; power-throttle-off gated to AC. |
| R12 | **User can't revert** | Low | Medium | `-WhatIf`, restore point, per-key `.reg` backups, `99-restore-defaults.ps1`. |
| R13 | **Dual-boot clock/FS issues** (Fast Startup/BitLocker) | Medium for dual-booters | Low | Documented; Fast Startup toggle + BitLocker suspend guidance for firmware/dual-boot changes. |
| R14 | **Licensing/activation** confusion | Low | Low | User supplies genuine ISO + license; no activation tampering. |

---

## 2. Anti-cheat compatibility matrix

| Anti-cheat | Titles | Requirement | John OS status |
|---|---|---|---|
| Riot Vanguard | Valorant, LoL | Secure Boot **on**, TPM 2.0 **on**, signed drivers | ✅ Compatible |
| Easy Anti-Cheat | Fortnite, Apex, Elden Ring, many | Signed drivers, intact services | ✅ |
| BattlEye | R6 Siege, PUBG, DayZ, Destiny 2 | Same | ✅ |
| Ricochet | Call of Duty | Secure Boot (recommended/required) | ✅ |
| FACEIT AC | CS2 (FACEIT) | Secure Boot **required** | ✅ |
| ESEA | CS2 | Kernel driver (sig enforcement on) | ✅ |
| VAC | Steam/CS2 | No injection/memory edit | ✅ |

**Anti-cheat do/don't (enforced by John OS design):**
- ✅ Keep Secure Boot, TPM, driver-signature enforcement on.
- ✅ Keep Xbox/Gaming services (some titles probe them).
- ❌ Don't run memory editors, kernel timer hacks, or unsanctioned injectors.
- ⚠️ Treat overlays (RTSS) and affinity managers (Process Lasso) as **opt-in**; some strict titles dislike them.

---

## 3. Components that MUST remain (compatibility-critical)

Removing any of these breaks games/launchers — John OS keeps them all:
- **Microsoft Edge + WebView2 Runtime** → EA App, Ubisoft Connect, Riot client UI.
- **Microsoft Store + Gaming Services** → Game Pass / Store titles.
- **Xbox app, Xbox Identity Provider, Game Bar, Xbox Live services** → Game Pass, sign-in, captures, Reflex overlay.
- **Visual C++ Redistributables (2005–2022)** + **DirectX runtime** → nearly all games.
- **.NET Framework 3.5/4.8 + .NET desktop runtimes** → many games/launchers.
- **Windows Update stack** (wuauserv/UsoSvc/BITS) → security + servicing.
- **Defender + Firewall + Secure Boot chain** → security + anti-cheat.

(Full keep-list in [`docs/04-debloating.md`](04-debloating.md) §2.)

---

## 4. Hardware & firmware compatibility

| Area | Consideration |
|---|---|
| **Secure Boot / TPM** | Required by Win11 + several anti-cheats. Must be enabled in UEFI. Old CPUs off the Win11 list are unsupported. |
| **Resizable BAR / SAM** | Needs UEFI "Above 4G Decoding" + "Re-Size BAR". Big win on Intel Arc; can't be toggled from the OS. |
| **NVMe / storage** | Inject storage drivers into the image for bare-metal installs; RAID/VMD modes need the Intel/AMD driver at setup. |
| **Laptops / hybrid GPU** | Use the balanced DC profile; ensure games target the dGPU (per-app High-performance). |
| **Multi-monitor / VRR** | Verify max refresh + G-SYNC/FreeSync per display; mixed-refresh setups can need per-display config. |
| **BitLocker + firmware changes** | Suspend BitLocker before BIOS/Secure Boot changes to avoid recovery-key prompts. |

---

## 5. Stability test plan (before calling a build "stable")

1. **Soak:** 2–4 h gaming across 3+ titles incl. one anti-cheat title (Valorant/Fortnite/CS2).
2. **Crash dumps:** none; Reliability Monitor clean.
3. **Updates:** force a Windows Update + Defender definition update → succeed.
4. **Sleep/resume + reboot cycles:** ×5, no device/input loss.
5. **Stress (optional):** OCCT/Prime + FurMark short runs to confirm no OS-induced instability (clocks unchanged by John OS).
6. **Restore test:** run `99-restore-defaults.ps1` on a copy → back to stock behavior.
7. **LatencyMon:** 10-min idle + in-game → no pathological DPC spikes introduced.

A build passes only if **all** of §5 are clean **and** the acceptance criteria in [`docs/09`](09-benchmark-goals.md) §5 are met.

---

## 6. Support & rollback

- **System Restore** point auto-created before tuning (R12).
- **Per-key `.reg` backups** in `%ProgramData%\JohnOS\backups\`.
- **`99-restore-defaults.ps1`** re-enables services, restores registry, removes the John OS power plan, re-enables scheduled tasks.
- **Recovery image:** keep a clean `install.wim` (or a full disk image) so you can always reimage.
- **Reinstalling removed apps:** Store or `winget` — provisioned removals aren't permanent to the user.

---

## 7. Bottom line

John OS's risk profile is **low** precisely because its biggest "gains" don't come from dangerous tweaks. The few real trade-offs (VBS off, narrow Defender exclusions, laptop power) are **opt-in, documented, and reversible**. The non-negotiables — anti-cheat compatibility, Windows Update, Defender/Firewall, Secure Boot/TPM, the pagefile — are protected by design.

Continue to [`docs/11-competitive-gaming-defaults.md`](11-competitive-gaming-defaults.md).
