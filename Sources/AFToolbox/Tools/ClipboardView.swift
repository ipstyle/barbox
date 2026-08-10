import SwiftUI

struct ClipboardView: View {
    @EnvironmentObject private var clipboard: ClipboardManager
    @EnvironmentObject private var lang: LanguageStore
    @State private var copiedItem: String?

    var body: some View {
        VStack(spacing: 0) {
            if clipboard.items.isEmpty {
                Spacer()
                Text(lang.t("Noch nichts kopiert — der Verlauf sammelt ab jetzt die letzten 20 Text-Einträge."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(24)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(clipboard.items, id: \.self) { item in
                            Button {
                                clipboard.copy(item)
                                copiedItem = item
                            } label: {
                                HStack(spacing: 8) {
                                    Text(item.trimmingCharacters(in: .whitespacesAndNewlines))
                                        .font(.system(size: 11))
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if copiedItem == item {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Theme.green)
                                    } else {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
                                .contentShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .help(lang.t("Klick kopiert den Eintrag wieder in die Zwischenablage"))
                        }
                    }
                    .padding(12)
                }
                Divider()
                HStack {
                    Text("\(clipboard.items.count)" + lang.t(" Einträge"))
                        .font(.system(size: 10)).foregroundStyle(.tertiary)
                    Spacer()
                    Button(lang.t("Verlauf löschen")) { clipboard.clear() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .navigationTitle(lang.t("Zwischenablage"))
    }
}
