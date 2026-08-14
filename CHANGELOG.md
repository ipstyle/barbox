# Toolbox — Änderungsprotokoll / Changelog

## 1.8 — 14.08.2026

- Absturz behoben: Der englische Wortschatz enthielt den Schlüssel «Gespeichert»
  zweimal. Swift bricht bei doppelten Schlüsseln in einem Dictionary-Literal zur
  Laufzeit ab — die App stürzte beim Umschalten auf Englisch ab und startete
  danach gar nicht mehr, weil die Sprachwahl gespeichert bleibt. Deutsch war nie
  betroffen. / Fixed a crash: the English dictionary had a duplicate key, which
  traps at runtime in Swift. The app crashed when switching to English and failed
  to launch afterwards, since the language choice is persisted. German was never
  affected.
- PDF zusammenfügen: Die Erfolgsmeldung war zur Hälfte hartcodiert deutsch
  («Seiten») und ist jetzt vollständig übersetzt. / The success message in the PDF
  merge tool is now fully translated instead of partly hardcoded German.

## 1.7 — 10.08.2026

- App zweisprachig: Deutsch und Englisch, umschaltbar in den Einstellungen
  (Sprache / Language), wirkt sofort / App is now bilingual (German/English),
  switchable in settings
- Privatsphäre: keine persönlichen Daten mehr in App und Binary; About verweist
  auf github.com/ipstyle/toolbox
- Erstveröffentlichung auf GitHub (GPL-3.0)


Versionierung: `VERSION`-Datei ist die einzige Quelle. `./release.sh` baut und legt den
fertigen Build unter `Releases/<version>/AF-Toolbox.app` ab. Für eine neue Version:
`VERSION` hochzählen, Eintrag hier ergänzen, `./release.sh` ausführen.

## 1.6.1 — 10.08.2026

- Fix Absturz beim Ziehen aus den Favoriten: Zielindex konnte über das
  Listenende hinauslaufen (Drop über dem Bereichs-Hintergrund)
- Bundle heisst neu Toolbox.app (Anzeigename «Toolbox»); Bundle-ID unverändert

## 1.6 — 10.08.2026

- Neue Wetter-Sektion (verschiebbar wie alle Sektionen): aktuelles Wetter am
  Standort + 5-Tage-Vorhersage (Symbol, max/min, Regen-%), Knöpfe für die
  Apple-Wetter-App und MeteoSchweiz. Daten: Open-Meteo mit MeteoSchweiz-Modell
  (ICON-CH), Standort via Ortungsdienst, Fallback-Ort in den Einstellungen,
  letzter Stand wird gecacht
- «Wach halten» aktiv: Menüleisten-Symbol bleibt unverändert, der Text wird blau
- Namen: Widget-Titel «Toolbox», Menüleiste «T-Box»

## 1.5.1 — 10.08.2026

- Fix Batterie-Chip: Text wurde umgebrochen — Chip-Zeile jetzt horizontal
  scrollbar, Chips behalten ihre natürliche Breite
- Schnellaktionen (Hell/Dunkel, Aktivität, Fokus) in die Werkzeuge verschoben
- Sektion umbenannt in «System Settings» mit Einstellungen, System, App-Liste
- Widget-Titel «W-Cockpit», Menüleiste «CP»

## 1.5 — 10.08.2026

- Fix: Unteransichten überlagerten den Dashboard-Kopf (fehlender deckender Hintergrund)
- Ganze Sektionen (Favoriten, Regler, Schnellaktionen, Werkzeuge, Meine Apps)
  per Griff oben rechts verschiebbar — Reihenfolge wird gespeichert
- Alle Kacheln einheitlich klein (Grösse der Schnellaktionen), Raster 4-spaltig
- AirDrop als Chip neben Bluetooth mit Dropdown (Fenster öffnen, Empfang
  Alle/Kontakte/Aus, zeigt aktuellen Modus); Schnellaktion entfernt
- Fokus-Knopf: fehlt der Kurzbefehl, erklärt ein Dialog die Einrichtung
  und öffnet auf Wunsch die Kurzbefehle-App

## 1.4.1 — 10.08.2026

- Fix: Zurück-Navigation aus allen Unteransichten — der Popover-Unterbau zeigt
  die System-Navigationsleiste nicht; jede Unteransicht hat jetzt eine eigene
  Kopfzeile mit «‹ Zurück»-Knopf und Titel

## 1.4 — 10.08.2026

- Fenster bleibt offen, bis erneut aufs Menüleisten-Symbol geklickt wird
  (Unterbau von MenuBarExtra auf StatusItem + NSPopover umgestellt)
- Fenstergrösse einstellbar: Breite/Höhe in den Einstellungen, Höhe zusätzlich
  per Zieh-Griff in der Fusszeile
- Neuer Favoriten-Bereich über den Sektionen: Werkzeuge UND Schnellaktionen
  per Drag & Drop hineinziehen, sortieren, per Rechtsklick entfernen
- Schnellaktionen und Werkzeuge einklappbar (Zustand wird gespeichert),
  Schnellaktionen ebenfalls sortierbar
