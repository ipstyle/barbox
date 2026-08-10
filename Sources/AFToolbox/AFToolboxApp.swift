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
    private let spaces = SpaceObserver()
    private let stats = StatsModel()
    private let clipboard = ClipboardManager()
    private let timerManager = TimerManager()
    private let weather = WeatherModel()
    private let language = LanguageStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let root = AnyView(
            RootView()
                .environmentObject(systemStatus)
                .environmentObject(wake)
                .environmentObject(favorites)
                .environmentObject(spaces)
                .environmentObject(stats)
                .environmentObject(clipboard)
                .environmentObject(timerManager)
                .environmentObject(weather)
                .environmentObject(language)
        )
        statusBar = StatusBarController(rootView: root, wake: wake)
    }
}
