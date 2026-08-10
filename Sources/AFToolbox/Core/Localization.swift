import Foundation
import SwiftUI

/// Zweisprachigkeit Deutsch/Englisch. Deutsch ist die Quellsprache und dient als
/// Schlüssel; fehlt eine Übersetzung, erscheint der deutsche Text (nie ein Key).
/// Umschalten wirkt sofort, da alle Views den LanguageStore beobachten.
@MainActor
final class LanguageStore: ObservableObject {
    @Published var code: String {
        didSet { UserDefaults.standard.set(code, forKey: "appLanguage") }
    }

    init() {
        code = UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
    }

    func t(_ german: String) -> String {
        code == "en" ? (L10n.english[german] ?? german) : german
    }

    /// Für Nicht-View-Code (Notifications, Alerts) ohne Store-Referenz
    nonisolated static func current(_ german: String) -> String {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
        return code == "en" ? (L10n.english[german] ?? german) : german
    }
}

enum L10n {
    static let english: [String: String] = [
        // Dashboard / Sektionen
        "Desktops": "Desktops",
        "· aktiv: ": "· active: ",
        "Favoriten": "Favorites",
        "Regler": "Controls",
        "System Settings": "System Settings",
        "Werkzeuge": "Tools",
        "Meine Apps": "My apps",
        "Wetter": "Weather",
        "Beenden": "Quit",
        "Zurück": "Back",
        "Freigabe nötig": "Permission needed",
        "Klick-Wechsel einrichten": "Set up click switching",
        "Noch leer — zieh dir Werkzeuge und Schnellaktionen hierher": "Still empty — drag your favorite tiles here",
        "Apps aus dem Finder hierhin ziehen": "Drag apps here from Finder",
        "Aus Favoriten entfernen": "Remove from favorites",
        "Zu Favoriten": "Add to favorites",
        "Im Finder zeigen": "Show in Finder",
        "Entfernen": "Remove",
        "Sektion verschieben": "Move section",
        "Ausgabegerät": "Output device",
        "App-Liste durchsuchen": "Search app list",
        "Einstellungen": "Settings",
        "Aktueller Desktop": "Current desktop",
        "Vorheriger Desktop": "Previous desktop",
        "Nächster Desktop": "Next desktop",
        "CPU-Auslastung": "CPU usage",
        "RAM belegt": "RAM used",
        "GPU-Auslastung": "GPU usage",
        "Ziehen, um das Fenster höher oder kürzer zu machen": "Drag to make the window taller or shorter",

        // Chips
        "WLAN": "Wi-Fi",
        "Bluetooth": "Bluetooth",
        "Einschalten": "Turn on",
        "Ausschalten": "Turn off",
        "WLAN-Einstellungen…": "Wi-Fi settings…",
        "Bluetooth-Einstellungen…": "Bluetooth settings…",
        "Schalten braucht blueutil (siehe Einstellungen)": "Switching requires blueutil (see settings)",
        "Batterie — Klick öffnet die Batterie-Einstellungen": "Battery — click opens Battery settings",
        "Fenster öffnen": "Open window",
        "Empfang: Alle": "Receiving: everyone",
        "Empfang: Nur Kontakte": "Receiving: contacts only",
        "Empfang: Aus": "Receiving: off",
        "AirDrop · Alle": "AirDrop · All",
        "AirDrop · Kontakte": "AirDrop · Contacts",
        "AirDrop · Aus": "AirDrop · Off",

        // Kacheln
        "Wach halten": "Keep awake",
        "Bilder": "Images",
        "Text aus Bild": "Text from image",
        "PDF": "PDF",
        "QR-Code": "QR code",
        "Umbenennen": "Rename",
        "Ablage": "Clipboard",
        "Timer": "Timer",
        "Passwörter": "Passwords",
        "Finanzen": "Finance",
        "Netzwerk": "Network",
        "Time Machine": "Time Machine",
        "System": "System",
        "App-Liste": "App list",
        "Hell/Dunkel": "Light/Dark",
        "Aktivität": "Activity",
        "Fokus": "Focus",
        "aktiv": "active",
        "bis ": "until ",
        "Unbegrenzt": "Unlimited",
        "30 Minuten": "30 minutes",
        "1 Stunde": "1 hour",
        "2 Stunden": "2 hours",

        // Wetter
        "Wetter wird geladen…": "Loading weather…",
        "Noch keine Wetterdaten": "No weather data yet",
        "Wetter laden": "Load weather",
        "Wetter-App": "Weather app",
        "MeteoSchweiz": "MeteoSwiss",
        "Stand ": "As of ",
        " · Fallback-Ort": " · fallback location",
        " · MeteoSchweiz-Modell via Open-Meteo": " · MeteoSwiss model via Open-Meteo",
        "Wind ": "Wind ",
        " · Feuchte ": " · humidity ",
        "Klar": "Clear",
        "Meist sonnig": "Mostly sunny",
        "Teils bewölkt": "Partly cloudy",
        "Bedeckt": "Overcast",
        "Nebel": "Fog",
        "Nieselregen": "Drizzle",
        "Regen": "Rain",
        "Schnee": "Snow",
        "Schauer": "Showers",
        "Gewitter": "Thunderstorm",
        "Bewölkt": "Cloudy",
        "Keine Ortung aktiv — Fallback-Ort in den Einstellungen setzen.": "Location off — set a fallback place in settings.",
        "Wetterdaten nicht lesbar": "Weather data unreadable",
        "Wetter nicht abrufbar (offline?)": "Weather unavailable (offline?)",
        "Standort": "Location",

        // Bilder
        "Für AI · ": "For AI · ",
        "Halb so gross · 50 %": "Half size · 50 %",
        "Bilder hierhin ziehen": "Drop images here",
        "JPEG, PNG, HEIC, TIFF …": "JPEG, PNG, HEIC, TIFF …",
        "Bilder auswählen…": "Choose images…",
        "Liste leeren": "Clear list",
        "Komprimieren": "Compress",
        "Bild konnte nicht gelesen werden": "Could not read image",
        "Verkleinern fehlgeschlagen": "Resizing failed",
        "Ausgabedatei konnte nicht angelegt werden": "Could not create output file",
        "Speichern fehlgeschlagen": "Saving failed",

        // OCR
        "Bild oder Screenshot hierhin ziehen": "Drop an image or screenshot here",
        "Text wird erkannt und automatisch kopiert (offline, Apple Vision)": "Text is recognized and copied automatically (offline, Apple Vision)",
        "Erkannter Text (bereits in der Zwischenablage)": "Recognized text (already on the clipboard)",
        "Nochmals kopieren": "Copy again",
        "Kopiert ✓": "Copied ✓",
        "Kein Text erkannt.": "No text recognized.",

        // PDF
        "PDFs hierhin ziehen — Reihenfolge unten anpassen": "Drop PDFs here — adjust the order below",
        "Zusammenfügen (%d PDFs)": "Merge (%d PDFs)",
        "Speichern fehlgeschlagen.": "Saving failed.",

        // QR
        "Text oder URL…": "Text or URL…",
        "Aus Zwischenablage": "From clipboard",
        "Bild kopieren": "Copy image",
        "Sichern…": "Save…",

        // Umbenennen
        "Dateien hierhin ziehen": "Drop files here",
        "Muster, z. B. {name}-{nr}": "Pattern, e.g. {name}-{nr}",
        "Platzhalter: {name} = Originalname · {nr} = Laufnummer · {datum} = Dateidatum (JJJJ-MM-TT). Endung bleibt erhalten.": "Placeholders: {name} = original name · {nr} = counter · {datum} = file date (YYYY-MM-DD). Extension is kept.",
        "Vorschau:": "Preview:",
        "Umbenennen (%d Dateien)": "Rename (%d files)",
        " umbenannt": " renamed",
        " übersprungen (Ziel existiert)": " skipped (target exists)",
        "Start: ": "Start: ",
        "Stellen: ": "Digits: ",

        // Zwischenablage
        "Zwischenablage": "Clipboard",
        "Noch nichts kopiert — der Verlauf sammelt ab jetzt die letzten 20 Text-Einträge.": "Nothing copied yet — the history keeps the last 20 text entries from now on.",
        "Klick kopiert den Eintrag wieder in die Zwischenablage": "Click copies the entry back to the clipboard",
        "Verlauf löschen": "Clear history",
        " Einträge": " entries",

        // Timer
        "Schnell-Timer mit Mitteilung am Ende": "Quick timer with a notification at the end",
        "Eigene Dauer: ": "Custom duration: ",
        "Start": "Start",
        "Abbrechen": "Cancel",
        "Timer abgelaufen": "Timer finished",
        " Minuten sind um.": " minutes are up.",

        // Passwörter
        "Länge: ": "Length: ",
        "Passwort erzeugen": "Generate password",
        "UUID erzeugen": "Generate UUID",
        "Kopieren": "Copy",
        "Wurde automatisch in die Zwischenablage kopiert.": "Was copied to the clipboard automatically.",
        "Mindestens eine Zeichenart wählen.": "Select at least one character set.",

        // Finanzen
        "Währungsrechner": "Currency converter",
        "Betrag": "Amount",
        "Zinsen (Hypotheken)": "Interest rates (mortgages)",
        "SARON (Monatsmittel)": "SARON (monthly mean)",
        "SNB-Leitzins": "SNB policy rate",
        "Vormonat: ": "Previous month: ",
        "Stand %@ · Quelle SNB": "As of %@ · source SNB",
        "Aktualisieren": "Refresh",
        "Kurse nicht abrufbar": "Rates unavailable",
        "SNB-Daten nicht abrufbar": "SNB data unavailable",
        "Kurse und SNB-Daten nicht abrufbar": "Rates and SNB data unavailable",
        "Noch keine Daten — «Aktualisieren» drücken.": "No data yet — press “Refresh”.",
        "EZB-Referenzkurse vom ": "ECB reference rates of ",
        "Kurs ": "Rate ",

        // Netzwerk & Info
        "Netzwerk & Info": "Network & info",
        "IP-Adressen": "IP addresses",
        "Kein Netzwerk verbunden": "No network connected",
        "Öffentlich": "Public",
        "Öffentliche IP abrufen": "Fetch public IP",
        "Internet-Speedtest": "Internet speed test",
        "Speedtest starten": "Start speed test",
        "Läuft… (~20 s)": "Running… (~20 s)",
        "Ergebnis nicht lesbar": "Result unreadable",
        "Test fehlgeschlagen": "Test failed",
        "Letzte Tests": "Recent tests",
        "Speicher frei": "Disk free",
        "Uptime": "Uptime",
        "CPU": "CPU",
        "GPU": "GPU",
        " von ": " of ",

        // Time Machine
        "Backup starten": "Start backup",
        "Öffnen": "Open",
        "Status wird gelesen…": "Reading status…",
        "Kein Backup aktiv": "No backup running",
        "Letztes Backup: ": "Last backup: ",
        "unbekannt": "unknown",
        "Backup läuft…": "Backup running…",
        "Backup läuft — ": "Backup running — ",
        "Kein Backup-Ziel eingerichtet — zuerst in den Time-Machine-Einstellungen ein Volume wählen.": "No backup destination configured — choose a volume in Time Machine settings first.",

        // System-Links
        "Systemeinstellungen": "System Settings",
        "Systemeinstellungen öffnen": "Open System Settings",
        "Allgemein": "General",
        "Netzwerk ": "Network ",
        "Batterie": "Battery",
        "Displays": "Displays",
        "Schreibtisch & Dock": "Desktop & Dock",
        "Tastatur": "Keyboard",
        "Datenschutz & Sicherheit": "Privacy & Security",
        "Bedienungshilfen": "Accessibility",
        "Softwareupdate": "Software Update",
        "Welche Verknüpfungen hier erscheinen, lässt sich in den Einstellungen festlegen.": "Which shortcuts appear here can be set in the settings.",

        // App-Liste
        "App suchen…": "Search apps…",
        " Apps": " apps",
        "In den Favoriten": "In favorites",
        "Zu «Meine Apps» hinzufügen": "Add to “My apps”",

        // Einstellungen
        "Sprache / Language": "Sprache / Language",
        "Bei Anmeldung starten": "Launch at login",
        "Fokus-Kurzbefehl (Kurzbefehle-App)": "Focus shortcut (Shortcuts app)",
        "Für den Fokus-Knopf einmal in der Kurzbefehle-App einen Kurzbefehl mit diesem Namen anlegen, der «Nicht stören» umschaltet.": "For the Focus button, create a shortcut with this name in the Shortcuts app that toggles Do Not Disturb.",
        "Fenster": "Window",
        "Breite: ": "Width: ",
        "Höhe: ": "Height: ",
        "Die Höhe lässt sich auch direkt am Griff unten in der Fusszeile ziehen. Das Fenster bleibt offen, bis du erneut aufs Menüleisten-Symbol klickst.": "The height can also be dragged at the grip in the footer. The window stays open until you click the menu bar icon again.",
        "Fallback-Ort (wenn Ortung aus)": "Fallback place (if location is off)",
        "Ort suchen & übernehmen": "Look up & apply place",
        "Ort nicht gefunden": "Place not found",
        " übernommen": " applied",
        "Standard ist dein aktueller Standort (Ortungs-Freigabe beim ersten Öffnen der Wetter-Sektion). Der Fallback-Ort greift, wenn die Ortung aus ist.": "Default is your current location (permission prompt on first use of the weather section). The fallback place is used when location is off.",
        "Desktop-Knöpfe (Fallback): ": "Desktop buttons (fallback): ",
        "Die Anzahl wird normalerweise automatisch aus deinen echten Desktops gelesen; dieser Wert greift nur, falls das fehlschlägt.": "The count is normally read from your actual desktops; this value is only used if that fails.",
        "Bedienungshilfen-Freigabe": "Accessibility permission",
        "erteilt": "granted",
        "Freigabe einrichten…": "Set up permission…",
        "Klick-Wechsel (Ctrl+1…9)": "Click switching (Ctrl+1…9)",
        "eingerichtet": "set up",
        "Jetzt einrichten": "Set up now",
        "Der Wechsel läuft intern über die Mission-Control-Kurzbefehle Ctrl+1…9. «Jetzt einrichten» aktiviert sie automatisch — drücken musst du sie nie.": "Switching uses the Mission Control shortcuts Ctrl+1…9 internally. “Set up now” enables them automatically — you never have to press them.",
        "Bilder komprimieren": "Compress images",
        "AI: längste Kante ": "AI: longest edge ",
        "AI-Qualität: ": "AI quality: ",
        "«Halb so gross»-Qualität: ": "“Half size” quality: ",
        "Datei-Endung": "File suffix",
        "Noch keine Favoriten — Apps im Dashboard hineinziehen oder hier hinzufügen.": "No favorites yet — drag apps onto the dashboard or add them here.",
        "App hinzufügen…": "Add app…",
        "Hinzufügen": "Add",
        "Systemeinstellungs-Verknüpfungen": "System Settings shortcuts",
        "Status": "Status",
        "blueutil (Bluetooth-Schalter)": "blueutil (Bluetooth switch)",
        "nicht installiert": "not installed",
        "Befehl kopieren: brew install blueutil": "Copy command: brew install blueutil",
        "Befehl im Terminal ausführen, danach AF-Toolbox neu starten.": "Run the command in Terminal, then restart the app.",
        "Version": "Version",

        // About
        "Es Wärchzüg hät mer eifach …": "A proper tool is simply a must …",
        "Bündelt Alltags-Werkzeuge für den Mac in der Menüleiste: Desktops, Apps, Bilder, Backups, System und Finanzen.": "Bundles everyday Mac tools in the menu bar: desktops, apps, images, backups, system and finance.",
        "Verbindungen": "Connections",
        "Nur zu api.frankfurter.dev (Währungskurse), data.snb.ch (SARON und SNB-Leitzins) sowie api.ipify.org (öffentliche IP, nur auf Klick). Der Speedtest nutzt Apples eingebautes networkQuality. Sonst keine Verbindungen — Inhalte werden nie übertragen.": "Only to api.frankfurter.dev (currency rates), data.snb.ch (SARON and SNB policy rate), open-meteo.com (weather) and api.ipify.org (public IP, on click only). The speed test uses Apple's built-in networkQuality. No other connections — content is never transmitted.",
        "Lokal gelesen": "Read locally",
        "Die App-Ordner (/Applications, ~/Applications) für die App-Liste — nur lesend. Bilder und PDFs nur, wenn du sie selbst hineinziehst.": "The app folders (/Applications, ~/Applications) for the app list — read-only. Images and PDFs only when you drop them yourself.",
        "Gespeichert": "Stored",
        "Einstellungen in den macOS-Vorgaben, App-Favoriten unter ~/Library/Application Support/AF-Toolbox. Keine Zugangsdaten, keine Inhalte. Der Zwischenablage-Verlauf bleibt nur im Arbeitsspeicher und verschwindet beim Beenden.": "Settings in macOS defaults, app favorites under ~/Library/Application Support/AF-Toolbox. No credentials, no content. The clipboard history stays in memory only and disappears on quit.",
        "Freigaben": "Permissions",
        "Bedienungshilfen (Desktop-Wechsel), Bluetooth (Schalter via blueutil), Mitteilungen (Timer), Automation (Hell/Dunkel-Umschalter). Jede Freigabe wird erst beim ersten Gebrauch angefragt.": "Accessibility (desktop switching), Bluetooth (switch via blueutil), notifications (timer), automation (light/dark toggle), location (weather). Each permission is requested on first use only.",
        "Sicherheit geprüft · Code-Review mit Claude Fable 5": "Security checked · code review with Claude Fable 5",
        "Durchgang am 10. August 2026 (1.2) — Fokus: Shell-Aufrufe, API-Nutzung, Freigaben, Parsing.": "Pass on August 10, 2026 (1.2) — focus: shell calls, API usage, permissions, parsing.",

        // Nachträge aus der Umstellung
        "Zum Wechseln braucht AF-Toolbox die Bedienungshilfen-Freigabe — Klick öffnet die Einstellung": "Switching desktops needs the Accessibility permission — click opens the setting",
        "Aktiviert einmalig die macOS-Kurzbefehle Ctrl+1…9, über die der Klick-Wechsel läuft — du musst sie nie selbst drücken": "Enables the macOS shortcuts Ctrl+1…9 once — click switching uses them internally, you never press them yourself",
        "Zu Desktop ": "Switch to desktop ",
        " wechseln": "",
        "Ausgabe: gleicher Ordner, Endung «%@.jpg». Presets in den Einstellungen anpassbar.": "Output: same folder, suffix “%@.jpg”. Presets adjustable in settings.",
        "Toolbox  « Alles zur Hand »": "Toolbox  « Everything at hand »",
        "PDF zusammenfügen": "Merge PDFs",
        "«%@» konnte nicht gelesen werden.": "Could not read “%@”.",
        "… und %d weitere": "… and %d more",
        "Gespeichert": "Saved",

        // Fokus-Dialog
        "Kurzbefehl «%@» nicht gefunden": "Shortcut “%@” not found",
        "Lege in der Kurzbefehle-App einen Kurzbefehl mit genau diesem Namen an, der den Fokus «Nicht stören» umschaltet (Aktion «Fokus festlegen»). Der Name lässt sich in den AF-Toolbox-Einstellungen ändern.": "Create a shortcut with exactly this name in the Shortcuts app that toggles the Do Not Disturb focus (action “Set Focus”). The name can be changed in the app settings.",
        "Kurzbefehle öffnen": "Open Shortcuts",
        "OK": "OK",
    ]
}
