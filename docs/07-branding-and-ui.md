# John OS — Branding & User Interface

The visual identity of John OS is **dark, minimal, and gaming-inspired** — confident but not noisy, so it looks great on a desktop you stare at for hours and never gets in the way of a game.

A ready-to-render wallpaper concept ships in [`branding/wallpaper-johnos-concept.svg`](../branding/wallpaper-johnos-concept.svg). Full asset spec in [`branding/branding-concept.md`](../branding/branding-concept.md).

---

## 1. Brand identity

| Element | Definition |
|---|---|
| **Name** | John OS |
| **Tagline** | *"Built to win."* (alt: *"Pure performance."*) |
| **Personality** | Fast, precise, premium, understated. Think esports-team-meets-flagship-hardware, not RGB-explosion. |
| **Logo** | Wordmark **"JOHN OS"** in a geometric sans; a monogram **"J"** inside a hexagon for the icon/boot badge. |

### Color palette
| Role | Color | Hex |
|---|---|---|
| Background base | Near-black | `#0A0E14` |
| Surface / panels | Charcoal | `#141A24` |
| Primary accent | Electric cyan | `#00E5FF` |
| Secondary accent | Violet | `#7C4DFF` |
| Alert/energy (sparing) | Crimson | `#FF3B5C` |
| Text primary | Off-white | `#E6EDF3` |
| Text muted | Slate gray | `#8B98A9` |

> The cyan→violet gradient is the signature. Crimson is used **only** for energy accents (never large fills) to keep the look clean.

### Typography
- **Display / logo:** a geometric sans (e.g., *Michroma*, *Orbitron*, or *Rajdhani*) for the wordmark and boot/lock screens.
- **UI:** Windows **Segoe UI Variable** kept for system consistency and readability.

---

## 2. Custom wallpaper

**Concept:** centered **"JOHN OS"** wordmark over a dark, abstract field — subtle isometric grid receding to the horizon, faint hexagonal mesh, and a cyan-to-violet light streak suggesting motion/speed. A thin neon underline pulses under the wordmark. Bottom-corner tagline *"Built to win."* in muted slate.

- **Resolutions:** delivered at 3840×2160 (4K master), auto-scaled to 2560×1440 and 1920×1080.
- **Variants:** Balanced (cyan accent), Esports (crimson accent), Creator (violet accent).
- **Vector source:** `branding/wallpaper-johnos-concept.svg` (rasterize to PNG/JPG for deployment).

The SVG in this repo is a faithful, editable mock of this concept.

---

## 3. Theme & desktop

- **Dark mode by default** (apps + system).
- **Accent color** = electric cyan `#00E5FF` (per-profile variant).
- **Transparency:** on in Balanced/Creator (Mica/Acrylic look), off in Esports.
- **Minimalist desktop:** no shortcuts except Recycle Bin (optionally hidden); clean taskbar (centered or left, user choice), Widgets/Chat off, Search as icon.
- **Curated Start layout:** launchers + utilities pinned, no promotional tiles.
- **Custom cursor:** a subtle dark cursor scheme with cyan edge highlight (system cursor, not a game overlay).
- **Sounds:** muted/minimal scheme (no jarring default chimes); startup sound off.

---

## 4. Custom icons

- A cohesive **flat, slightly neon icon set** for John OS's own tools (Repair Toolkit, profile switcher) and pinned folders.
- Library/game-drive folders get custom hex-accent folder icons.
- Drive icons themed (OS drive vs game drive distinct).
- System app icons are **left default** (replacing protected system icons risks servicing issues) — John OS themes its **own** shortcuts and folders, not Windows binaries.

---

## 5. Custom boot logo

- Implemented via the **ACPI BGRT** (Boot Graphics Resource Table) / OEM badge mechanism — the supported, Secure-Boot-safe way to show a vendor logo at boot. On a build/OEM image this displays the **hex "J" monogram** under the firmware's spinner.
- **Note:** John OS does **not** patch `bootres.dll` or other signed boot binaries (that breaks Secure Boot and update servicing). Boot branding is done the supported way or left to firmware. This is an intentional security choice.

---

## 6. Custom lock screen & login

- **Lock screen:** dark John OS key art (wordmark + light streak), clock and date in the display font, no ads/Spotlight/"fun facts."
- **Sign-in:** matching dark background, accent-colored field highlights, Windows Hello (PIN/biometric) supported.
- **OOBE/first-run:** branded with John OS wordmark via the unattended setup; skips consumer upsell screens.

---

## 7. OEM system branding

Set during image build (see ISO roadmap):
- `Manufacturer = "John OS"`, `Model = "Gaming Edition"`, support URL, and a John OS logo BMP appear in **Settings → System → About** and the classic System panel.
- `SetupComplete.cmd` writes the OEM info and applies the wallpaper/lock screen/theme.

---

## 8. Visual identity summary

> **Dark. Fast. Precise.** Near-black canvas, a single confident cyan-violet gradient, a geometric wordmark, and zero clutter. It signals performance without screaming for attention — and it never costs a frame, because none of the branding runs in-game.

See [`branding/branding-concept.md`](../branding/branding-concept.md) for the full asset checklist (sizes, file formats, deployment paths).
