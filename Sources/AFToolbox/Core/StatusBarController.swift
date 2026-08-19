import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let closeAFToolboxPopover = Notification.Name("closeAFToolboxPopover")
    /// Wird von RootView mit der neuen Zielgrösse gepostet (userInfo["size"] = CGSize).
    static let afToolboxWindowSizeChanged = Notification.Name("afToolboxWindowSizeChanged")
}

/// Klassisches StatusItem + NSPopover statt MenuBarExtra: Das Fenster bleibt offen,
/// bis erneut aufs Menüleisten-Symbol geklickt wird, und die Grösse ist frei einstellbar.
@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    /// Zuletzt gemeldete Zielgrösse. Der Controller ist der einzige Schreiber der
    /// Popover-Grösse — RootView meldet nur.
    private var contentSize = WindowMetrics.storedSize()
    /// Gemerkt, damit die Blaufärbung einen Neuaufbau des Status-Items übersteht.
    private var wakeActive = false

    init(rootView: AnyView, wake: WakeManager) {
        super.init()

        buildStatusItem()

        // Grösse wird explizit gesetzt, nicht aus der View abgeleitet: Mit
        // sizingOptions = .preferredContentSize übernahm der Popover beim Wechsel
        // auf die Einstellungen einen Zwischenwert der Grössenanimation und
        // schnitt den Inhalt ab.
        let hosting = NSHostingController(rootView: rootView)
        popover.contentViewController = hosting
        popover.contentSize = contentSize
        popover.behavior = .applicationDefined // bleibt offen bei Klick daneben
        popover.animates = false
        popover.appearance = NSAppearance(named: .darkAqua)

        bindWake(wake)

        NotificationCenter.default.addObserver(forName: .closeAFToolboxPopover, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }

        NotificationCenter.default.addObserver(forName: .afToolboxWindowSizeChanged, object: nil, queue: .main) { [weak self] note in
            guard let size = note.userInfo?["size"] as? CGSize else { return }
            Task { @MainActor in self?.apply(size: size) }
        }

        observeSystemChanges()
    }

    // MARK: - Menüleisten-Symbol

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Ohne autosaveName vergibt AppKit einen abgeleiteten Namen. Ein eigener,
        // stabiler Schlüssel macht die gespeicherte Sichtbarkeit vorhersagbar —
        // und lässt sie sich beim Start gezielt zurücksetzen.
        statusItem.autosaveName = "BarBoxStatusItem"
        statusItem.isVisible = true
        applyButton()
    }

    private func applyButton() {
        guard let button = statusItem.button else { return }
        button.image = BarBoxIcon.menuBarImage
        button.target = self
        button.action = #selector(togglePopover)
        button.toolTip = "BarBox"
        button.contentTintColor = wakeActive ? .systemBlue : nil
    }

    /// Bei aktivem «Wach halten» wird das Symbol blau eingefärbt.
    private func bindWake(_ wake: WakeManager) {
        wake.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] active in
                self?.wakeActive = active
                self?.statusItem?.button?.contentTintColor = active ? .systemBlue : nil
            }
            .store(in: &cancellables)
    }

    /// Selbstheilung nach Displaywechsel, Aufwachen oder Benutzerwechsel.
    /// Gegen Menüleisten-Überlauf (volle Leiste, Notch) hilft das nicht — dagegen
    /// gibt es keine API. Dafür ist der Reopen-Weg im AppDelegate da.
    private func observeSystemChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reassert() }
        }

        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.reassert() }
            }
        }
    }

    /// Idempotent: stellt Sichtbarkeit, Bild und Aktion wieder her. Baut das
    /// Status-Item nur dann neu auf, wenn es nachweislich keinen Button mehr hat —
    /// ein Neuaufbau kostet die gespeicherte Position in der Leiste.
    func reassert() {
        guard statusItem != nil else {
            buildStatusItem()
            return
        }
        statusItem.isVisible = true
        if statusItem.button == nil || statusItem.button?.window == nil {
            NSStatusBar.system.removeStatusItem(statusItem)
            buildStatusItem()
        } else {
            applyButton()
        }
    }

    /// Notausgang: Ist das Symbol nicht auffindbar, startet man BarBox aus
    /// Spotlight oder dem Dock. macOS schickt der laufenden Instanz ein Reopen —
    /// wir stellen das Symbol wieder her und zeigen gleich das Fenster.
    func reassertAndShow() {
        reassert()
        if !popover.isShown { show() }
    }

    // MARK: - Fenster

    private func apply(size: CGSize) {
        guard size != contentSize else { return } // Sturm beim Ziehen dämpfen
        contentSize = size
        if popover.isShown { popover.contentSize = size }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            close()
        } else {
            show()
        }
    }

    func show() {
        guard let button = statusItem?.button else { return }
        // Der Bildschirm kann seit dem letzten Öffnen gewechselt haben
        // (Notebook an- oder abgedockt) — Höhe darum frisch nachklemmen.
        var size = contentSize
        size.height = min(size.height, WindowMetrics.usableHeight(on: button.window?.screen))
        popover.contentSize = size

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func close() {
        popover.performClose(nil)
    }
}
