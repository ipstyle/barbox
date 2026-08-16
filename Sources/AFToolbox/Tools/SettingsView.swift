import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var status: SystemStatusModel
    @EnvironmentObject private var lang: LanguageStore

    @AppStorage("aiEdge") private var aiEdge = 1568
    @AppStorage("aiQuality") private var aiQuality = 0.80
    @AppStorage("halfQuality") private var halfQuality = 0.85
    @AppStorage("outputSuffix") private var outputSuffix = "-klein"
    @AppStorage("hiddenSettingsPanes") private var hiddenPanes = ""
    @AppStorage("dndShortcutName") private var dndShortcutName = ""
    @AppStorage("windowWidth") private var windowWidth = 360.0
    @AppStorage("windowHeight") private var windowHeight = 560.0
    @AppStorage("weatherPlace") private var weatherPlace = ""
    @State private var geocodeStatus: String?

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)
                    Text(lang.t("BarBox  « Alles zur Hand »"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(lang.t("Es Wärchzüg hät mer eifach …"))
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(.secondary)
                    Text(lang.t("Version") + " \(AppInfo.version) (Build \(AppInfo.build))")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                    Button("github.com/ipstyle/barbox") { openSystemURL("https://github.com/ipstyle/barbox") }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.blue)

                    Divider().padding(.vertical, 6)

                    Text(lang.t("Bündelt Alltags-Werkzeuge für den Mac in der Menüleiste: Apps, Bilder, Backups, System und Finanzen."))
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        #if MAS_BUILD
                        aboutBlock(lang.t("Verbindungen"),
                                   lang.t("Nur zu api.frankfurter.dev (Währungskurse), data.snb.ch (SARON und SNB-Leitzins), open-meteo.com (Wetter) sowie api.ipify.org (öffentliche IP, nur auf Klick). Sonst keine Verbindungen — Inhalte werden nie übertragen."))
                        #else
                        aboutBlock(lang.t("Verbindungen"),
                                   lang.t("Nur zu api.frankfurter.dev (Währungskurse), data.snb.ch (SARON und SNB-Leitzins) sowie api.ipify.org (öffentliche IP, nur auf Klick). Der Speedtest nutzt Apples eingebautes networkQuality. Sonst keine Verbindungen — Inhalte werden nie übertragen."))
                        #endif
                        aboutBlock(lang.t("Lokal gelesen"),
                                   lang.t("Die App-Ordner (/Applications, ~/Applications) für die App-Liste — nur lesend. Bilder und PDFs nur, wenn du sie selbst hineinziehst."))
                        aboutBlock(lang.t("Gespeichert"),
                                   lang.t("Einstellungen in den macOS-Vorgaben, App-Favoriten unter ~/Library/Application Support/BarBox. Keine Zugangsdaten, keine Inhalte. Der Zwischenablage-Verlauf bleibt nur im Arbeitsspeicher und verschwindet beim Beenden."))
                        #if MAS_BUILD
                        aboutBlock(lang.t("Freigaben"),
                                   lang.t("Mitteilungen (Timer), Automation (Hell/Dunkel, Fokus), Ort (Wetter), Ordner-Freigaben beim Speichern. Jede Freigabe wird erst beim ersten Gebrauch angefragt."))
                        #else
                        aboutBlock(lang.t("Freigaben"),
                                   lang.t("Bluetooth (Schalter via blueutil), Mitteilungen (Timer), Automation (Hell/Dunkel-Umschalter). Jede Freigabe wird erst beim ersten Gebrauch angefragt."))
                        #endif
                    }
                    .padding(.top, 6)

                    Divider().padding(.vertical, 6)

                    Label(lang.t("Sicherheit geprüft · Code-Review mit Claude Fable 5"), systemImage: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.green)
                    Text(lang.t("Durchgang am 10. August 2026 (1.2) — Fokus: Shell-Aufrufe, API-Nutzung, Freigaben, Parsing."))
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Text("© 2026 ipstyle")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }

            Section(lang.t("Allgemein")) {
                Picker("Sprache / Language", selection: $lang.code) {
                    Text("Deutsch").tag("de")
                    Text("English").tag("en")
                }
                Toggle(lang.t("Bei Anmeldung starten"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                if let loginError {
                    Text(loginError)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
                TextField(lang.t("Fokus-Kurzbefehl (Kurzbefehle-App)"), text: $dndShortcutName,
                          prompt: Text(lang.code == "en" ? "Do Not Disturb" : "Nicht stören"))
                Text(lang.t("Für den Fokus-Knopf einmal in der Kurzbefehle-App einen Kurzbefehl mit diesem Namen anlegen, der «Nicht stören» umschaltet."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Section(lang.t("Fenster")) {
                Slider(value: $windowWidth, in: 360...520, step: 20) {
                    Text(lang.t("Breite: ") + "\(Int(windowWidth)) px")
                }
                Slider(value: $windowHeight, in: 480...900, step: 20) {
                    Text(lang.t("Höhe: ") + "\(Int(windowHeight)) px")
                }
                Text(lang.t("Die Höhe lässt sich auch direkt am Griff unten in der Fusszeile ziehen. Das Fenster bleibt offen, bis du erneut aufs Menüleisten-Symbol klickst."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Section(lang.t("Wetter")) {
                TextField(lang.t("Fallback-Ort (wenn Ortung aus)"), text: $weatherPlace)
                HStack {
                    Button(lang.t("Ort suchen & übernehmen")) {
                        geocodeStatus = "…"
                        Task {
                            if let result = await WeatherModel.geocode(weatherPlace) {
                                weatherPlace = result.name
                                UserDefaults.standard.set(result.lat, forKey: "weatherLat")
                                UserDefaults.standard.set(result.lon, forKey: "weatherLon")
                                geocodeStatus = "✓ \(result.name)" + lang.t(" übernommen")
                            } else {
                                geocodeStatus = lang.t("Ort nicht gefunden")
                            }
                        }
                    }
                    .disabled(weatherPlace.trimmingCharacters(in: .whitespaces).isEmpty)
                    if let geocodeStatus {
                        Text(geocodeStatus)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(lang.t("Standard ist dein aktueller Standort (Ortungs-Freigabe beim ersten Öffnen der Wetter-Sektion). Der Fallback-Ort greift, wenn die Ortung aus ist."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Section(lang.t("Bilder komprimieren")) {
                Stepper(lang.t("AI: längste Kante ") + "\(aiEdge) px", value: $aiEdge, in: 256...8192, step: 64)
                Slider(value: $aiQuality, in: 0.3...1.0, step: 0.05) {
                    Text(lang.t("AI-Qualität: ") + "\(Int((aiQuality * 100).rounded())) %")
                }
                Slider(value: $halfQuality, in: 0.3...1.0, step: 0.05) {
                    Text(lang.t("«Halb so gross»-Qualität: ") + "\(Int((halfQuality * 100).rounded())) %")
                }
                TextField(lang.t("Datei-Endung"), text: $outputSuffix)
            }

            Section(lang.t("Meine Apps")) {
                if favorites.apps.isEmpty {
                    Text(lang.t("Noch keine Favoriten — Apps im Dashboard hineinziehen oder hier hinzufügen."))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                List {
                    ForEach(favorites.apps) { app in
                        HStack(spacing: 8) {
                            AppIconView(path: app.path, size: 18)
                            Text(app.name).font(.system(size: 12))
                            Spacer()
                            Button {
                                favorites.remove(app)
                            } label: {
                                Image(systemName: "minus.circle").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { source, destination in
                        favorites.move(from: source, to: destination)
                    }
                }
                .frame(height: favorites.apps.isEmpty ? 0 : min(CGFloat(favorites.apps.count) * 28 + 10, 150))
                Button(lang.t("App hinzufügen…")) { addAppViaPanel() }
            }

            Section(lang.t("Systemeinstellungs-Verknüpfungen")) {
                ForEach(SettingsPane.all) { pane in
                    Toggle(lang.t(pane.title), isOn: paneBinding(pane.id))
                }
            }

            #if !MAS_BUILD
            Section(lang.t("Status")) {
                LabeledContent(lang.t("blueutil (Bluetooth-Schalter)")) {
                    if let path = status.blueutilPath {
                        Text(path).font(.system(size: 10)).foregroundStyle(.secondary)
                    } else {
                        Text(lang.t("nicht installiert")).foregroundStyle(Theme.orange)
                    }
                }
                if status.blueutilPath == nil {
                    Button(copied ? lang.t("Kopiert ✓") : lang.t("Befehl kopieren: brew install blueutil")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install blueutil", forType: .string)
                        copied = true
                    }
                    Text(lang.t("Befehl im Terminal ausführen, danach BarBox neu starten."))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            #endif
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(lang.t("Einstellungen"))
    }

    private func aboutBlock(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paneBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { !hiddenPanes.split(separator: ",").map(String.init).contains(id) },
            set: { visible in
                var hidden = Set(hiddenPanes.split(separator: ",").map(String.init))
                if visible { hidden.remove(id) } else { hidden.insert(id) }
                hiddenPanes = hidden.sorted().joined(separator: ",")
            }
        )
    }

    private func addAppViaPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = lang.t("Hinzufügen")
        NSApplication.shared.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK {
            for url in panel.urls {
                favorites.add(url: url)
            }
        }
    }
}
