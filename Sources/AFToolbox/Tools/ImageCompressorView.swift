import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ImageCompressorView: View {
    @EnvironmentObject private var lang: LanguageStore
    @AppStorage("aiEdge") private var aiEdge = 1568
    @AppStorage("aiQuality") private var aiQuality = 0.80
    @AppStorage("halfQuality") private var halfQuality = 0.85
    @AppStorage("outputSuffix") private var outputSuffix = "-klein"

    @State private var preset = 0
    @State private var results: [CompressionResult] = []
    @State private var working = false
    @State private var dropHover = false

    private var mode: ImageCompressor.Mode { preset == 0 ? .maxEdge(aiEdge) : .scale(0.5) }
    private var quality: Double { preset == 0 ? aiQuality : halfQuality }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $preset) {
                Text(lang.t("Für AI · ") + "\(aiEdge) px").tag(0)
                Text(lang.t("Halb so gross · 50 %")).tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            dropZone

            HStack {
                Button(lang.t("Bilder auswählen…")) { pickFiles() }
                    .disabled(working)
                if working { ProgressView().controlSize(.small) }
                Spacer()
                if !results.isEmpty {
                    Button(lang.t("Liste leeren")) { results.removeAll() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if results.isEmpty {
                Text(String(format: lang.t("Ausgabe: gleicher Ordner, Endung «%@.jpg». Presets in den Einstellungen anpassbar."), outputSuffix))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(results) { result in
                            resultRow(result)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .navigationTitle(lang.t("Bilder komprimieren"))
    }

    private var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo.badge.arrow.down")
                .font(.system(size: 26))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary)
            Text(lang.t("Bilder hierhin ziehen"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(lang.t("JPEG, PNG, HEIC, TIFF …"))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.primary.opacity(dropHover ? 0.10 : 0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary.opacity(0.35))
        )
        .dropDestination(for: URL.self) { urls, _ in
            process(urls)
            return true
        } isTargeted: { hovering in
            dropHover = hovering
        }
    }

    private func resultRow(_ result: CompressionResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.errorText == nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(result.errorText == nil ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 1) {
                Text(result.sourceName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                if let error = result.errorText {
                    Text(lang.t(error))
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                } else {
                    Text("\(format(result.originalBytes)) → \(format(result.newBytes)) · −\(result.savedPercent) %")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let output = result.outputURL {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([output])
                } label: {
                    Image(systemName: "magnifyingglass.circle").font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(lang.t("Im Finder zeigen"))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    private func format(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.prompt = lang.t("Komprimieren")
        NSApplication.shared.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK {
            process(panel.urls)
        }
    }

    private func process(_ urls: [URL]) {
        let images = urls.filter { ImageCompressor.imageExtensions.contains($0.pathExtension.lowercased()) }
        guard !images.isEmpty, !working else { return }
        working = true
        let mode = mode
        let q = quality
        let suffix = outputSuffix
        Task {
            let newResults = await Task.detached {
                images.map { ImageCompressor.compress(url: $0, mode: mode, quality: q, suffix: suffix) }
            }.value
            results.insert(contentsOf: newResults, at: 0)
            working = false
        }
    }
}
