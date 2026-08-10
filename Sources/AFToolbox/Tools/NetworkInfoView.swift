import AppKit
import Darwin
import SwiftUI

struct SpeedtestEntry: Codable, Identifiable {
    let date: Date
    let down: String
    let up: String
    var id: Date { date }
}

struct NetworkInfoView: View {
    @EnvironmentObject private var stats: StatsModel
    @EnvironmentObject private var lang: LanguageStore
    @State private var localIPs: [(name: String, address: String)] = []
    @State private var publicIP: String?
    @State private var loadingPublicIP = false
    @State private var speedResult: String?
    @State private var runningSpeedtest = false
    @AppStorage("speedtestHistory") private var speedtestHistoryRaw = ""
    @State private var history: [SpeedtestEntry] = []
    @State private var diskInfo = ""
    @State private var uptimeText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section(lang.t("IP-Adressen")) {
                    ForEach(localIPs, id: \.address) { ip in
                        infoRow(label: ip.name, value: ip.address, copyable: true)
                    }
                    if localIPs.isEmpty {
                        Text(lang.t("Kein Netzwerk verbunden"))
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if let publicIP {
                            infoRow(label: lang.t("Öffentlich"), value: publicIP, copyable: true)
                        } else {
                            Button(lang.t("Öffentliche IP abrufen")) { fetchPublicIP() }
                                .disabled(loadingPublicIP)
                            if loadingPublicIP { ProgressView().controlSize(.small) }
                        }
                    }
                }

                section(lang.t("Internet-Speedtest")) {
                    HStack(spacing: 8) {
                        Button(runningSpeedtest ? lang.t("Läuft… (~20 s)") : lang.t("Speedtest starten")) { runSpeedtest() }
                            .disabled(runningSpeedtest)
                        if runningSpeedtest { ProgressView().controlSize(.small) }
                    }
                    if let speedResult {
                        Text(speedResult)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.green)
                    }
                    if !history.isEmpty {
                        Divider()
                        Text(lang.t("Letzte Tests"))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        ForEach(history) { entry in
                            HStack {
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("↓ \(entry.down)   ↑ \(entry.up)")
                                    .font(.system(size: 10).monospacedDigit())
                            }
                        }
                    }
                }

                section(lang.t("System")) {
                    infoRow(label: lang.t("CPU"), value: "\(stats.cpu) %")
                    if let gpu = stats.gpu {
                        infoRow(label: lang.t("GPU"), value: "\(gpu) %")
                    }
                    infoRow(label: lang.t("RAM belegt"), value: "\(stats.mem) %")
                    infoRow(label: lang.t("Speicher frei"), value: diskInfo)
                    infoRow(label: lang.t("Uptime"), value: uptimeText)
                }
            }
            .padding(12)
        }
        .navigationTitle(lang.t("Netzwerk & Info"))
        .onAppear {
            refresh()
            loadHistory()
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title)
            VStack(alignment: .leading, spacing: 6) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func infoRow(label: String, value: String, copyable: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 12).monospacedDigit()).textSelection(.enabled)
            if copyable {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc").font(.system(size: 10))
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help(lang.t("Kopieren"))
            }
        }
    }

    private func refresh() {
        localIPs = Self.collectLocalIPs()
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let free = attrs[.systemFreeSize] as? Int64,
           let total = attrs[.systemSize] as? Int64 {
            let freeText = ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
            let totalText = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            diskInfo = "\(freeText)" + lang.t(" von ") + "\(totalText)"
        }
        let uptime = Int(ProcessInfo.processInfo.systemUptime)
        uptimeText = "\(uptime / 86400) T \(uptime % 86400 / 3600) h \(uptime % 3600 / 60) min"
    }

    private func fetchPublicIP() {
        loadingPublicIP = true
        Task {
            defer { loadingPublicIP = false }
            guard let url = URL(string: "https://api.ipify.org") else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let text = String(data: data, encoding: .utf8) {
                publicIP = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    private func runSpeedtest() {
        runningSpeedtest = true
        speedResult = nil
        Task {
            let result = await Shell.runAsync("/usr/bin/networkQuality", [])
            runningSpeedtest = false
            var down: String?
            var up: String?
            for line in result.output.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("Downlink capacity:") {
                    down = trimmed.replacingOccurrences(of: "Downlink capacity:", with: "").trimmingCharacters(in: .whitespaces)
                }
                if trimmed.hasPrefix("Uplink capacity:") {
                    up = trimmed.replacingOccurrences(of: "Uplink capacity:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
            if let down, let up {
                speedResult = "↓ \(down)   ↑ \(up)"
                history.insert(SpeedtestEntry(date: Date(), down: down, up: up), at: 0)
                if history.count > 5 {
                    history.removeLast(history.count - 5)
                }
                saveHistory()
            } else {
                speedResult = result.status == 0 ? lang.t("Ergebnis nicht lesbar") : lang.t("Test fehlgeschlagen")
            }
        }
    }

    private func loadHistory() {
        guard let data = speedtestHistoryRaw.data(using: .utf8),
              let entries = try? JSONDecoder().decode([SpeedtestEntry].self, from: data) else { return }
        history = entries
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history),
           let text = String(data: data, encoding: .utf8) {
            speedtestHistoryRaw = text
        }
    }

    private static func collectLocalIPs() -> [(name: String, address: String)] {
        var result: [(String, String)] = []
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return [] }
        defer { freeifaddrs(pointer) }
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = current {
            defer { current = ifa.pointee.ifa_next }
            guard let addr = ifa.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: ifa.pointee.ifa_name)
            guard name != "lo0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                result.append((name, String(cString: host)))
            }
        }
        return result
    }
}
