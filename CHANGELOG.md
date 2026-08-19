# BarBox — Changelog / Änderungsprotokoll

## 2.1 — 19.08.2026

- **Fixed: the settings screen was cut off** the first time you opened it. The
  popover took its size from an animation still in progress and never corrected
  itself; you had to close and reopen to see the full width. Window size is now
  set explicitly, which also means the width and height sliders take effect
  immediately while the window is open. / **Behoben: Die Einstellungen waren
  beim ersten Öffnen abgeschnitten.** Das Fenster übernahm einen Zwischenwert
  einer laufenden Animation und korrigierte sich nie — man musste schliessen und
  neu öffnen. Die Fenstergrösse wird jetzt ausdrücklich gesetzt; damit wirken
  auch die Schieberegler sofort, während das Fenster offen ist.
- **Menu bar icon: several causes of it disappearing are fixed.** The item now
  has its own autosave name, is made visible again at every launch, and restores
  itself after a display change, waking from sleep or a user switch. If the icon
  is ever missing anyway, start BarBox again from Spotlight or the Dock — the
  running app puts it back and opens the window. **Honest limit:** when macOS
  hides the icon because the menu bar is full (many icons plus a notch), no app
  can override that; moving the icon closer to the clock helps. / **Menüleisten-
  Symbol: Mehrere Ursachen fürs Verschwinden sind behoben.** Das Symbol hat neu
  einen eigenen Speicherplatz, wird bei jedem Start wieder sichtbar gemacht und
  stellt sich nach Displaywechsel, Aufwachen oder Benutzerwechsel selbst wieder
  her. Fehlt es trotzdem einmal: BarBox einfach nochmals aus Spotlight oder dem
  Dock starten — die laufende App holt das Symbol zurück und öffnet das Fenster.
  **Ehrliche Grenze:** Blendet macOS das Symbol wegen voller Menüleiste aus
  (viele Symbole plus Notch), kann das keine App überstimmen; hilfreich ist, das
  Symbol näher zur Uhr zu schieben.
- **The window can now be up to 1500 px tall** (was 900), and the default for a
  fresh install is 900 (was 560). The height is capped to what the current
  screen actually fits, so a tall window does not run off a smaller display —
  a note under the slider says so when that happens. There is also a «reset to
  default» button now. Anyone who was still on the old default of 560 is moved
  to 900 once; a height you chose yourself is left alone. / **Das Fenster darf
  neu bis 1500 px hoch sein** (vorher 900), Vorgabe bei Neuinstallation ist 900
  (vorher 560). Die Höhe wird auf das begrenzt, was der aktuelle Bildschirm
  hergibt — ein Hinweis unter dem Regler sagt es, wenn das greift. Dazu gibt es
  neu «Auf Vorgabe zurücksetzen». Wer noch auf der alten Vorgabe 560 stand, wird
  einmalig auf 900 gehoben; eine selbst gewählte Höhe bleibt unangetastet.
- **New: update check.** BarBox asks the App Store once a day whether a newer
  version is out, and shows a small arrow in the header only if there really is
  one. Settings has a «check now» button and a switch to turn the automatic
  check off. This adds one host, `itunes.apple.com`, and nothing about you is
  sent — only the app's bundle identifier. / **Neu: Update-Prüfung.** BarBox
  fragt einmal täglich im App Store nach, ob eine neuere Fassung da ist, und
  zeigt nur dann einen kleinen Pfeil im Kopfbereich, wenn es wirklich eine gibt.
  In den Einstellungen gibt es «Jetzt prüfen» und einen Schalter, um die
  automatische Prüfung abzuschalten. Dazu kommt ein Server hinzu,
  `itunes.apple.com`; gesendet wird nichts über dich, nur die Kennung der App.
- Corrected in the privacy notes: BarBox has always contacted
  `geocoding-api.open-meteo.com` when you look up a fallback place in the
  settings, but every document said «exactly four hosts». The list now names all
  six — in the app, the README, the privacy policy and on the website. / In den
  Datenschutzangaben richtiggestellt: BarBox kontaktiert seit jeher
  `geocoding-api.open-meteo.com`, wenn man in den Einstellungen einen Ort sucht
  — überall stand aber «genau vier Server». Die Liste nennt jetzt alle sechs, in
  der App, im README, in der Datenschutzerklärung und auf der Website.
- Two icon problems found while testing 2.1 and fixed before release: the menu
  bar symbol drew nothing at all (the image was rendered lazily and never
  reached the button), and switching on «keep awake» made it vanish completely
  (tinting a template image). The active state now uses its own blue image. /
  Zwei Symbol-Fehler, beim Testen von 2.1 gefunden und vor der Veröffentlichung
  behoben: Das Menüleisten-Symbol zeichnete gar nichts (das Bild wurde verzögert
  erzeugt und kam nie am Knopf an), und beim Einschalten von «Wach halten»
  verschwand es ganz (Einfärben eines Template-Bildes). Der aktive Zustand hat
  jetzt ein eigenes blaues Bild.
- The website has a new **«What's new»** section, so you can see what changed
  before downloading. / Die Website hat neu einen Abschnitt **«Was ist neu»** —
  damit man vor dem Laden sieht, was sich geändert hat.

## 2.0 — 16.08.2026

- **Rebranded to BarBox** (formerly Toolbox/AF-Toolbox). New app icon ("bar over
  box") and matching monochrome menu bar symbol. The bundle identifier changed to
  `com.ip-style.barbox`, so macOS treats 2.0 as a new app: existing users are
  asked once again for the Location, Bluetooth and Automation permissions, and
  Login-at-startup must be re-enabled. App favorites migrate automatically. /
  **Umbenannt in BarBox** (vorher Toolbox/AF-Toolbox). Neues App-Icon («Balken
  über Box») und passendes Menüleisten-Symbol. Die Bundle-ID ist neu
  `com.ip-style.barbox` — macOS behandelt 2.0 darum wie eine neue App: Freigaben
  (Ort, Bluetooth, Automation) werden einmalig neu angefragt, «Bei Anmeldung
  starten» muss neu gesetzt werden. App-Favoriten wandern automatisch mit.
- **English is now the default language.** German remains fully available via
  Settings → Sprache/Language; an already saved language choice is kept. /
  **Englisch ist neu die Standardsprache.** Deutsch bleibt in den Einstellungen
  wählbar; eine bereits gespeicherte Sprachwahl bleibt erhalten.
- **Desktop switching removed** from all builds — it required the Accessibility
  permission and Mission-Control shortcuts and never worked reliably. /
  **Desktop-Wechsel entfernt** (alle Varianten) — er brauchte die
  Bedienungshilfen-Freigabe samt Mission-Control-Kurzbefehlen und lief nie
  zuverlässig.
- CPU / MEM / GPU indicators in the header now carry visible labels next to the
  icons. / Die CPU-/MEM-/GPU-Anzeigen im Kopfbereich tragen neu sichtbare
  Beschriftungen neben den Symbolen.
- The merged-PDF filename follows the app language (Merged.pdf / 
  Zusammengefuegt.pdf), and the SARON/SNB month labels are localized. / Der
  Dateiname beim PDF-Zusammenfügen folgt neu der App-Sprache, die
  SARON/SNB-Monatsnamen sind übersetzt.

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
  Version/Build, Security-Vermerk
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
