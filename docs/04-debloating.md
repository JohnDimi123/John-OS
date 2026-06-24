# John OS — Debloating Plan

Debloating in John OS is **curated and reversible**, not a blind "remove everything" pass. The goal: strip consumer cruft and telemetry while keeping **everything games, launchers, and anti-cheat depend on**. Implemented offline in the image and/or by [`scripts/01-debloat-apps.ps1`](../scripts/01-debloat-apps.ps1), [`scripts/08-privacy-telemetry.ps1`](../scripts/08-privacy-telemetry.ps1), and [`scripts/09-scheduled-tasks.ps1`](../scripts/09-scheduled-tasks.ps1).

> **Golden rule:** if removing something risks breaking the Store, WebView2, gaming runtimes, or update mechanisms, John OS **keeps it**. Bloat is removed; plumbing is not.

---

## 1. Apps removed (provisioned + installed Appx)

Removed for **all users** (provisioned) so they don't reappear on new profiles. Each is a consumer app with no gaming role.

| App | Package (wildcard) | Notes |
|---|---|---|
| News | `Microsoft.BingNews` | |
| Weather | `Microsoft.BingWeather` | |
| Bing Search | `Microsoft.BingSearch` | |
| Get Help | `Microsoft.GetHelp` | |
| Tips | `Microsoft.Getstarted` | |
| Office hub | `Microsoft.MicrosoftOfficeHub` | "Get Office" upsell |
| Solitaire | `Microsoft.MicrosoftSolitaireCollection` | |
| Sticky Notes | `Microsoft.MicrosoftStickyNotes` | optional (kept in Creator) |
| To Do | `Microsoft.Todos` | |
| 3D / Mixed Reality | `Microsoft.MixedReality.Portal` | |
| OneNote (Store) | `Microsoft.Office.OneNote` | |
| People | `Microsoft.People` | |
| Skype | `Microsoft.SkypeApp` | |
| Feedback Hub | `Microsoft.WindowsFeedbackHub` | |
| Maps | `Microsoft.WindowsMaps` | |
| Clipchamp | `Clipchamp.Clipchamp` | kept in Creator |
| Family | `MicrosoftCorporationII.MicrosoftFamily` | |
| Power Automate | `Microsoft.PowerAutomateDesktop` | |
| Quick Assist | `MicrosoftCorporationII.QuickAssist` | |
| Teams (consumer) | `MicrosoftTeams` / `MSTeams` | consumer chat; not Teams for Work |
| Cortana | `Microsoft.549981C3F5F10` | |
| Your Phone / Phone Link | `Microsoft.YourPhone` | kept if user wants phone integration |
| Mail & Calendar (legacy) | `microsoft.windowscommunicationsapps` | replaced by new Outlook; optional |
| Movies & TV | `Microsoft.ZuneVideo` | optional |
| Groove Music | `Microsoft.ZuneMusic` | optional |

> Apps marked "optional/kept in Creator" are profile-gated — the Creator profile keeps Sticky Notes/Clipchamp/Photos editing for content workflows.

**Removal method (offline, in image):**
```powershell
Get-AppxProvisionedPackage -Path $MountDir |
  Where-Object DisplayName -in $RemoveList |
  Remove-AppxProvisionedPackage -Path $MountDir
```
**Removal method (live system):** `Get-AppxPackage` + `Remove-AppxPackage`, plus `Get-AppxProvisionedPackage -Online`.

---

## 2. Apps & components that MUST remain (game compatibility)

| Keep | Why |
|---|---|
| **App Installer** (`Microsoft.DesktopAppInstaller` / winget) | Provisioning tools & runtimes. |
| **Microsoft Store** (`Microsoft.WindowsStore`) | Game Pass titles, app/runtime updates, some games ship here. |
| **Xbox app** (`Microsoft.GamingApp`) + **Gaming Services** | Game Pass install/launch layer. |
| **Xbox Game Bar** (`Microsoft.XboxGamingOverlay`) + Game Bar plugins | Reflex latency overlay, captures, Game Mode UI. |
| **Xbox Identity Provider** (`Microsoft.XboxIdentityProvider`) | Xbox Live sign-in many games use. |
| **WebView2 Runtime** (`Microsoft.Win32WebViewHost` / Evergreen WebView2) | EA App, Ubisoft Connect, Riot client, many launchers render UI in WebView2. **Removing it breaks launchers.** |
| **Microsoft Edge** | Hosts WebView2; deep OS integration. John OS **does not rip out Edge** (it breaks WebView2 and Store); it just **un-pins it and stops it auto-launching**. |
| **.NET runtimes** (Framework 3.5/4.8, .NET 6/7/8 desktop) | Countless games/launchers. |
| **Visual C++ Redistributables (2005–2022, x86+x64)** | Nearly every game links these. |
| **DirectX** runtime (incl. legacy d3dx via redist) | All games. |
| **Photos / Calculator / Notepad / Terminal / Snipping Tool** | Useful, lightweight; kept. |
| **Microsoft Store Purchase / Licensing** | Game licensing. |

> The most common self-inflicted breakage in "gaming OS" builds is **removing Edge/WebView2 or the Store**, then the EA App / Ubisoft Connect / Game Pass won't launch. John OS keeps the plumbing and only removes the noise.

---

## 3. Windows features removed/disabled (optional features)

