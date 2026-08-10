import AppKit
import SwiftUI

struct SettingsPane: Identifiable {
    let id: String
    let title: String
    let icon: String
    let url: String

    static let all: [SettingsPane] = [
        SettingsPane(id: "general", title: "Allgemein", icon: "gear",
                     url: "x-apple.systempreferences:com.apple.systempreferences.GeneralSettings"),
        SettingsPane(id: "wifi", title: "WLAN", icon: "wifi",
                     url: "x-apple.systempreferences:com.apple.wifi-settings-extension"),
        SettingsPane(id: "bluetooth", title: "Bluetooth", icon: "dot.radiowaves.left.and.right",
                     url: "x-apple.systempreferences:com.apple.BluetoothSettings"),
        SettingsPane(id: "network", title: "Netzwerk", icon: "network",
                     url: "x-apple.systempreferences:com.apple.Network-Settings.extension"),
        SettingsPane(id: "battery", title: "Batterie", icon: "battery.75percent",
                     url: "x-apple.systempreferences:com.apple.Battery-Settings.extension"),
        SettingsPane(id: "displays", title: "Displays", icon: "display",
                     url: "x-apple.systempreferences:com.apple.Displays-Settings.extension"),
        SettingsPane(id: "desktop", title: "Schreibtisch & Dock", icon: "dock.rectangle",
                     url: "x-apple.systempreferences:com.apple.Desktop-Settings.extension"),
        SettingsPane(id: "keyboard", title: "Tastatur", icon: "keyboard",
                     url: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"),
        SettingsPane(id: "privacy", title: "Datenschutz & Sicherheit", icon: "hand.raised",
                     url: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"),
        SettingsPane(id: "accessibility", title: "Bedienungshilfen", icon: "figure.stand",
                     url: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension"),
        SettingsPane(id: "timemachine", title: "Time Machine", icon: "clock.arrow.circlepath",
                     url: "x-apple.systempreferences:com.apple.Time-Machine-Settings.extension"),
        SettingsPane(id: "softwareupdate", title: "Softwareupdate", icon: "arrow.down.circle",
                     url: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension"),
    ]
}

struct SystemSettingsLinksView: View {
    @EnvironmentObject private var lang: LanguageStore
    @AppStorage("hiddenSettingsPanes") private var hiddenPanes = ""

    private var visible: [SettingsPane] {
        let hidden = Set(hiddenPanes.split(separator: ",").map(String.init))
        return SettingsPane.all.filter { !hidden.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    NSWorkspace.shared.openApplication(
                        at: URL(fileURLWithPath: "/System/Applications/System Settings.app"),
                        configuration: NSWorkspace.OpenConfiguration())
                    closePopoverWindow()
                } label: {
                    Label(lang.t("Systemeinstellungen öffnen"), systemImage: "gearshape.2")
                        .frame(maxWidth: .infinity)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(visible) { pane in
                        Button {
                            openSystemURL(pane.url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: pane.icon)
                                    .font(.system(size: 13))
                                    .frame(width: 18)
                                Text(lang.t(pane.title))
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(lang.t("Welche Verknüpfungen hier erscheinen, lässt sich in den Einstellungen festlegen."))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .navigationTitle(lang.t("Systemeinstellungen"))
    }
}
