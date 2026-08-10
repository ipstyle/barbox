import Foundation

enum ToolAction {
    case route(Route)
    case wakeToggle
    case darkMode
    case airDrop
    case activityMonitor
    case focus
}

struct ToolItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let action: ToolAction
}

/// Zentrale Definition aller Werkzeuge und Schnellaktionen. Favoriten, Sortierung
/// und Raster in der UI arbeiten nur noch mit den IDs von hier.
enum ToolCatalog {
    static let tools: [ToolItem] = [
        ToolItem(id: "wake", title: "Wach halten", icon: "cup.and.saucer", action: .wakeToggle),
        ToolItem(id: "images", title: "Bilder", icon: "photo.on.rectangle.angled", action: .route(.images)),
        ToolItem(id: "ocr", title: "Text aus Bild", icon: "text.viewfinder", action: .route(.ocr)),
        ToolItem(id: "pdf", title: "PDF", icon: "doc.on.doc", action: .route(.pdfMerge)),
        ToolItem(id: "qr", title: "QR-Code", icon: "qrcode", action: .route(.qrCode)),
        ToolItem(id: "rename", title: "Umbenennen", icon: "pencil.line", action: .route(.rename)),
        ToolItem(id: "clipboard", title: "Ablage", icon: "doc.on.clipboard", action: .route(.clipboard)),
        ToolItem(id: "timer", title: "Timer", icon: "timer", action: .route(.timerTool)),
        ToolItem(id: "password", title: "Passwörter", icon: "key", action: .route(.password)),
        ToolItem(id: "finance", title: "Finanzen", icon: "francsign.circle", action: .route(.finance)),
        ToolItem(id: "network", title: "Netzwerk", icon: "network", action: .route(.netInfo)),
        ToolItem(id: "timemachine", title: "Time Machine", icon: "clock.arrow.circlepath", action: .route(.timeMachine)),
        ToolItem(id: "qa.darkmode", title: "Hell/Dunkel", icon: "circle.lefthalf.filled", action: .darkMode),
        ToolItem(id: "qa.activity", title: "Aktivität", icon: "waveform.path.ecg", action: .activityMonitor),
        ToolItem(id: "qa.focus", title: "Fokus", icon: "moon.circle", action: .focus),
    ]

    // Sektion «System Settings»: Zugänge zu Einstellungen und App-Liste
    static let quickActions: [ToolItem] = [
        ToolItem(id: "settings", title: "Einstellungen", icon: "gearshape", action: .route(.settings)),
        ToolItem(id: "system", title: "System", icon: "slider.horizontal.3", action: .route(.systemSettings)),
        ToolItem(id: "applist", title: "App-Liste", icon: "square.grid.3x3", action: .route(.appList)),
    ]

    static let all: [ToolItem] = tools + quickActions

    static func item(_ id: String) -> ToolItem? {
        all.first { $0.id == id }
    }

    /// Gespeicherte CSV-Reihenfolge laden: unbekannte IDs verwerfen, neue anhängen
    static func order(from raw: String, defaults: [ToolItem]) -> [String] {
        let known = defaults.map(\.id)
        let stored = raw.split(separator: ",").map(String.init).filter { known.contains($0) }
        return stored + known.filter { !stored.contains($0) }
    }
}