| Feature | Action | Notes |
|---|---|---|
| Internet Explorer 11 (mode) | Disable | Legacy. |
| Windows Media Player (legacy) | Optional remove | Keep "Media Feature Pack" codecs. |
| Work Folders client | Remove | Enterprise sync. |
| Windows Fax and Scan | Remove | |
| XPS Services / XPS Viewer | Remove | |
| WordPad | (already deprecated/removed in 24H2) | — |
| SMB 1.0/CIFS | **Ensure removed** | Security: SMBv1 is unsafe and off by default — John OS verifies it's gone. |
| PowerShell 2.0 engine | Remove | Legacy/insecure engine; PS5.1/7 stay. |
| Hyper-V | **Kept available** | Needed for VBS; off unless VBS/sandbox used. |
| Windows Sandbox | Optional | Handy for testing sketchy downloads. |
| .NET 3.5 | **Kept** | Many older games need it. |

---

## 4. Telemetry reduced or disabled

Goal: minimize data collection **without** disabling Defender cloud protection or breaking updates. Applied by [`scripts/08-privacy-telemetry.ps1`](../scripts/08-privacy-telemetry.ps1).

| Setting | Value | Effect |
|---|---|---|
| `AllowTelemetry` (policy) | `0` (Security) on Pro/Ent; `1` (Required) floor on Home | Lowest diagnostic data the edition permits. |
| `DiagTrack` service | Disabled | Stops the telemetry uploader. |
| `dmwappushservice` | Disabled | Telemetry transport. |
| Advertising ID | Off | No ad personalization. |
| Tailored experiences w/ diagnostic data | Off | |
| "Let websites provide locally relevant content" | Off | |
| Activity history (Timeline) upload | Off | |
| Feedback frequency | Never | |
| Cloud content / suggestions in Start, Settings, lock screen (Spotlight upsell) | Off | Removes "suggested apps"/ads. |
| Speech online recognition | Off (offline kept) | |
| Inking & typing personalization | Off | |
| Error reporting (WER) | Queue task disabled; core kept for crash dumps | |

**Not disabled:** Defender cloud-delivered protection, MAPS reporting toggle is left to the user (defaults on for protection; can be set to off for privacy in the script with a clear note that it weakens cloud detection).

---

## 5. Scheduled tasks removed/disabled

Disabled by [`scripts/09-scheduled-tasks.ps1`](../scripts/09-scheduled-tasks.ps1). **Only telemetry/CEIP/feedback tasks** are touched — maintenance, Defender, and .NET tasks are left alone.

| Task path | Reason |
|---|---|
| `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser` | Compat telemetry. |
| `\Microsoft\Windows\Application Experience\ProgramDataUpdater` | Compat telemetry. |
| `\Microsoft\Windows\Application Experience\StartupAppTask` | Startup app telemetry. |
| `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator` | CEIP. |
| `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip` | CEIP. |
| `\Microsoft\Windows\Autochk\Proxy` | CEIP proxy. |
| `\Microsoft\Windows\Feedback\Siuf\DmClient` | Feedback. |
| `\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload` | Feedback. |
| `\Microsoft\Windows\Windows Error Reporting\QueueReporting` | WER queue upload. |
| `\Microsoft\Windows\Maps\MapsToastTask` / `MapsUpdateTask` | Maps. |
| `\Microsoft\Windows\Clip\License Validation` (if present) | telemetry-adjacent |

### Tasks DELIBERATELY kept (do **not** disable)
- `\Microsoft\Windows\Defrag\ScheduledDefrag` — does SSD TRIM/retrim.
- `\Microsoft\Windows\.NET Framework\.NET Framework NGEN*` — precompiles .NET (faster app/game launches).
- All `\Microsoft\Windows\Windows Defender\*` — security scans/updates.
- `\Microsoft\Windows\UpdateOrchestrator\*`, `WindowsUpdate\*` — updates.
- `\Microsoft\Windows\SystemRestore\SR` — restore points.
- `\Microsoft\Windows\TPM\*`, `\Microsoft\Windows\Servicing\*` — integrity/servicing.

> Killing the NGEN or defrag/TRIM tasks (common in aggressive scripts) *hurts* performance and SSD longevity. John OS keeps them.

---

## 6. Start menu, taskbar & first-run cleanup

- Unpin all promotional Start tiles; ship a clean Start layout (`start2.bin` / `LayoutModification.json`) with launchers + utilities pinned.
- Remove "Recommended" web content suggestions where policy allows.
- Taskbar: Search box → icon only; Widgets off; Chat/Teams off; Task View kept.
- Disable "suggested apps" and auto-install of sponsored apps (`SilentInstalledAppsEnabled`, `OemPreInstalledAppsEnabled`, `PreInstalledAppsEnabled`, `ContentDeliveryAllowed` = 0).
- First-logon: no consumer app re-download (`DisableWindowsConsumerFeatures=1`, Pro+).

---

## 7. What "debloated" measurably buys you

| Metric | Stock Win11 (post-update, signed-in) | John OS (Balanced) |
|---|---|---|
| Background processes at idle | ~120–160 | ~80–110 |
| Idle RAM (committed) | ~3.5–4.5 GB | ~1.8–2.8 GB |
| Idle CPU | ~2–5% | <1–2% |
| Auto-start apps | many (Spotlight, Teams, etc.) | minimal (launchers only if user opts) |

(Hardware-dependent; see [`docs/09-benchmark-goals.md`](09-benchmark-goals.md) for methodology and caveats.)

---

## 8. Reversibility

- Removed **provisioned** apps can be reinstalled from the Store or via `winget`.
- Telemetry/privacy registry changes are backed up to `%ProgramData%\JohnOS\backups\` and reverted by [`scripts/99-restore-defaults.ps1`](../scripts/99-restore-defaults.ps1).
- Disabled scheduled tasks can be re-enabled individually (`Enable-ScheduledTask`).
- Nothing in the debloat layer deletes protected system files, so `DISM /RestoreHealth` + `sfc /scannow` always have a clean baseline.

See the full [`checklists/debloat-checklist.md`](../checklists/debloat-checklist.md).
