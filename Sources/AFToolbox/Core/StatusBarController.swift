import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let closeAFToolboxPopover = Notification.Name("closeAFToolboxPopover")
    static let afToolboxWindowSizeChanged = Notification.Name("afToolboxWindowSizeChanged")
}

/// Klassisches StatusItem + NSPopover statt MenuBarExtra: Das Fenster bleibt offen,
/// bis erneut aufs Menüleisten-Symbol geklickt wird, und die Grösse ist frei einstellbar.
@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(rootView: AnyView, wake: WakeManager) {
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wrench.adjustable", accessibilityDescription: "AF-Toolbox")
            button.title = " T-Box"
            button.imagePosition = .imageLeading
            button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            button.target = self
            button.action = #selector(togglePopover)
        }

        let hosting = NSHostingController(rootView: rootView)
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
        popover.behavior = .applicationDefined // bleibt offen bei Klick daneben
        popover.animates = false
        popover.appearance = NSAppearance(named: .darkAqua)

        // Bei aktivem «Wach halten»: Symbol bleibt, der Text «CP» wird blau
        wake.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] active in
                guard let button = self?.statusItem.button else { return }
                button.attributedTitle = NSAttributedString(
                    string: " T-Box",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                        .foregroundColor: active ? NSColor.systemBlue : NSColor.labelColor,
                    ])
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(forName: .closeAFToolboxPopover, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            close()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    func close() {
        popover.performClose(nil)
    }
}
