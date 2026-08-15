import AppKit
import Foundation

/// Schreibrecht auf Ordner. Ausserhalb des App Store ein No-op; in der Sandbox
/// (MAS_BUILD) deckt eine gezogene Datei nur sich selbst ab — wer daneben etwas
/// ablegen oder umbenennen will, braucht die Freigabe des Ordners. Ein NSOpenPanel
/// holt sie einmalig, ein Security-Scoped Bookmark hält sie über App-Neustarts.
@MainActor
enum FolderAccess {
#if MAS_BUILD
    private static let defaultsKey = "folderBookmarks"

    /// Für alle Ordner der übergebenen Dateien Schreibrecht sicherstellen.
    /// false, sobald der Nutzer eine Freigabe verweigert.
    static func ensureWritable(forFiles urls: [URL]) -> Bool {
        let folders = Set(urls.map { $0.deletingLastPathComponent().standardizedFileURL })
        for folder in folders where !ensureWritable(folder) { return false }
        return true
    }

    static func ensureWritable(_ folder: URL) -> Bool {
        var bookmarks = (UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Data]) ?? [:]

        // Bereits freigegeben? Bookmark auflösen und Zugriff aktivieren.
        // (Der Zugriff bleibt bewusst bis zum App-Ende aktiv.)
        for (path, data) in bookmarks where folder.path == path || folder.path.hasPrefix(path + "/") {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope,
                                  relativeTo: nil, bookmarkDataIsStale: &stale),
               !stale, url.startAccessingSecurityScopedResource() {
                return true
            }
            bookmarks.removeValue(forKey: path)
            UserDefaults.standard.set(bookmarks, forKey: defaultsKey)
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = folder
        panel.prompt = LanguageStore.current("Freigeben")
        panel.message = LanguageStore.current("Damit Toolbox hier speichern darf, den Ordner einmalig bestätigen.")
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let granted = panel.url else { return false }

        if let data = try? granted.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil, relativeTo: nil) {
            bookmarks[granted.standardizedFileURL.path] = data
            UserDefaults.standard.set(bookmarks, forKey: defaultsKey)
        }
        _ = granted.startAccessingSecurityScopedResource()
        let grantedPath = granted.standardizedFileURL.path
        return folder.path == grantedPath || folder.path.hasPrefix(grantedPath + "/")
    }
#else
    static func ensureWritable(forFiles urls: [URL]) -> Bool { true }
    static func ensureWritable(_ folder: URL) -> Bool { true }
#endif
}
