# BarBox

**[BarBox-Website →](https://ipstyle.github.io/barbox/)** · *[English version →](README.md)*

Eine kostenlose, quelloffene **Menüleisten-Toolbox für macOS** — alles einen Klick entfernt: Apps, Bilder, PDFs, Backups, Systemregler, Wetter und Finanzen. Früher bekannt als *Toolbox / AF-Toolbox*.

**Englisch und Deutsch** — Standard ist Englisch, umschaltbar in den Einstellungen.

<p align="center">
  <img src="docs/menubar.jpg" alt="BarBox-Symbol in der Menüleiste" width="280">
</p>
<p align="center">
  <img src="docs/dashboard-de.jpg" alt="Dashboard (deutsche Oberfläche) mit CPU/MEM/GPU-Anzeige, Status-Chips, Reglern, Favoriten, Werkzeugen und Wetter" width="360">
  <img src="docs/dashboard-en.jpg" alt="Dashboard (englische Oberfläche) mit CPU/MEM/GPU-Anzeige, Status-Chips, Reglern, Favoriten, Werkzeugen und Wetter" width="360">
</p>
<p align="center">
  <img src="docs/about.jpg" alt="Einstellungen mit Info-Bereich" width="360">
</p>

## Funktionen

- **Live-Werte** — CPU-, MEM- und GPU-Auslastung direkt im Kopfbereich
- **Status-Chips** — Batterie, WLAN- und Bluetooth-Schalter, AirDrop-Modus, alles als Dropdown
- **Regler** — Display-Helligkeit, Lautstärke, Audio-Ausgabegerät
- **Favoriten** — die wichtigsten Werkzeuge und Schnellaktionen kombiniert, per Drag & Drop sortierbar; alle Sektionen einklappbar und verschiebbar
- **Werkzeuge**
  - Wach halten (unbegrenzt / 30 min / 1 h / 2 h)
  - Bilder komprimieren (AI-Preset 1568 px, halb so gross 50 %, JPEG-Ausgabe)
  - Text aus Bild (OCR, offline via Apple Vision)
  - PDFs zusammenfügen, QR-Code-Generator, Batch-Umbenennen mit Mustern
  - Zwischenablage-Verlauf (letzte 20, nur im Arbeitsspeicher)
  - Timer mit Mitteilung, Passwort/UUID-Generator
  - Netzwerk & Info: lokale/öffentliche IP, Internet-Speedtest (mit Historie), Systeminfo
  - Finanzen: CHF→EUR/USD-Rechner (EZB-Kurse), SARON & SNB-Leitzins
  - Time-Machine-Status & Backup-Start
  - Wetter: aktuell + 5-Tage-Vorhersage am Standort (MeteoSchweiz-Modell ICON via Open-Meteo)
- **App-Starter** — Apps aus dem Finder in «Meine Apps» ziehen, durchsuchbare Liste aller installierten Apps
- **Persistentes Fenster** — bleibt offen, bis du erneut aufs Menüleisten-Symbol klickst; Grösse einstellbar

## Installation

1. `BarBox-x.y.zip` aus dem [neusten Release](../../releases/latest) laden und entpacken.
2. `BarBox.app` nach `/Programme` (`/Applications`) verschieben.
3. **Erster Start:** Der GitHub-Build ist nicht notarisiert. macOS warnt darum — Rechtsklick auf die App → **Öffnen** → **Öffnen**. Alternativ:

```bash
xattr -d com.apple.quarantine /Applications/BarBox.app
```

Eine Mac-App-Store-Fassung (Sandbox) ist in Vorbereitung; der GitHub-Build behält immer den vollen Funktionsumfang.

## Freigaben

Jede Freigabe wird erst beim ersten Gebrauch angefragt:

| Funktion | Freigabe |
|---|---|
| Bluetooth-Schalter | [blueutil](https://github.com/toy/blueutil) (`brew install blueutil`) + Bluetooth-Freigabe |
| Wetter | Ortung (oder Fallback-Ort in den Einstellungen) |
| Timer | Mitteilungen |
| Hell/Dunkel, Fokus | Automation (System Events / Kurzbefehle) |

**Update von Toolbox 1.x:** Version 2.0 hat eine neue Bundle-ID — macOS fragt die Freigaben darum einmalig neu an, und «Bei Anmeldung starten» muss neu gesetzt werden. Die App-Favoriten wandern automatisch mit.

## Privatsphäre

Keine Konten, kein Tracking, keine Analyse. Netzwerkverbindungen nur zu: `api.open-meteo.com` (Wetter), `api.frankfurter.dev` (Währungskurse), `data.snb.ch` (Schweizer Zinsen) und `api.ipify.org` (öffentliche IP, nur auf Klick). Der Speedtest nutzt Apples eingebautes `networkQuality`. Sonst verlässt nichts deinen Mac.

Ausführlich: [Datenschutzrichtlinie](PRIVACY.md) (englisch).

## Selbst bauen

Braucht nur die Xcode Command Line Tools (Swift 5.9+), kein Xcode-Projekt:

```bash
git clone https://github.com/ipstyle/barbox.git
cd barbox
./build.sh
open build/BarBox.app
```

## Lizenz

[GPL-3.0](LICENSE) · © 2026 ipstyle

Kopieren, Forken und Weiterverbreiten sind unter den GPL-3.0-Bedingungen ausdrücklich willkommen — bitte mit Namensnennung von **ipstyle/barbox**.
