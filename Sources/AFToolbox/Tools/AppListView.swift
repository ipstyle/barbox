import AppKit
import SwiftUI

struct InstalledApp: Identifiable, Hashable {
    let name: String
    let path: String
    var id: String { path }
}

struct AppListView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var lang: LanguageStore
    @State private var apps: [InstalledApp] = []
    @State private var search = ""
    @State private var loading = true

    private var filtered: [InstalledApp] {
        guard !search.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField(lang.t("App suchen…"), text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            Divider()
            if loading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { app in
                            row(app)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Divider()
                Text("\(filtered.count)" + lang.t(" Apps"))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
        }
        .navigationTitle(lang.t("App-Liste"))
        .task { await scan() }
    }

    private func row(_ app: InstalledApp) -> some View {
        HStack(spacing: 10) {
            Button {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app.path),
                                                   configuration: NSWorkspace.OpenConfiguration())
                closePopoverWindow()
            } label: {
                HStack(spacing: 10) {
                    AppIconView(path: app.path, size: 22)
                    Text(app.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if favorites.apps.contains(where: { $0.path == app.path }) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                    .help(lang.t("In den Favoriten"))
            } else {
                Button {
                    favorites.add(url: URL(fileURLWithPath: app.path))
                } label: {
                    Image(systemName: "plus.circle").font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(lang.t("Zu «Meine Apps» hinzufügen"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    private func scan() async {
        let dirs = [
            "/Applications",
            "/Applications/Utilities",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications",
        ]
        let found: [InstalledApp] = await Task.detached {
            let fm = FileManager.default
            var result: [InstalledApp] = []
            for dir in dirs {
                guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
                for item in items where item.hasSuffix(".app") {
                    let path = dir + "/" + item
                    result.append(InstalledApp(name: fm.displayName(atPath: path), path: path))
                }
            }
            return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }.value
        apps = found
        loading = false
    }
}
