# John OS — Debloat Checklist

Curated removal. **Keep-list is as important as the remove-list** — the keep items are what stop launchers/Game Pass from breaking. Detail: [`docs/04-debloating.md`](../docs/04-debloating.md). Applied by [`scripts/01-debloat-apps.ps1`](../scripts/01-debloat-apps.ps1), [`08`](../scripts/08-privacy-telemetry.ps1), [`09`](../scripts/09-scheduled-tasks.ps1).

---

## Remove — consumer apps (provisioned + installed)
- [ ] News (`BingNews`), Weather (`BingWeather`), Bing Search (`BingSearch`)
- [ ] Get Help, Tips (`Getstarted`)
- [ ] Office Hub, OneNote (Store), Solitaire, To Do
- [ ] Mixed Reality Portal
- [ ] People, Skype, Feedback Hub, Maps
- [ ] Family, Power Automate, Quick Assist
- [ ] Teams **consumer** chat (`MSTeams`/`MicrosoftTeams`)
- [ ] Cortana
- [ ] (Optional) Your Phone, Mail&Calendar legacy, Movies&TV, Groove, Sticky Notes, Clipchamp — *kept in Creator*

## KEEP — game/launcher plumbing (do NOT remove)
- [ ] **App Installer (winget)**
- [ ] **Microsoft Store**
- [ ] **Xbox app + Gaming Services + Xbox Live services + Xbox Identity Provider**
- [ ] **Xbox Game Bar** (Reflex overlay, captures, Game Mode UI)
- [ ] **WebView2 Runtime** (EA/Ubisoft/Riot UIs)
- [ ] **Microsoft Edge** (un-pinned, not removed — hosts WebView2/Store)
- [ ] **Visual C++ Redistributables 2005–2022**
- [ ] **DirectX runtime**
- [ ] **.NET Framework 3.5 & 4.8 + .NET desktop runtimes**
- [ ] Photos, Calculator, Notepad, Terminal, Snipping Tool

## Optional features
- [ ] IE11 mode disabled
- [ ] Work Folders, XPS, Fax&Scan removed
- [ ] **SMB1 confirmed absent** (security)
- [ ] PowerShell 2.0 engine removed
- [ ] .NET 3.5 **kept** (old games)
- [ ] Hyper-V kept available (VBS); Sandbox optional

## Telemetry / privacy
- [ ] `AllowTelemetry=0` (Pro/Ent) / Required floor (Home)
- [ ] `DiagTrack` + `dmwappushservice` disabled
- [ ] Advertising ID off; tailored experiences off
- [ ] Activity history upload off; feedback = never
- [ ] Cloud content / Spotlight suggestions / "suggested apps" off
- [ ] Speech online off (offline kept); inking/typing personalization off
- [ ] **Defender cloud protection NOT disabled** by privacy pass

## Scheduled tasks — disable (telemetry only)
- [ ] Compatibility Appraiser, ProgramDataUpdater, StartupAppTask
- [ ] CEIP Consolidator, UsbCeip, Autochk\Proxy
- [ ] Feedback DmClient(+OnScenarioDownload)
- [ ] WER QueueReporting
- [ ] Maps tasks

## Scheduled tasks — KEEP (do NOT disable)
- [ ] **ScheduledDefrag** (SSD TRIM/retrim)
- [ ] **.NET NGEN** tasks (faster launches)
- [ ] **Windows Defender** tasks
- [ ] **Windows Update / UpdateOrchestrator** tasks
- [ ] **SystemRestore\SR**, TPM, Servicing tasks

## Start / taskbar / first-run
- [ ] Promo Start tiles unpinned; curated layout shipped
- [ ] Widgets/Chat off; Search → icon; Task View kept
- [ ] `SilentInstalledApps/PreInstalledApps/ContentDelivery` = off
- [ ] `DisableWindowsConsumerFeatures=1` (Pro+)

## Verify
- [ ] EA App, Ubisoft Connect, Game Pass title **all launch** (WebView2/Store intact)
- [ ] Store + winget functional; Windows Update functional
- [ ] `sfc /scannow` + `DISM /RestoreHealth` clean
- [ ] Idle process count / RAM measured vs stock — bench `09`
- [ ] Removed apps restorable via Store/winget (reversibility)
