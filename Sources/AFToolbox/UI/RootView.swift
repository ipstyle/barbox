import SwiftUI

enum Route: Hashable {
    case appList
    case images
    case timeMachine
    case systemSettings
    case settings
    case ocr
    case pdfMerge
    case qrCode
    case rename
    case clipboard
    case timerTool
    case password
    case netInfo
    case finance
}

struct RootView: View {
    // Für Doku-Screenshots («--route settings»): Startansicht vorwählen
    @State private var path: [Route] = {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--route"), args.count > idx + 1,
           args[idx + 1] == "settings" {
            return [.settings]
        }
        return []
    }()
    @AppStorage("windowWidth") private var windowWidth = WindowMetrics.defaultWidth
    @AppStorage("windowHeight") private var windowHeight = WindowMetrics.defaultHeight

    // Einstellungen bekommen ein grösseres Fenster, damit alles gut lesbar ist
    private var isSettings: Bool { path.last == .settings }

    /// Zielgrösse aus der gemeinsamen Rechenstelle. Der Popover bekommt exakt
    /// denselben Wert gemeldet — sonst wird der Inhalt abgeschnitten.
    private var desiredSize: CGSize {
        WindowMetrics.contentSize(isSettings: isSettings,
                                  width: windowWidth, height: windowHeight)
    }

    private func postSize() {
        NotificationCenter.default.post(name: .afToolboxWindowSizeChanged,
                                        object: nil,
                                        userInfo: ["size": desiredSize])
    }

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .appList: ToolPage(title: "App-Liste") { AppListView() }
                    case .images: ToolPage(title: "Bilder komprimieren") { ImageCompressorView() }
                    case .timeMachine: ToolPage(title: "Time Machine") { TimeMachineView() }
                    case .systemSettings: ToolPage(title: "Systemeinstellungen") { SystemSettingsLinksView() }
                    case .settings: ToolPage(title: "Einstellungen") { SettingsView() }
                    case .ocr: ToolPage(title: "Text aus Bild") { OCRView() }
                    case .pdfMerge: ToolPage(title: "PDF zusammenfügen") { PDFMergeView() }
                    case .qrCode: ToolPage(title: "QR-Code") { QRCodeView() }
                    case .rename: ToolPage(title: "Umbenennen") { RenameView() }
                    case .clipboard: ToolPage(title: "Zwischenablage") { ClipboardView() }
                    case .timerTool: ToolPage(title: "Timer") { TimerView() }
                    case .password: ToolPage(title: "Passwörter") { PasswordView() }
                    case .netInfo: ToolPage(title: "Netzwerk & Info") { NetworkInfoView() }
                    case .finance: ToolPage(title: "Finanzen") { FinanceView() }
                    }
                }
        }
        .frame(width: desiredSize.width, height: desiredSize.height)
        .background(Theme.background)
        .onAppear { postSize() }
        .onChange(of: desiredSize) { _, _ in postSize() }
        // MenuBarExtra ignoriert preferredColorScheme — Umgebung direkt erzwingen,
        // sonst bleibt der Text im System-Hellmodus schwarz auf Anthrazit
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .tint(Color(red: 0.35, green: 0.62, blue: 1.0))
    }
}
