import AppKit
import SwiftUI
import Vision

struct OCRView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var recognizedText = ""
    @State private var working = false
    @State private var dropHover = false
    @State private var copied = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            dropZone
            if working { ProgressView().controlSize(.small) }
            if let errorText {
                Text(errorText).font(.system(size: 11)).foregroundStyle(Theme.red)
            }
            if !recognizedText.isEmpty {
                HStack {
                    Text(lang.t("Erkannter Text (bereits in der Zwischenablage)"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(copied ? lang.t("Kopiert ✓") : lang.t("Nochmals kopieren")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(recognizedText, forType: .string)
                        copied = true
                    }
                    .font(.system(size: 11))
                }
                ScrollView {
                    Text(recognizedText)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .navigationTitle(lang.t("Text aus Bild"))
    }

    private var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 26))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary)
            Text(lang.t("Bild oder Screenshot hierhin ziehen"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(lang.t("Text wird erkannt und automatisch kopiert (offline, Apple Vision)"))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color.white.opacity(dropHover ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary.opacity(0.35))
        )
        .dropDestination(for: URL.self) { urls, _ in
            if let url = urls.first {
                recognize(url)
                return true
            }
            return false
        } isTargeted: { dropHover = $0 }
    }

    private func recognize(_ url: URL) {
        working = true
        errorText = nil
        copied = false
        Task {
            let text: String? = await Task.detached {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["de-DE", "en-US", "fr-FR", "it-IT"]
                let handler = VNImageRequestHandler(url: url)
                guard (try? handler.perform([request])) != nil else { return nil }
                let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                return lines.joined(separator: "\n")
            }.value
            working = false
            guard let text, !text.isEmpty else {
                errorText = lang.t("Kein Text erkannt.")
                return
            }
            recognizedText = text
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }
}
