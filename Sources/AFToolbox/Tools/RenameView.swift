import AppKit
import SwiftUI

struct RenameView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var files: [URL] = []
    @AppStorage("renamePattern") private var pattern = "{name}-{nr}"
    @AppStorage("renameDigits") private var digits = 2
    @State private var startNumber = 1
    @State private var dropHover = false
    @State private var resultText: String?
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            dropZone

            VStack(alignment: .leading, spacing: 6) {
                TextField(lang.t("Muster, z. B. {name}-{nr}"), text: $pattern)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 12) {
                    Stepper(lang.t("Start: ") + "\(startNumber)", value: $startNumber, in: 0...999)
                    Stepper(lang.t("Stellen: ") + "\(digits)", value: $digits, in: 1...4)
                }
                .font(.system(size: 11))
                Text(lang.t("Platzhalter: {name} = Originalname · {nr} = Laufnummer · {datum} = Dateidatum (JJJJ-MM-TT). Endung bleibt erhalten."))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            if !files.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.t("Vorschau:"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    ForEach(Array(files.prefix(3).enumerated()), id: \.element) { index, url in
                        Text("\(url.lastPathComponent)  →  \(newName(for: url, number: startNumber + index))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if files.count > 3 {
                        Text(String(format: lang.t("… und %d weitere"), files.count - 3))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button(String(format: lang.t("Umbenennen (%d Dateien)"), files.count)) { rename() }
                        .disabled(pattern.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(lang.t("Liste leeren")) { files.removeAll(); resultText = nil; errorText = nil }
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
        .navigationTitle(lang.t("Umbenennen"))
    }

    private var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "pencil.line")
                .font(.system(size: 24))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary)
            Text(lang.t("Dateien hierhin ziehen"))
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(dropHover ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(dropHover ? Color.accentColor : Color.secondary.opacity(0.35))
        )
        .dropDestination(for: URL.self) { urls, _ in
            for url in urls where !files.contains(url) && !url.hasDirectoryPath {
                files.append(url)
            }
            files.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            return true
        } isTargeted: { dropHover = $0 }
    }

    /// Wendet das Muster auf eine Datei an — Platzhalter {name}, {nr}, {datum}
    private func newName(for url: URL, number: Int) -> String {
        var name = pattern
        name = name.replacingOccurrences(of: "{name}",
                                         with: url.deletingPathExtension().lastPathComponent)
        name = name.replacingOccurrences(of: "{nr}",
                                         with: String(format: "%0\(digits)d", number))
        if name.contains("{datum}") {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let date = (attributes?[.creationDate] as? Date) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            name = name.replacingOccurrences(of: "{datum}", with: formatter.string(from: date))
        }
        let ext = url.pathExtension
        return ext.isEmpty ? name : "\(name).\(ext)"
    }

    private func rename() {
        errorText = nil
        var renamed = 0
        var skipped = 0
        var number = startNumber
        var newFiles: [URL] = []
        for url in files {
            let target = url.deletingLastPathComponent().appendingPathComponent(newName(for: url, number: number))
            number += 1
            if target == url {
                newFiles.append(url)
                continue
            }
            if FileManager.default.fileExists(atPath: target.path) {
                skipped += 1
                newFiles.append(url)
                continue
            }
            do {
                try FileManager.default.moveItem(at: url, to: target)
                renamed += 1
                newFiles.append(target)
            } catch {
                skipped += 1
                newFiles.append(url)
            }
        }
        files = newFiles
        resultText = "\(renamed)" + lang.t(" umbenannt") + (skipped > 0 ? ", \(skipped)" + lang.t(" übersprungen (Ziel existiert)") : "")
    }
}
