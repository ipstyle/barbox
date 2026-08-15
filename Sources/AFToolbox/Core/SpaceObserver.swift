import AppKit
import Foundation

/// Liest den aktuellen Desktop (Space) und die Anzahl Desktops über die private
/// SkyLight-API aus — per dlsym, damit kein Linken gegen das Private Framework nötig ist.
/// Fällt die API weg, liefert der Observer nil und die UI nutzt den Fallback.
#if MAS_BUILD
/// Store-Variante: SkyLight ist ein privates Framework — kein Space-Auslesen.
/// Die Desktop-Sektion ist unter MAS_BUILD ohnehin ausgeblendet.
@MainActor
final class SpaceObserver: ObservableObject {
    @Published var currentIndex: Int?
    @Published var spaceCount: Int?
    func refresh() {}
}
#else
@MainActor
final class SpaceObserver: ObservableObject {
    @Published var currentIndex: Int?
    @Published var spaceCount: Int?

    private typealias MainConnectionFn = @convention(c) () -> UInt32
    private typealias CopySpacesFn = @convention(c) (UInt32) -> Unmanaged<CFArray>?

    private let mainConnection: MainConnectionFn?
    private let copySpaces: CopySpacesFn?

    init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW),
           let connSym = dlsym(handle, "SLSMainConnectionID"),
           let copySym = dlsym(handle, "SLSCopyManagedDisplaySpaces") {
            mainConnection = unsafeBitCast(connSym, to: MainConnectionFn.self)
            copySpaces = unsafeBitCast(copySym, to: CopySpacesFn.self)
        } else {
            mainConnection = nil
            copySpaces = nil
        }
        refresh()
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard let mainConnection, let copySpaces,
              let displays = copySpaces(mainConnection())?.takeRetainedValue() as? [[String: Any]] else {
            currentIndex = nil
            spaceCount = nil
            return
        }
        // Bei mehreren Bildschirmen den Hauptbildschirm bevorzugen
        let ordered = displays.sorted { lhs, _ in
            (lhs["Display Identifier"] as? String) == "Main"
        }
        for display in ordered {
            guard let current = display["Current Space"] as? [String: Any],
                  let currentID = (current["ManagedSpaceID"] as? NSNumber)?.intValue,
                  let spaces = display["Spaces"] as? [[String: Any]] else { continue }
            // type 0 = normaler Benutzer-Desktop; 4 = Vollbild-App
            let userSpaces = spaces.filter { (($0["type"] as? NSNumber)?.intValue ?? 0) == 0 }
            if let index = userSpaces.firstIndex(where: { (($0["ManagedSpaceID"] as? NSNumber)?.intValue) == currentID }) {
                currentIndex = index + 1
                spaceCount = userSpaces.count
                return
            }
            // Aktuell in einer Vollbild-App: Anzahl trotzdem melden
            if !userSpaces.isEmpty {
                currentIndex = nil
                spaceCount = userSpaces.count
                return
            }
        }
        currentIndex = nil
        spaceCount = nil
    }
}
#endif
