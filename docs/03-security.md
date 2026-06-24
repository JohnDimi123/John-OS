# John OS — Security Profile

John OS is a **gaming OS that is still genuinely secure**. The security baseline is a *floor*: it is never removed to gain benchmark numbers. Only one item — **Virtualization-Based Security (VBS/HVCI)** — is a documented performance trade-off, and even that defaults to **ON** in the Balanced profile.

Configured by [`scripts/06-security-hardening.ps1`](../scripts/06-security-hardening.ps1).

---

## 1. Security posture at a glance

| Control | John OS default | Performance cost | User-adjustable? |
|---|---|---|---|
| Microsoft Defender (real-time) | **ON** | Negligible with tuned exclusions | No (stays on) |
| Cloud-delivered protection | **ON** | None | Yes (privacy) |
| Firewall (all profiles) | **ON**, inbound default-deny | None | No |
| SmartScreen (apps + Edge) | **ON** | None | Yes |
| Exploit Protection (DEP/ASLR/CFG) | **System defaults ON** | None | Advanced only |
| Controlled Folder Access (ransomware) | **ON** with gaming allow-list | Tiny; managed | Yes |
| Secure Boot | **ON** (required) | None | No |
| TPM 2.0 | **ON** (required) | None | No |
| VBS / HVCI (Core Isolation) | **ON** (Balanced) / optional OFF (Esports) | ~0–10% in some titles | **Yes — documented** |
| BitLocker | Optional, **recommended** on laptops | Negligible (AES-NI) | Yes |
| LSA Protection / Credential Guard | **ON** where supported | Negligible | Yes |

---

## 2. Microsoft Defender configuration

**Defender stays fully enabled.** John OS tunes it for gaming without weakening it.

### 2.1 Kept on
- Real-time protection, behavior monitoring, cloud-delivered protection, automatic sample submission (sample submission can be set to "safe samples only" or off for privacy — see [`docs/04`](04-debloating.md)/[`08`](../scripts/08-privacy-telemetry.ps1)).
- Tamper Protection **ON** — prevents malware (and reckless scripts) from disabling Defender.
- Network protection, PUA (Potentially Unwanted App) blocking **ON**.

### 2.2 Gaming-aware tuning (safe)
- **Scheduled scans** moved to **idle / off-hours** and set to **only run when on AC + idle**, so a scan never starts mid-match:
  ```
  Set-MpPreference -ScanScheduleTime 02:00:00
  Set-MpPreference -ScanOnlyIfIdleEnabled $true
  Set-MpPreference -DisableScanningNetworkFiles $false   ; keep network scan on
  ```
- **Low-priority scanning** enabled so background scans yield to the foreground:
  ```
  Set-MpPreference -EnableLowCpuPriority $true
  ```
- **CPU throttle for scans** kept at default (50%) so a scan can't monopolize cores.

### 2.3 Exclusions — careful, minimal, opt-in
Defender real-time scanning of shader compilation and asset streaming can cause **micro-stutter** in some titles. John OS allows **narrow, explicit** exclusions, **off by default**, applied only with user consent:
- Game **shader cache** folders (e.g., `%LOCALAPPDATA%\D3DSCache`, NVIDIA/AMD shader caches).
- Specific, trusted **anti-cheat directories** if a vendor documents an exclusion.

