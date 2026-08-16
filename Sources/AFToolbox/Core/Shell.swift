import AppKit
import Foundation

enum Shell {
    @discardableResult
    static func run(_ launchPath: String, _ args: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return (-1, error.localizedDescription)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    static func runAsync(_ launchPath: String, _ args: [String]) async -> (status: Int32, output: String) {
        await Task.detached { run(launchPath, args) }.value
    }

    #if !MAS_BUILD
    /// Simulierter Tastendruck mit Modifiern (braucht Bedienungshilfen-Freigabe)
    static func postKeyEvent(key: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
    #endif
}

func openSystemURL(_ string: String) {
    if let url = URL(string: string) {
        NSWorkspace.shared.open(url)
    }
}
