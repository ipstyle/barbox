import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

#if MAS_BUILD
/// Store-Variante: Tastatur-Injektion (CGEvent) und Bedienungshilfen sind in der
/// Sandbox nicht verfügbar — der Desktop-Wechsel existiert dort nicht. Stub, damit
/// die restliche UI kompiliert; alle Aufrufstellen sind unter MAS_BUILD ausgeblendet.
enum DesktopSwitcher {
    static var isTrusted: Bool { false }
    static func requestPermission() {}
    static func openAccessibilitySettings() {}
    static func switchTo(_ number: Int) {}
    static func previous() {}
    static func next() {}
    static func hotkeysEnabled(count: Int) -> Bool { false }
    static func enableHotkeys(count: Int) {}
}
#else
enum DesktopSwitcher {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        openSystemURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    // Keycodes der Zahlenreihe 1–9 (ANSI)
    private static let digitKeys: [CGKeyCode] = [18, 19, 20, 21, 23, 22, 26, 28, 25]

    static func switchTo(_ number: Int) {
        guard (1...9).contains(number) else { return }
        postCtrl(key: digitKeys[number - 1])
    }

    static func previous() { postCtrl(key: 123) }
    static func next() { postCtrl(key: 124) }

    private static func postCtrl(key: CGKeyCode) {
        post(key: key, flags: .maskControl)
    }

    /// Simulierter Tastendruck mit Modifiern (braucht Bedienungshilfen-Freigabe)
    static func post(key: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    // MARK: - Mission-Control-Kurzbefehle (Ctrl+1…9)
    // macOS lässt den Direktwechsel nur über diese Kurzbefehle zu. Sie sind ab Werk
    // deaktiviert; die App kann sie auf Wunsch selbst aktivieren, damit der
    // Klick-Wechsel funktioniert, ohne dass man je eine Taste drücken muss.

    private static let hotkeyBaseID = 118 // 118 = «Zu Schreibtisch 1 wechseln»
    private static let symbolicHotkeysDomain = "com.apple.symbolichotkeys" as CFString

    static func hotkeysEnabled(count: Int) -> Bool {
        guard let dict = CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, symbolicHotkeysDomain) as? [String: Any] else {
            return false
        }
        for index in 0..<min(max(count, 1), 9) {
            guard let entry = dict[String(hotkeyBaseID + index)] as? [String: Any],
                  (entry["enabled"] as? NSNumber)?.boolValue == true else {
                return false
            }
        }
        return true
    }

    static func enableHotkeys(count: Int) {
        var dict = (CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, symbolicHotkeysDomain) as? [String: Any]) ?? [:]
        for index in 0..<min(max(count, 1), 9) {
            dict[String(hotkeyBaseID + index)] = [
                "enabled": true,
                "value": [
                    "parameters": [65535, Int(digitKeys[index]), 262144], // 262144 = Ctrl
                    "type": "standard",
                ],
            ]
        }
        CFPreferencesSetAppValue("AppleSymbolicHotKeys" as CFString, dict as CFDictionary, symbolicHotkeysDomain)
        CFPreferencesAppSynchronize(symbolicHotkeysDomain)

        let activate = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
        if FileManager.default.isExecutableFile(atPath: activate) {
            Shell.run(activate, ["-u"])
        }
    }
}
#endif

func openSystemURL(_ string: String) {
    if let url = URL(string: string) {
        NSWorkspace.shared.open(url)
    }
}
