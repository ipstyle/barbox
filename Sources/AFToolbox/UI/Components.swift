import AppKit
import SwiftUI

/// Kopfzeile mit Zurück-Knopf für alle Unteransichten — der NSPopover-Unterbau
/// zeigt die System-Navigationsleiste nicht an, darum eine eigene.
struct ToolPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lang: LanguageStore

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(lang.t(title))
                    .font(.system(size: 12, weight: .semibold))
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text(lang.t("Zurück"))
                                .font(.system(size: 11))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            Divider()
            content()
        }
        // Deckender Hintergrund — sonst scheint das Dashboard darunter durch
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

/// Reine Chip-Optik (für Menü-Labels und Buttons gleichermassen)
struct StatusChipLabel: View {
    let icon: String
    let text: String
    let active: Bool
    let tint: Color
    var showsChevron = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .fixedSize()
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .semibold))
                    .opacity(0.7)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(active ? tint.opacity(0.22) : Theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(active ? tint.opacity(0.35) : Theme.stroke))
        .foregroundStyle(active ? tint : Color.secondary)
    }
}

struct StatusChip: View {
    let icon: String
    let text: String
    let active: Bool
    let tint: Color
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(active ? tint.opacity(0.22) : Theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(active ? tint.opacity(0.35) : Theme.stroke))
            .foregroundStyle(active ? tint : Color.secondary)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// Bewusst KEIN Button: Buttons schlucken den Maus-Drag, dann funktioniert das
// Sortieren per Drag & Drop nicht. Tap-Geste + Drag vertragen sich.
struct ToolTile: View {
    let icon: String
    let title: String
    var active = false
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(height: 17)
            Text(title)
                .font(.system(size: 9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(active ? Theme.cardActive : Theme.card,
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(active ? Color.accentColor.opacity(0.4) : Theme.stroke))
        .foregroundStyle(active ? Color.accentColor : Color.primary)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(perform: action)
        .help(title)
    }
}

struct AppIconView: View {
    let path: String
    var size: CGFloat = 32

    var body: some View {
        Image(nsImage: AppIconCache.icon(for: path))
            .resizable()
            .frame(width: size, height: size)
    }
}

enum AppIconCache {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(for path: String) -> NSImage {
        if let cached = cache.object(forKey: path as NSString) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 64, height: 64)
        cache.setObject(icon, forKey: path as NSString)
        return icon
    }
}

func closePopoverWindow() {
    NotificationCenter.default.post(name: .closeAFToolboxPopover, object: nil)
}

/// Sortieren per Drag & Drop innerhalb eines Rasters: verschiebt Einträge schon
/// beim Darüberziehen und meldet am Ende einmal «fertig» zum Speichern.
struct ReorderDropDelegate: DropDelegate {
    let itemID: String
    @Binding var dragging: String?
    let indexOf: (String) -> Int?
    let move: (Int, Int) -> Void
    let finish: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != itemID,
              let from = indexOf(dragging),
              let to = indexOf(itemID) else { return }
        let destination = to > from ? to + 1 : to
        guard destination != from, destination != from + 1 else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            move(from, destination)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        finish()
        return true
    }
}

/// Drop-Delegate für den Favoriten-Bereich: nimmt Items aus anderen Sektionen auf
/// (einfügen) und sortiert vorhandene (verschieben).
struct FavoritesDropDelegate: DropDelegate {
    let itemID: String?          // nil = Bereichs-Hintergrund → ans Ende
    @Binding var dragging: String?
    @Binding var favorites: [String]
    let save: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging else { return }
        if let from = favorites.firstIndex(of: dragging) {
            guard dragging != itemID else { return }
            // Ziel bestimmen; über dem Hintergrund (itemID nil) = ans Ende —
            // toOffset darf favorites.count nie überschreiten (sonst Absturz)
            let destination: Int
            if let itemID, let to = favorites.firstIndex(of: itemID) {
                destination = to > from ? to + 1 : to
            } else {
                destination = favorites.count
            }
            guard destination != from, destination != from + 1 else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                favorites.move(fromOffsets: IndexSet(integer: from),
                               toOffset: min(destination, favorites.count))
            }
        } else {
            let target = itemID.flatMap { favorites.firstIndex(of: $0) } ?? favorites.count
            withAnimation(.easeInOut(duration: 0.15)) {
                favorites.insert(dragging, at: min(target, favorites.count))
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        save()
        return true
    }
}

enum AppInfo {
    static let version: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    static let build: String =
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
}
