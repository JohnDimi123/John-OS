# John OS — Branding Asset Specification

Complete production checklist for the John OS visual identity. The narrative concept lives in [`docs/07-branding-and-ui.md`](../docs/07-branding-and-ui.md); this file is the **deliverables + deployment** spec.

---

## 1. Brand core

- **Wordmark:** `JOHN OS` — geometric sans, heavy weight, wide letter-spacing on "OS".
- **Monogram:** `J` centered in a hexagon (icon, boot badge, favicon).
- **Palette:** base `#0A0E14` · surface `#141A24` · cyan `#00E5FF` · violet `#7C4DFF` · crimson `#FF3B5C` · text `#E6EDF3` · muted `#8B98A9`.
- **Signature:** cyan→violet horizontal gradient + a single light streak.
- **Tagline:** *"Built to win."* / *"Pure performance."*

---

## 2. Asset manifest

| Asset | Format | Sizes | Deploy path (in image) |
|---|---|---|---|
| Desktop wallpaper (Balanced/cyan) | JPG + PNG (from SVG master) | 3840×2160, 2560×1440, 1920×1080 | `C:\Windows\Web\Wallpaper\JohnOS\` |
| Wallpaper (Esports/crimson, Creator/violet) | JPG/PNG | same | same folder, variant names |
| Lock screen art | JPG | 3840×2160 | `C:\Windows\Web\Screen\JohnOS-lock.jpg` |
| Boot badge (BGRT/OEM) | BMP, ≤300×300, 32-bit | per firmware spec | OEM logo slot |
| OEM logo (About page) | BMP, 120×120 | `C:\Windows\System32\oemlogo.bmp` | via `OEMInformation` reg |
| App/folder icon set | ICO (multi-res 16–256) | — | `C:\ProgramData\JohnOS\icons\` |
| Cursor scheme | CUR/ANI | — | `C:\Windows\Cursors\JohnOS\` |
| Accent / theme | `.theme` + `.deskthemepack` | — | `C:\Windows\Resources\Themes\JohnOS.theme` |

> The repo's [`wallpaper-johnos-concept.svg`](wallpaper-johnos-concept.svg) is the editable master; rasterize with Inkscape/ImageMagick:
> ```bash
> # Example: 4K PNG from the SVG
> inkscape wallpaper-johnos-concept.svg -w 3840 -h 2160 -o JohnOS-4k.png
> # then JPG variants
> magick JohnOS-4k.png -resize 2560x1440 -quality 92 JohnOS-1440.jpg
> magick JohnOS-4k.png -resize 1920x1080 -quality 92 JohnOS-1080.jpg
> ```

---

## 3. Theme (`JohnOS.theme`) key fields

```ini
[Theme]
DisplayName=John OS

[Control Panel\Desktop]
Wallpaper=%SystemRoot%\Web\Wallpaper\JohnOS\JohnOS-4k.jpg
WallpaperStyle=10            ; Fill

[VisualStyles]
SystemMode=Dark
AppMode=Dark
AutoColorization=0
ColorizationColor=0XFF00E5FF ; cyan accent
EnableTransparency=1         ; 0 in Esports variant

[Control Panel\Cursors]
DefaultValue=John OS
```

---

## 4. OEM info (System → About)

Applied by `SetupComplete.cmd`:
```reg
[HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation]
"Manufacturer"="John OS"
"Model"="Gaming Edition"
"SupportURL"="https://github.com/johndimi123/john-os"
"Logo"="C:\\Windows\\System32\\oemlogo.bmp"
```

---

## 5. Deployment notes & guardrails

- Wallpaper/lock screen/theme are applied **per-user at first logon** (or by policy) — no protected system file is replaced.
- **Do not** replace `imageres.dll`/`shell32.dll` system icons or patch `bootres.dll`; that breaks servicing and Secure Boot. John OS themes its **own** shortcuts/folders and uses the supported BGRT path for the boot badge (see UI doc §5).
- Lock screen "Windows Spotlight" is disabled so the John OS art isn't overridden.
- All branding is **cosmetic and zero-cost in-game** — none of it runs while a game is in the foreground.

---

## 6. Variants summary

| Profile | Accent | Transparency | Wallpaper file |
|---|---|---|---|
| Balanced | Cyan `#00E5FF` | On | `JohnOS-4k.jpg` |
| Esports | Crimson `#FF3B5C` | Off | `JohnOS-esports-4k.jpg` |
| Creator | Violet `#7C4DFF` | On | `JohnOS-creator-4k.jpg` |
