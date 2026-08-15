import AppKit
import SwiftUI

#if MAS_BUILD
/// Store-Variante: tmutil-Steuerung ist in der Sandbox nicht möglich; die Kachel
/// fehlt im ToolCatalog, dieser Stub hält nur die Route kompilierbar.
struct TimeMachineView: View {
    var body: some View { EmptyView() }
}
#else
struct TimeMachineView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var running = false
    @State private var percent: Double?
    @State private var lastBackup: String?
    @State private var destinationConfigured = true
    @State private var loading = true
    @State private var starting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusCard

            HStack(spacing: 8) {
                Button {
                    startBackup()
                } label: {
                    Label(lang.t("Backup starten"), systemImage: "play.circle")
                }
                .disabled(running || starting || !destinationConfigured)
                Button {
                    openSystemURL("x-apple.systempreferences:com.apple.Time-Machine-Settings.extension")
                } label: {
                    Label(lang.t("Öffnen"), systemImage: "arrow.up.forward.app")
                }
            }

            if !destinationConfigured {
                Label(lang.t("Kein Backup-Ziel eingerichtet — zuerst in den Time-Machine-Einstellungen ein Volume wählen."),
                      systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.orange)
            }

            Spacer()
        }
        .padding(12)
        .navigationTitle(lang.t("Time Machine"))
        .task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 26))
                .foregroundStyle(running ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 3) {
                if loading {
                    Text(lang.t("Status wird gelesen…"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else if running {
                    Text(percentText)
                        .font(.system(size: 13, weight: .medium))
                    ProgressView(value: min(max(percent ?? 0, 0), 1))
                        .controlSize(.small)
                } else {
                    Text(lang.t("Kein Backup aktiv"))
                        .font(.system(size: 13, weight: .medium))
                    Text(lang.t("Letztes Backup: ") + (lastBackup ?? lang.t("unbekannt")))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private var percentText: String {
        if let percent {
            return lang.t("Backup läuft — ") + "\(Int((percent * 100).rounded())) %"
        }
        return lang.t("Backup läuft…")
    }

    private func startBackup() {
        starting = true
        Task {
            _ = await Shell.runAsync("/usr/bin/tmutil", ["startbackup"])
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await refresh()
            starting = false
        }
    }

    private func refresh() async {
        let status = await Shell.runAsync("/usr/bin/tmutil", ["status"]).output
        running = status.contains("Running = 1")
        percent = parsePercent(from: status)

        let latest = await Shell.runAsync("/usr/bin/tmutil", ["latestbackup"])
        if latest.status == 0 {
            lastBackup = formatBackupPath(latest.output.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let destinations = await Shell.runAsync("/usr/bin/tmutil", ["destinationinfo"])
        destinationConfigured = destinations.status == 0
            && !destinations.output.contains("No destinations configured")
        loading = false
    }

    private func parsePercent(from output: String) -> Double? {
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("Percent"), !trimmed.hasPrefix("_") else { continue }
            let cleaned = trimmed
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: ";", with: "")
            guard let valuePart = cleaned.components(separatedBy: "=").last,
                  let value = Double(valuePart.trimmingCharacters(in: .whitespaces)), value >= 0 else { continue }
            return value
        }
        return nil
    }

    private func formatBackupPath(_ path: String) -> String {
        // Letzte Pfadkomponente sieht aus wie "2026-08-10-091223" (ggf. mit Suffix)
        let component = (path as NSString).lastPathComponent
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let stamp = String(component.prefix(17))
        if let date = formatter.date(from: stamp) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return component
    }
}
#endif
