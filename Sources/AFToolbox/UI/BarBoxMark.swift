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
    /// Menüleisten-Symbol, normal: Template-Bild — macOS färbt es passend zur
    /// hellen oder dunklen Leiste ein.
    static let menuBarImage: NSImage = render(NSColor.black, template: true)

    /// Menüleisten-Symbol bei aktivem «Wach halten»: fest blau.
    ///
    /// Früher wurde stattdessen `button.contentTintColor` auf Blau gesetzt —
    /// damit verschwand das Symbol in der Menüleiste vollständig. Ein eigenes,
    /// nicht-Template-Bild ist unabhängig von der Tönungslogik und immer sichtbar.
    static let menuBarImageAwake: NSImage = render(NSColor.systemBlue, template: false)

    /// Sofort in eine Bitmap gezeichnet, nicht über den verzögerten
    /// drawingHandler von `NSImage(size:flipped:)` — der lieferte in der
    /// Menüleiste nichts, das Element blieb leer.
    private static func render(_ color: NSColor, template: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 17)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(x: 1, y: size.height - 5.6, width: size.width - 2, height: 4.2),
                     xRadius: 2.1, yRadius: 2.1).fill()
        NSBezierPath(roundedRect: NSRect(x: 2.5, y: 1.4, width: size.width - 5, height: 8.8),
                     xRadius: 2.2, yRadius: 2.2).fill()
        image.unlockFocus()
        image.isTemplate = template
        image.accessibilityDescription = "BarBox"
        return image
    }
}
