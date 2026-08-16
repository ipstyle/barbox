# BarBox

*[Deutsche Version →](README.de.md)*

A free, open-source **menu bar toolbox for macOS** — everything one click away: apps, images, PDFs, backups, system controls, weather and finance. Formerly known as *Toolbox / AF-Toolbox*.

**English and German UI** — English by default, switchable in the settings.

<p align="center">
  <img src="docs/menubar.jpg" alt="BarBox icon in the menu bar" width="280">
</p>
<p align="center">
  <img src="docs/dashboard-en.jpg" alt="Dashboard (English UI) with CPU/MEM/GPU stats, status chips, sliders, favorites, tools and weather" width="360">
  <img src="docs/dashboard-de.jpg" alt="Dashboard (German UI) with CPU/MEM/GPU stats, status chips, sliders, favorites, tools and weather" width="360">
</p>
<p align="center">
  <img src="docs/about.jpg" alt="Settings with about section" width="360">
</p>

## Features

- **Live stats** — CPU, MEM and GPU usage right in the header
- **Status chips** — battery, Wi-Fi and Bluetooth toggle, AirDrop mode, all as dropdowns
- **Controls** — display brightness, volume, audio output device
- **Favorites** — combine your most-used tools and quick actions, drag & drop to arrange; all sections are collapsible and reorderable
- **Tools**
  - Keep awake (unlimited / 30 min / 1 h / 2 h)
  - Image compression (AI preset 1568 px, half-size 50 %, JPEG output)
  - Text from image (OCR, offline via Apple Vision)
  - Merge PDFs, QR code generator, batch rename with patterns
  - Clipboard history (last 20, in-memory only)
  - Timer with notification, password/UUID generator
  - Network & info: local/public IP, internet speed test (with history), system info
  - Finance: CHF→EUR/USD converter (ECB rates), Swiss SARON & SNB policy rate
  - Time Machine status & backup start
  - Weather: current + 5-day forecast at your location (MeteoSwiss ICON model via Open-Meteo)
- **App launcher** — drag apps from Finder into "My apps", searchable list of all installed apps
- **Persistent window** — stays open until you click the menu bar icon again; window size adjustable

## Installation

1. Download `BarBox-x.y.zip` from the [latest release](../../releases/latest) and unzip it.
2. Move `BarBox.app` to `/Applications`.
3. **First launch:** the GitHub build is not notarized. macOS will warn you — right-click the app → **Open** → **Open**. Alternatively:

```bash
xattr -d com.apple.quarantine /Applications/BarBox.app
```

A sandboxed Mac App Store edition is in preparation; the GitHub build always keeps the full feature set.

## Permissions

Each permission is requested on first use only:

| Feature | Permission |
|---|---|
| Bluetooth toggle | [blueutil](https://github.com/toy/blueutil) (`brew install blueutil`) + Bluetooth permission |
| Weather | Location (or set a fallback place in settings) |
| Timer | Notifications |
| Light/dark toggle, Focus | Automation (System Events / Shortcuts) |

**Upgrading from Toolbox 1.x:** version 2.0 has a new bundle identifier, so macOS asks for these permissions once again and "Launch at login" must be re-enabled. Your app favorites are migrated automatically.

## Privacy

No accounts, no tracking, no analytics. Network connections only to: `api.open-meteo.com` (weather), `api.frankfurter.dev` (currency rates), `data.snb.ch` (Swiss interest rates) and `api.ipify.org` (public IP, on click only). The speed test uses Apple's built-in `networkQuality`. Nothing else leaves your Mac.

Full details: [Privacy Policy](PRIVACY.md).

## Build from source

Requires Xcode command line tools (Swift 5.9+). No Xcode project needed:

```bash
git clone https://github.com/ipstyle/barbox.git
cd barbox
./build.sh
open build/BarBox.app
```

## License

[GPL-3.0](LICENSE) · © 2026 ipstyle

Copying, forking and redistribution are welcome under the GPL-3.0 terms — please keep the attribution to **ipstyle/barbox**.
