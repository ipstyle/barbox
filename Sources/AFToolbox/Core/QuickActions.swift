import AppKit
import Foundation

enum QuickActions {
    static func toggleDarkMode() {
        Task {
            _ = await Shell.runAsync("/usr/bin/osascript", [
                "-e", "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode",
            ])
        }
    }

    static func openActivityMonitor() {
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"),
            configuration: NSWorkspace.OpenConfiguration())
    }

    /// Öffnet das AirDrop-Fenster im Finder (Cmd+Shift+R, braucht Bedienungshilfen-Freigabe)
    static func openAirDrop() {
        Task {
            _ = await Shell.runAsync("/usr/bin/osascript", ["-e", "tell application \"Finder\" to activate"])
            try? await Task.sleep(nanoseconds: 400_000_000)
            DesktopSwitcher.post(key: 15, flags: [.maskCommand, .maskShift]) // R
        }
    }

    /// AirDrop-Empfang: "Off", "Contacts Only" oder "Everyone"
    static func setAirDropMode(_ mode: String) {
        Task {
            _ = await Shell.runAsync("/usr/bin/defaults", ["write", "com.apple.sharingd", "DiscoverableMode", "-string", mode])
            _ = await Shell.runAsync("/usr/bin/killall", ["sharingd"])
        }
    }

    /// Führt einen Kurzbefehl aus der Kurzbefehle-App aus (z. B. für «Nicht stören»)
    static func runShortcut(_ name: String) async -> Bool {
        let result = await Shell.runAsync("/usr/bin/shortcuts", ["run", name])
        return result.status == 0
    }
}
