import SwiftUI

/// Einklappbare Sektion mit Chevron; Zustand bleibt pro Sektion gespeichert.
struct CollapsibleSection<Content: View, Accessory: View>: View {
    let title: String
    let storageID: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder let accessory: () -> Accessory

    @AppStorage private var collapsed: Bool

    init(_ title: String, storageID: String,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
        self.title = title
        self.storageID = storageID
        self.content = content
        self.accessory = accessory
        _collapsed = AppStorage(wrappedValue: false, "sectionCollapsed.\(storageID)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { collapsed.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .rotationEffect(.degrees(collapsed ? 0 : 90))
                            .foregroundStyle(.secondary)
                        SectionTitle(title)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                accessory()
            }
            if !collapsed {
                content()
            }
        }
    }
}
