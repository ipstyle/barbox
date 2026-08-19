import Foundation
import os

/// Fragt den App Store, ob eine neuere Fassung von BarBox bereitliegt.
///
/// Bewusst zurückhaltend: prüft höchstens einmal am Tag, zeigt nur etwas, wenn
/// wirklich eine neuere Version da ist, und schweigt bei Fehlern. Abschaltbar in
/// den Einstellungen — eine App, die von selbst ins Netz geht, braucht einen
/// sichtbaren Schalter.
@MainActor
final class UpdateChecker: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, url: URL)
        case failed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastCheck: Date?

    private let log = Logger(subsystem: "com.ip-style.barbox", category: "update")

    private enum Key {
        static let lastCheck = "updateLastCheck"
        static let latestVersion = "updateLatestVersion"
        static let autoCheck = "updateAutoCheck"
    }

    private static let bundleID = "com.ip-style.barbox"
    private static let storePage = "https://apps.apple.com/app/id6802093315"
    private static let releasePage = "https://github.com/ipstyle/barbox/releases/latest"

    init() {
        lastCheck = UserDefaults.standard.object(forKey: Key.lastCheck) as? Date
        // Ein bereits erkanntes Update soll den Neustart überleben, auch offline.
        if let known = UserDefaults.standard.string(forKey: Key.latestVersion),
           Self.isNewer(known, than: Self.localVersion),
           let url = Self.downloadURL(trackViewUrl: nil) {
            state = .available(version: known, url: url)
        }
    }

    // MARK: - Prüfen

    /// Beim Start: nur wenn eingeschaltet und die letzte erfolgreiche Prüfung
    /// mehr als 24 Stunden her ist.
    func checkIfNeeded() async {
        guard UserDefaults.standard.object(forKey: Key.autoCheck) as? Bool ?? true else { return }
        if ProcessInfo.processInfo.arguments.contains("--screenshot") { return }
        if let lastCheck, Date().timeIntervalSince(lastCheck) < 86_400 { return }
        await check()
    }

    func check() async {
        // Ohne Bundle (Kommandozeilenstart) gibt es keine sinnvolle Version zum
        // Vergleichen — sonst wäre jede Store-Version «neuer».
        guard Self.localVersion != "dev" else {
            state = .idle
            return
        }

        state = .checking

        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [URLQueryItem(name: "bundleId", value: Self.bundleID)]
        guard let url = components.url else {
            state = .failed
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // Die Antwort beginnt mit Leerzeilen; defensiv ab der ersten Klammer lesen.
            let body = data.firstIndex(of: UInt8(ascii: "{")).map { Data(data[$0...]) } ?? data

            guard let json = try JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let entry = results.first,
                  let remote = entry["version"] as? String else {
                // Leeres Ergebnis heisst: in diesem Storefront nicht verfügbar,
                // Apple-Störung oder falsche Bundle-ID. Nichts davon ist etwas,
                // das ein Nutzer sehen soll — aber im Log will man es finden.
                log.notice("Update-Prüfung ohne verwertbares Ergebnis")
                state = .upToDate
                return
            }

            let defaults = UserDefaults.standard
            defaults.set(remote, forKey: Key.latestVersion)
            let now = Date()
            lastCheck = now
            defaults.set(now, forKey: Key.lastCheck)

            if Self.isNewer(remote, than: Self.localVersion),
               let target = Self.downloadURL(trackViewUrl: entry["trackViewUrl"] as? String) {
                state = .available(version: remote, url: target)
            } else {
                state = .upToDate
            }
        } catch {
            // Offline ist kein Fehler, den man dem Nutzer vorhält. lastCheck bleibt
            // alt, damit beim nächsten Start neu versucht wird.
            log.notice("Update-Prüfung fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
            state = .failed
        }
    }

    // MARK: - Vergleich

    /// Lokale Version — mit `--fake-version <x.y>` überschreibbar, damit sich der
    /// Fundfall testen lässt, ohne auf eine echte neue Store-Version zu warten.
    static var localVersion: String {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--fake-version"), args.count > idx + 1 {
            return args[idx + 1]
        }
        return AppInfo.version
    }

    /// Numerisch je Komponente. Ein Zeichenkettenvergleich hielte 2.10 für kleiner
    /// als 2.9, und `compare(options: .numeric)` hielte 2.0 für kleiner als 2.0.0.
    /// Gleichstand und «lokal neuer» ergeben beide false — damit ist der Fall
    /// abgedeckt, dass der GitHub-Build dem Store voraus ist.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        // Ohne eine einzige Ziffer ist es keine Version ("dev" beim Start ohne
        // Bundle) — sonst würde daraus [0] und jede Store-Version wäre neuer.
        func parts(_ value: String) -> [Int]? {
            guard value.contains(where: \.isNumber) else { return nil }
            return value.split(separator: ".").map { Int($0.prefix(while: \.isNumber)) ?? 0 }
        }
        guard let r = parts(remote), let l = parts(local) else { return false }
        for i in 0 ..< max(r.count, l.count) {
            let a = i < r.count ? r[i] : 0
            let b = i < l.count ? l[i] : 0
            if a != b { return a > b }
        }
        return false
    }

    /// Store-Fassung führt in den App Store, GitHub-Fassung auf die Release-Seite.
    private static func downloadURL(trackViewUrl: String?) -> URL? {
        #if MAS_BUILD
        if let trackViewUrl, let url = URL(string: trackViewUrl) { return url }
        return URL(string: storePage)
        #else
        return URL(string: releasePage)
        #endif
    }
}
