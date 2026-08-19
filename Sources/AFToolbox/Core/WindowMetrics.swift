import AppKit

/// Fenstermasse an einer einzigen Stelle.
///
/// RootView setzt damit seinen Frame, der StatusBarController die contentSize des
/// Popovers. Beide müssen exakt denselben Wert bekommen — laufen sie auseinander,
/// wird der Inhalt abgeschnitten (genau das war der Fehler bis 2.0).
enum WindowMetrics {
    static let minWidth: Double = 360
    static let maxWidth: Double = 520
    static let minHeight: Double = 480
    static let maxHeight: Double = 1500      // seit 2.1 (vorher 900)

    static let defaultWidth: Double = 360
    static let defaultHeight: Double = 900   // seit 2.1 (vorher 560)

    /// Die Einstellungen brauchen mehr Platz als das Dashboard.
    static let settingsMinWidth: Double = 500
    static let settingsMinHeight: Double = 660

    /// Höhe, die ein unter der Menüleiste hängendes Popover wirklich hat.
    /// `visibleFrame` kennt Menüleiste und Dock bereits; der Abzug ist für Pfeil
    /// und Randabstand.
    static func usableHeight(on screen: NSScreen? = nil) -> Double {
        guard let screen = screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return maxHeight
        }
        return max(minHeight, Double(screen.visibleFrame.height) - 24)
    }

    /// Die einzige Wahrheit über die Fenstergrösse.
    ///
    /// Reihenfolge ist wichtig: erst die Mindestmasse der Einstellungen, dann die
    /// Bildschirmklemmung — die Klemmung muss gewinnen, sonst erzwingt die
    /// Settings-Mindesthöhe auf einem kleinen Bildschirm ein Fenster, das nicht passt.
    static func contentSize(isSettings: Bool,
                            width: Double,
                            height: Double,
                            screen: NSScreen? = nil) -> CGSize {
        let wantedWidth = isSettings ? max(width, settingsMinWidth) : width
        let wantedHeight = isSettings ? max(height, settingsMinHeight) : height
        let w = min(max(wantedWidth, minWidth), maxWidth)
        let h = min(max(wantedHeight, minHeight), usableHeight(on: screen))
        return CGSize(width: w.rounded(), height: h.rounded())
    }

    /// Gespeicherte Masse — für den StatusBarController, bevor RootView das erste Mal meldet.
    static func storedSize(isSettings: Bool = false) -> CGSize {
        let defaults = UserDefaults.standard
        return contentSize(isSettings: isSettings,
                           width: defaults.object(forKey: "windowWidth") as? Double ?? defaultWidth,
                           height: defaults.object(forKey: "windowHeight") as? Double ?? defaultHeight)
    }

    /// Einmalige Anhebung für Bestandsnutzer, die nie am Regler waren: Wer exakt
    /// auf dem alten Vorgabewert 560 steht, bekommt die neue Vorgabe 900. Wer die
    /// Höhe bewusst gesetzt hat, behält sie.
    static func migrateDefaultHeightIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "heightDefaultMigrated21") else { return }
        if let stored = defaults.object(forKey: "windowHeight") as? Double, stored == 560.0 {
            defaults.set(defaultHeight, forKey: "windowHeight")
        }
        defaults.set(true, forKey: "heightDefaultMigrated21")
    }
}
