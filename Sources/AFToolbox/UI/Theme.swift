import SwiftUI

/// Zentrale Design-Konstanten. Die App erzwingt Dark Mode mit Anthrazit-Hintergrund.
enum Theme {
    /// Anthrazit-Grundton der App
    static let background = Color(red: 0.153, green: 0.161, blue: 0.176)
    /// Karten heben sich klar vom Hintergrund ab
    static let card = Color.white.opacity(0.10)
    static let cardActive = Color.accentColor.opacity(0.30)
    /// Feiner Rand um Karten und Chips
    static let stroke = Color.white.opacity(0.08)

    // Leuchtende Statusfarben — auf Anthrazit gut lesbar
    static let green = Color(red: 0.38, green: 0.85, blue: 0.48)
    static let red = Color(red: 1.0, green: 0.45, blue: 0.42)
    static let blue = Color(red: 0.45, green: 0.72, blue: 1.0)
    static let indigo = Color(red: 0.72, green: 0.70, blue: 1.0)
    static let orange = Color(red: 1.0, green: 0.68, blue: 0.30)
}
