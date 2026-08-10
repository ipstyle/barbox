import AppKit
import PDFKit
import SwiftUI

struct PDFMergeView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var files: [URL] = []
    @State private var dropHover = false
    @State private var resultText: String?
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            dropZone
            if !files.isEmpty {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(files.enumerated()), id: \.element) { index, url in
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                                Text(url.lastPathComponent)
                                    .font(.system(size: 11)).lineLimit(1)
                                Spacer()
                                Button {
                                    if index > 0 { files.swapAt(index, index - 1) }
                                } label: { Image(systemName: "arrow.up") }
                                    .buttonStyle(.plain).disabled(index == 0)
                                Button {
                                    files.removeAll { $0 == url }
                                } label: { Image(systemName: "xmark.circle") }
                                    .buttonStyle(.plain).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 180)
                HStack {
                    Button(String(format: lang.t("Zusammenfügen (%d PDFs)"), files.count)) { merge() }
                        .disabled(files.count < 2)
                    Button(lang.t("Liste leeren")) { files.removeAll(); resultText = nil }
                        .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            if let resultText {
                Label(resultText, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11)).foregroundStyle(Theme.green)
            }
            if let errorText {
                Text(errorText).font(.system(size: 11)).foregroundStyle(Theme.red)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .navigationTitle(lang.t("PDF zusammenfügen"))
    }

    private var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 24))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary)
            Text(lang.t("PDFs hierhin ziehen — Reihenfolge unten anpassen"))
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(dropHover ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary.opacity(0.35))
        )
        .dropDestination(for: URL.self) { urls, _ in
            let pdfs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
            for pdf in pdfs where !files.contains(pdf) {
                files.append(pdf)
            }
            return !pdfs.isEmpty
        } isTargeted: { dropHover = $0 }
    }

    private func merge() {
        errorText = nil
        let output = PDFDocument()
        for url in files {
            guard let doc = PDFDocument(url: url) else {
                errorText = String(format: lang.t("«%@» konnte nicht gelesen werden."), url.lastPathComponent)
                return
            }
            for pageIndex in 0..<doc.pageCount {
                if let page = doc.page(at: pageIndex) {
                    output.insert(page, at: output.pageCount)
                }
            }
        }
        let directory = files[0].deletingLastPathComponent()
        var destination = directory.appendingPathComponent("Zusammengefuegt.pdf")
        var counter = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = directory.appendingPathComponent("Zusammengefuegt-\(counter).pdf")
            counter += 1
        }
        if output.write(to: destination) {
            resultText = lang.t("Gespeichert") + ": \(destination.lastPathComponent) (\(output.pageCount) Seiten)"
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } else {
            errorText = lang.t("Speichern fehlgeschlagen.")
        }
    }
}
