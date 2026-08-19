import AppKit
import SwiftUI

@main
struct AFToolboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?

    private let systemStatus = SystemStatusModel()
    private let wake = WakeManager()
    private let favorites = FavoritesStore()
    private let stats = StatsModel()
    private let clipboard = ClipboardManager()
    private let timerManager = TimerManager()
    private let weather = WeatherModel()
    private let language = LanguageStore()
    private let updates = UpdateChecker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Einmalige Anhebung der Fensterhöhe für alle, die nie am Regler waren
        WindowMetrics.migrateDefaultHeightIfNeeded()

        let root = AnyView(
            RootView()
                .environmentObject(systemStatus)
                .environmentObject(wake)
                .environmentObject(favorites)
                .environmentObject(stats)
                .environmentObject(clipboard)
                .environmentObject(timerManager)
                .environmentObject(weather)
                .environmentObject(language)
                .environmentObject(updates)
        )
        statusBar = StatusBarController(rootView: root, wake: wake)

        // Verzögert, damit der Start nicht am Netz hängt
        Task { [updates] in
            try? await Task.sleep(for: .seconds(5))
            await updates.checkIfNeeded()
        }

        // Für Doku-Screenshots: zeigt den Inhalt in einem freien Fenster an
        // fester Position (unten links 60/60) — unabhängig von der Menüleiste.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--show-popover") || args.contains("--screenshot") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showScreenshotWindow(root: root)
            }
        }
        // --screenshot <pfad.png>: rendert das Fenster nach 8 s als PNG (2x)
        // direkt aus der View-Hierarchie und beendet die App — kein Bildschirmfoto,
        // keine Freigaben, keine fremden Fensterinhalte.
        if let idx = args.firstIndex(of: "--screenshot"), args.count > idx + 1 {
            let path = args[idx + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                var status = "no window"
                if let view = self?.screenshotWindow?.contentView,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    do {
                        try rep.representation(using: .png, properties: [:])?
                            .write(to: URL(fileURLWithPath: path))
                        status = "ok"
                    } catch {
                        status = "write failed: \(error.localizedDescription)"
                    }
                }
                try? status.write(toFile: path + ".status", atomically: true, encoding: .utf8)
                exit(0)
            }
        }
    }

    /// macOS startet keine zweite Instanz, sondern schickt der laufenden ein
    /// Reopen. Wenn das Menüleisten-Symbol verschwunden ist, ist das der einzige
    /// verlässliche Weg zurück — Symbol wiederherstellen und Fenster zeigen.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        statusBar?.reassertAndShow()
        return true
    }

    private var screenshotWindow: NSWindow?

    private func showScreenshotWindow(root: AnyView) {
        let hosting = NSHostingController(rootView: root)
        let win = NSWindow(contentViewController: hosting)
        win.styleMask = [.borderless]
        win.appearance = NSAppearance(named: .darkAqua)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.contentView?.wantsLayer = true
        win.contentView?.layer?.cornerRadius = 12
        win.contentView?.layer?.masksToBounds = true
        win.setFrameOrigin(NSPoint(x: 60, y: 60))
        win.orderFrontRegardless()
        screenshotWindow = win
    }
}
