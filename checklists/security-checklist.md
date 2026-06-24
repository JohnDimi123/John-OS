# John OS — Security Checklist

The security **floor**. Everything here stays on except the one clearly-marked ⚠️ opt-in trade-off. If any non-⚠️ box is unchecked, the build is **not** a valid John OS build.

> Detailed rationale: [`docs/03-security.md`](../docs/03-security.md). Applied by [`scripts/06-security-hardening.ps1`](../scripts/06-security-hardening.ps1).

---

## Microsoft Defender
- [ ] Real-time protection **ON**
- [ ] Cloud-delivered protection **ON**
- [ ] Behavior monitoring **ON**
- [ ] **Tamper Protection ON** (prevents Defender from being disabled)
- [ ] PUA protection **ON**
- [ ] Network protection **ON**
- [ ] Scheduled scans moved to **idle/off-hours**, low-CPU-priority — gaming-aware, not disabled
- [ ] Exclusions: **none broad**; only narrow opt-in shader-cache/anti-cheat dirs ⚠️ — never whole drives/`C:`/`Downloads`
- [ ] Sample submission: user choice (safe samples default); cloud protection NOT sacrificed for privacy

## Firewall
- [ ] Firewall **ON** for Domain, Private, **and Public**
- [ ] Inbound default **block**; per-app rules created on demand (no pre-opened ports)
- [ ] Public profile stricter; dropped-packet logging on
- [ ] No "disable firewall for gaming"

## Exploit protection
- [ ] System defaults **ON** (DEP, ASLR, bottom-up ASLR, SEHOP, CFG, heap integrity)
- [ ] Per-app mitigations **NOT force-enabled** on games (crash/anti-cheat risk)

## Boot & firmware integrity
- [ ] **Secure Boot ON** (required; Vanguard/FACEIT need it) — `Confirm-SecureBootUEFI` = True
- [ ] **TPM 2.0 ON** — `Get-Tpm` ready/enabled
- [ ] Measured Boot on
- [ ] **Driver signature enforcement ON** (no test-signing, ever)
- [ ] **Vulnerable Driver Blocklist ON**

## Core Isolation (the trade-off)
- [ ] Balanced/Creator: **VBS/HVCI ON**
- [ ] ⚠️ Esports only: VBS/HVCI may be **OFF** by explicit opt-in (script prompts + records choice)
- [ ] If VBS off: Secure Boot, TPM, Defender, Firewall **still ON** (only the hypervisor CI layer is dropped)

## Ransomware & data
- [ ] Controlled Folder Access **ON** with curated launcher/engine allow-list
- [ ] System Restore / Shadow Copy **ON**
- [ ] Save-file backup guidance offered (not forced)

## Accounts & credentials
- [ ] **UAC at default** (notify) — not lowered
- [ ] LSA Protection (RunAsPPL) **ON** where supported
- [ ] Credential Guard ON where supported (off only if VBS off — documented)
- [ ] Standard (non-admin) daily account + separate admin recommended/offered
- [ ] Windows Hello (PIN/biometric) supported

## SmartScreen & apps
- [ ] SmartScreen **ON** (apps + Edge)
- [ ] Store/winget app sources only; no driver-pack/crack sites

## Updates (security-critical)
- [ ] **Windows Update fully functional** (never disabled)
- [ ] Security/quality updates **NOT deferred**; only feature updates deferred (active hours set)
- [ ] Defender definitions update freely
- [ ] Latest SSU+LCU slipstreamed into the image (day-one patched)

## Privacy (without weakening security)
- [ ] Telemetry at edition minimum (`AllowTelemetry=0` on Pro/Ent)
- [ ] `DiagTrack`/`dmwappushservice` disabled
- [ ] Advertising ID, tailored experiences, activity-history upload **off**
- [ ] Defender **cloud protection kept on** despite privacy hardening

## Never (auto-fail if any are true)
- [ ] ❌ Defender disabled/removed
- [ ] ❌ Windows Update disabled/blocked
- [ ] ❌ Secure Boot or TPM disabled
- [ ] ❌ Firewall disabled
- [ ] ❌ UAC disabled/lowered
- [ ] ❌ Driver signature enforcement off / test-signing
- [ ] ❌ Whole-drive Defender exclusions
- [ ] ❌ SmartScreen off system-wide

## Verify
- [ ] `Get-MpComputerStatus` → real-time/tamper/cloud all on
- [ ] `Get-MpPreference` → no broad exclusions
- [ ] `Confirm-SecureBootUEFI` True; `Get-Tpm` ready
- [ ] Firewall on (all profiles); WU + Defender update succeed
- [ ] Anti-cheat title launches (Valorant/CS2-FACEIT/Fortnite)
