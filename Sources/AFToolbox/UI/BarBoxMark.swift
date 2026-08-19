import AppKit
import SwiftUI

/// Markenzeichen «Balken über Box» — dasselbe Motiv wie das App-Icon,
/// als SwiftUI-View (Dashboard-Header) und als Template-NSImage (Menüleiste).
struct BarBoxMark: View {
    var size: CGFloat = 13

    var body: some View {
        VStack(spacing: size * 0.16) {
            RoundedRectangle(cornerRadius: size * 0.11)
                .frame(width: size, height: size * 0.24)
            RoundedRectangle(cornerRadius: size * 0.16)
                .frame(width: size * 0.8, height: size * 0.56)
        }
        .frame(width: size, height: size)
    }
}

enum BarBoxIcon {
    /// Monochromes Menüleisten-Symbol; isTemplate lässt macOS die Farbe
    /// an helle/dunkle Menüleiste anpassen.
    ///
    /// Bewusst sofort in eine Bitmap gezeichnet statt über den verzögerten
    /// drawingHandler von `NSImage(size:flipped:)`: Der wird erst beim Zeichnen
    /// aufgerufen, und in der Menüleiste kam dabei nichts an — das Element
    /// belegte Platz, blieb aber leer.
    static let menuBarImage: NSImage = {
        let size = NSSize(width: 18, height: 17)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 1, y: size.height - 5.6, width: size.width - 2, height: 4.2),
                     xRadius: 2.1, yRadius: 2.1).fill()
        NSBezierPath(roundedRect: NSRect(x: 2.5, y: 1.4, width: size.width - 5, height: 8.8),
                     xRadius: 2.2, yRadius: 2.2).fill()
        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "BarBox"
        return image
    }()
}
