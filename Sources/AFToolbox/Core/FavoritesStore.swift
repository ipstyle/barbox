import AppKit
import Foundation

struct FavoriteApp: Codable, Identifiable, Equatable {
    let path: String
    var name: String
    var id: String { path }
}

@MainActor
final class FavoritesStore: ObservableObject {
    @Published var apps: [FavoriteApp] = [] {
        didSet { save() }
    }

    private static let storeURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("BarBox", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("favorites.json")
        // Migration vom alten Ordnernamen (bis 1.8: AF-Toolbox)
        let legacy = support.appendingPathComponent("AF-Toolbox/favorites.json")
        if !FileManager.default.fileExists(atPath: url.path),
           FileManager.default.fileExists(atPath: legacy.path) {
            try? FileManager.default.copyItem(at: legacy, to: url)
        }
        return url
    }()

    init() {
        if let data = try? Data(contentsOf: Self.storeURL),
           let decoded = try? JSONDecoder().decode([FavoriteApp].self, from: data) {
            apps = decoded
        }
    }

    func add(url: URL) {
        let path = url.path
        guard path.hasSuffix(".app"), !apps.contains(where: { $0.path == path }) else { return }
        apps.append(FavoriteApp(path: path, name: FileManager.default.displayName(atPath: path)))
    }

    func remove(_ app: FavoriteApp) {
        apps.removeAll { $0.id == app.id }
    }

    func move(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
    }

    func launch(_ app: FavoriteApp) {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app.path),
                                           configuration: NSWorkspace.OpenConfiguration())
    }

    private func save() {
        if let data = try? JSONEncoder().encode(apps) {
            try? data.write(to: Self.storeURL)
        }
    }
}
