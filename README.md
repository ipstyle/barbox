# Toolbox

*[Deutsche Version →](README.de.md)*

A free, open-source **menu bar toolbox for macOS** — inspired by Parallels Toolbox, built with SwiftUI. Everything one click away: desktops, apps, images, backups, system controls, weather and finance.

**German and English UI** — switchable in the settings.

## Features

- **Desktop switching** — jump straight to desktop 1–9 by click (shows the active desktop)
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

1. Download `Toolbox-x.y.zip` from the [latest release](../../releases/latest) and unzip it.
2. Move `Toolbox.app` to `/Applications`.
3. **First launch:** the app is not notarized (no paid Apple developer account behind this project). macOS will warn you — right-click the app → **Open** → **Open**. Alternatively:

```bash
xattr -d com.apple.quarantine /Applications/Toolbox.app
```

## Permissions

Each permission is requested on first use only:

| Feature | Permission |
|---|---|
| Desktop switching | Accessibility (simulates Ctrl+1…9; the app can enable those Mission Control shortcuts for you) |
| Bluetooth toggle | [blueutil](https://github.com/toy/blueutil) (`brew install blueutil`) + Bluetooth permission |
| Weather | Location (or set a fallback place in settings) |
| Timer | Notifications |
| Light/dark toggle | Automation (System Events) |

## Privacy

No accounts, no tracking, no analytics. Network connections only to: `api.open-meteo.com` (weather), `api.frankfurter.dev` (currency rates), `data.snb.ch` (Swiss interest rates) and `api.ipify.org` (public IP, on click only). The speed test uses Apple's built-in `networkQuality`. Nothing else leaves your Mac.

## Build from source

Requires Xcode command line tools (Swift 5.9+). No Xcode project needed:

```bash
git clone https://github.com/ipstyle/toolbox.git
cd toolbox
./build.sh
open build/Toolbox.app
```

## License

[GPL-3.0](LICENSE) · © 2026 ipstyle
