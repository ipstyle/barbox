import AppKit
import CoreImage
import SwiftUI

struct QRCodeView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var input = ""
    @State private var image: NSImage?
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(lang.t("Text oder URL…"), text: $input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .onChange(of: input) { _, _ in generate() }
            HStack {
                Button(lang.t("Aus Zwischenablage")) {
                    if let text = NSPasteboard.general.string(forType: .string) {
                        input = text
                    }
                }
                Spacer()
            }
            if let image {
                VStack(spacing: 8) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    HStack {
                        Button(copied ? lang.t("Kopiert ✓") : lang.t("Bild kopieren")) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([image])
                            copied = true
                        }
                        Button(lang.t("Sichern…")) { save() }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .navigationTitle(lang.t("QR-Code"))
    }

    private func generate() {
        copied = false
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            image = nil
            return
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)) else {
            image = nil
            return
        }
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        image = nsImage
    }

    private func save() {
        guard let image, let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "QR-Code.png"
        NSApplication.shared.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            try? png.write(to: url)
        }
    }
}