- WLAN/Bluetooth-Chips als Dropdown (Ein/Aus/Einstellungen) statt Direkt-Toggle
- Widget-Titel: «AF-Toolbox»
- Umbenennen mit definierbarem Muster: {name}, {nr}, {datum} + Live-Vorschau
- Passwort-Generator: a–z, A–Z, 0–9, $! einzeln wählbar (alle an), Standard 25 Zeichen
- Speedtest behält die letzten 5 Ergebnisse mit Zeitstempel
- Info-Bereich im Stil der «Never get OoT!»-App: Slang-Untertitel, Kontakt,
  Transparenz-Abschnitte (Verbindungen/Lokal/Gespeichert/Freigaben), Security-Vermerk

## 1.3.1 — 10.08.2026

- Menüleiste wieder kompakt: nur Drehschlüssel + «AF-T»
- CPU/RAM/GPU-Werte mit Symbolen zentriert im Widget-Titel (mit Abstand, Warnfarbe ab 85 %)
- Drag & Drop der Kacheln/Favoriten repariert (Buttons schluckten den Drag —
  Umstellung auf Tap-Gesten)
- Copyright «© 2026 ipstyle» in Info-Bereich und Bundle

## 1.3 — 10.08.2026

- Menüleiste zeigt CPU/GPU/RAM-Auslastung neben «AF-T» (abschaltbar in den Einstellungen)
- Neue Regler im Dashboard: Display-Helligkeit, Lautstärke, Audio-Ausgabegerät
- Schnellaktionen: Hell/Dunkel-Umschalter, AirDrop (öffnen + Empfangsmodus),
  Aktivitätsanzeige, Fokus «Nicht stören» (via Kurzbefehl)
- Neue Werkzeuge: Text aus Bild (OCR, offline), PDF zusammenfügen, QR-Code-Generator,
  Batch-Umbenennen, Zwischenablage-Verlauf (letzte 20), Timer mit Mitteilung,
  Passwort/UUID-Generator, Netzwerk & Info (IPs, Speedtest, Systeminfo),
  Finanzen (CHF→EUR/USD-Rechner mit EZB-Kursen, SARON + SNB-Leitzins)
- Werkzeug-Kacheln und App-Favoriten per Drag & Drop sortierbar (Reihenfolge gespeichert)
- Bilder: Preset «Halb so gross» (50 %) ersetzt WhatsApp

## 1.2.2 — 10.08.2026

- Lesbarkeit: leuchtende Statusfarben (Grün/Blau/Indigo/Orange) statt dunkler
  Systemtöne — Chips und Warnhinweise auf Anthrazit klar erkennbar

## 1.2.1 — 10.08.2026

- Design-Fix: MenuBarExtra übernimmt preferredColorScheme nicht — Dunkelmodus wird
  jetzt direkt in der View-Umgebung erzwungen (Text/Icons waren im System-Hellmodus
  schwarz auf Anthrazit)
- Kontrast erhöht: hellere Karten (10 % Weiss), feine Ränder um Kacheln und Chips,
  hellerer Akzentton

## 1.2 — 10.08.2026

- Anzeige des aktuellen Desktops: aktiver Desktop blau markiert, Knopf-Anzahl folgt
  automatisch der echten Desktop-Zahl (SkyLight-API, Fallback: Einstellung)
- Desktop-Zeile zuoberst im Menü (kürzere Mauswege)
- Anthrazit-Design für die ganze App, zentral in Theme.swift (Vorlage für weitere Apps)
- Einstellungen in grösserem Fenster (500×660) mit Info-Bereich: Icon, Slogan,
  Version/Build, Security-Vermerk (Claude Fable 5)
- Review-Fixes: tmutil-Statusprüfung, robusteres Popover-Schliessen,
  Hauptbildschirm-Präferenz bei mehreren Displays, App-Listen-Zeilen entflochten
- build.sh nutzt stabile Signatur-Identität «AF-Toolbox Dev», falls vorhanden
  (verhindert Freigabe-Verlust bei Updates)

## 1.1 — 10.08.2026

- Desktop-Wechsel per Klick ohne manuelle Systemeinstellung: neuer Knopf
  «Klick-Wechsel einrichten» (Dashboard und Einstellungen) aktiviert die
  Mission-Control-Kurzbefehle Ctrl+1…n automatisch — Tasten drücken muss man nie.
- Bluetooth-Nutzungstext im Info.plist ergänzt (sauberer Freigabe-Dialog)

## 1.0 — 10.08.2026

Erste Version.

- Menüleisten-App «AF-T» (Drehschlüssel), Kachel-Dashboard im Parallels-Stil
- Status-Chips: Batterie, WLAN-Toggle, Bluetooth-Toggle (via blueutil)
- App-Favoriten per Drag & Drop, durchsuchbare App-Liste
- Wach halten (unbegrenzt / 30 min / 1 h / 2 h)
- Bilder komprimieren: Presets AI (1568 px, Q80) und WhatsApp (1600 px, Q75)
- Time Machine: Status, letztes Backup, Backup starten, Einstellungen öffnen
- Deep-Links in 12 Bereiche der Systemeinstellungen (abwählbar)
- Desktop-Wechsel (Ctrl+1…9 / Ctrl+Pfeil, Bedienungshilfen-Freigabe)
- Einstellungen: Login-Start, Presets, Favoriten- und Verknüpfungs-Verwaltung