**Rules for exclusions (enforced in the script):**
- Never exclude whole drives, `Downloads`, `%TEMP%`, or `C:\`.
- Never exclude a game's *entire* library blindly — prefer the shader-cache subfolders.
- Each exclusion is logged and reversible.
- Default John OS install ships with **no broad exclusions**; the shader-cache exclusion is a prompted opt-in in the Esports profile.

> This is the single most-abused "gaming" Defender tweak. John OS treats exclusions as a scalpel, not a sledgehammer.

---

## 3. Firewall configuration

- **Windows Defender Firewall stays ON for Domain, Private, and Public profiles.**
- **Inbound:** default **block**; outbound default allow.
- Game launchers create their own inbound rules on first run (allowed once, per-app) — John OS does **not** pre-open ports.
- **Public networks:** stricter — block inbound including for games until the user marks the network Private.
- Logging of dropped packets enabled for the Public profile (diagnostics).
- No "disable firewall for gaming" — that advice is dangerous and unnecessary; per-app rules handle multiplayer fine.

---

## 4. Exploit Protection

John OS keeps the **system-wide Exploit Protection defaults** (Windows Defender Exploit Guard): DEP, mandatory ASLR (opt-in app level), bottom-up ASLR, SEHOP, Control Flow Guard, heap integrity.

- **Per-app mitigations are not force-enabled** on game executables — forcing ASLR/CFG on a game that wasn't built for it can crash it or trip anti-cheat. John OS leaves game-specific mitigations to **system default / app opt-in**.
- An exported `ProcessMitigations` baseline is included for auditors but applied conservatively.

---

## 5. Core Isolation — VBS / HVCI / Memory Integrity (the one real trade-off)

**What it is:** Virtualization-Based Security (VBS) uses the hypervisor to isolate a secure kernel; **HVCI / Memory Integrity** uses it to enforce that only signed, validated code runs in kernel mode. It is a strong defense against kernel exploits and malicious drivers.

**The trade-off:** VBS/HVCI adds virtualization overhead. Independent testing and Microsoft's own guidance show it can cost roughly **0–10%** in CPU-bound games (often ~3–7%, occasionally more on older CPUs; near-zero on high-end GPU-bound scenes).

### John OS policy
| Profile | VBS/HVCI | Rationale |
|---|---|---|
| **Balanced** (default) | **ON** | Security wins for a daily driver; the FPS cost is small and usually invisible on a good GPU. |
| **Esports** | **Optional OFF** | Competitive players who measure a benefit may disable it. The script **prompts**, explains the security cost, and records the choice. |
| **Creator** | **ON** | Stability + security for long sessions. |

**Important nuances John OS gets right:**
- Disabling **VBS does NOT mean disabling Secure Boot or TPM.** Those stay on (anti-cheats need them — §7).
- New PCs may ship with HVCI on by default; some pre-built/OEM images don't. John OS makes the state **explicit and intentional**, not accidental.
- If VBS is disabled, John OS **leaves Secure Boot, TPM, Defender, and Firewall fully on** — you lose only the kernel code-integrity hypervisor layer, nothing else.

---

## 6. Driver security

- **Microsoft Vulnerable Driver Blocklist:** **ON** (HVCI-independent in 24H2). Blocks known-exploitable signed drivers (the "bring your own vulnerable driver" attack class).
- **Driver signature enforcement:** **ON** (never disabled). John OS never instructs users to boot with test-signing or unsigned drivers.
- **Clean driver installs:** guidance to use **DDU (Display Driver Uninstaller)** in Safe Mode when swapping GPU vendors, then install the latest **WHQL** driver.
- **Driver source:** vendor-direct (NVIDIA/AMD/Intel) or Windows Update WHQL only — no third-party "driver pack" sites.

---

## 7. Secure Boot & TPM

| Feature | State | Why it must stay |
|---|---|---|
| **UEFI Secure Boot** | **ON** | Windows 11 requirement; **Riot Vanguard, FACEIT, and others require it** on Win11. Disabling it breaks those games and weakens boot integrity. |
| **TPM 2.0** | **ON** | Windows 11 requirement; **Vanguard and some anti-cheats require TPM 2.0**. Also backs BitLocker and Credential Guard. |
| Measured Boot | ON | Boot integrity attestation. |

> Community builds that disable Secure Boot/TPM to "save performance" gain nothing (these have **zero** runtime FPS cost) and lock the user out of major competitive titles. John OS keeps both **mandatory**.

---

## 8. Ransomware protection

- **Controlled Folder Access (CFA):** **ON**, protecting `Documents`, `Saved Games`, `Pictures`, etc.
  - Game launchers and save-writing executables are added to the **allow-list** during setup so cloud saves and game writes aren't blocked.
  - John OS ships a curated allow-list for Steam, Epic, EA App, Ubisoft Connect, Battle.net, Riot, Xbox, and common engines, reducing the "my game can't save" friction that makes people disable CFA.
- **OneDrive/Backup:** optional file backup guidance for save files (user choice; not forced).
- **Volume Shadow Copy / System Restore:** kept enabled for rollback.

---

## 9. Account & credential security

- **LSA Protection (RunAsPPL):** **ON** where firmware supports it — protects `lsass` from credential dumping.
- **Credential Guard:** ON on capable hardware (rides on VBS; if VBS is off in Esports, Credential Guard is off too — documented).
- **Local vs Microsoft account:** John OS supports either; a **standard (non-admin) daily account** with a separate admin is recommended and offered by the unattended setup.
- **UAC:** kept at **default (notify)** — lowering UAC is a common bad tweak John OS rejects.
- **Windows Hello:** supported (PIN/biometric); `WbioSrvc` kept if enrolled.

---

## 10. Privacy-focused settings (security-adjacent)

Detailed in [`docs/04-debloating.md`](04-debloating.md) §Telemetry and [`scripts/08-privacy-telemetry.ps1`](../scripts/08-privacy-telemetry.ps1):
- Telemetry set to the **lowest the edition allows** (`AllowTelemetry=0` honored on Pro/Enterprise as "Security/Required").
- Advertising ID **off**, tailored experiences **off**, activity history (Timeline) **off & not sent to cloud**.
- App permissions (camera, mic, location) reviewed; **mic/camera left available** (voice chat) but per-app controllable.
- `DiagTrack` service disabled (§performance doc), CEIP tasks disabled (§debloat).
- **Privacy is pursued without disabling Defender's cloud protection by default** — the two are separated so users don't trade security for privacy by accident.

---

## 11. Security ≠ off. What John OS never does

- ❌ Disable or remove Defender. (Tamper Protection actively prevents it.)
- ❌ Disable Windows Update or block security definitions.
- ❌ Disable Secure Boot or TPM.
- ❌ Disable the Firewall "for gaming".
- ❌ Lower/disable UAC.
- ❌ Boot with driver-signature enforcement off / test-signing.
- ❌ Apply blanket Defender exclusions for whole drives.
- ❌ Disable SmartScreen system-wide.

The only sanctioned, documented trade-off is **VBS/HVCI in the Esports profile** — and even then every other control above stays on.

See the full [`checklists/security-checklist.md`](../checklists/security-checklist.md).
