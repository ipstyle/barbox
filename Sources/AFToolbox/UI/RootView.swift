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
    @AppStorage("windowWidth") private var windowWidth = 360.0
    @AppStorage("windowHeight") private var windowHeight = 560.0

    // Einstellungen bekommen ein grösseres Fenster, damit alles gut lesbar ist
    private var isSettings: Bool { path.last == .settings }

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
        .frame(width: isSettings ? max(windowWidth, 500) : windowWidth,
               height: isSettings ? max(windowHeight, 660) : windowHeight)
        .background(Theme.background)
        // MenuBarExtra ignoriert preferredColorScheme — Umgebung direkt erzwingen,
        // sonst bleibt der Text im System-Hellmodus schwarz auf Anthrazit
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .tint(Color(red: 0.35, green: 0.62, blue: 1.0))
        .animation(.easeInOut(duration: 0.15), value: isSettings)
    }
}
