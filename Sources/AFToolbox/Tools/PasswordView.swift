import AppKit
import Security
import SwiftUI

struct PasswordView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var length = 25.0
    @State private var useLowercase = true
    @State private var useUppercase = true
    @State private var useDigits = true
    @State private var useSymbols = true
    @State private var generated = ""
    @State private var copied = false

    private var noOptionActive: Bool {
        !useLowercase && !useUppercase && !useDigits && !useSymbols
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lang.t("Länge: ") + "\(Int(length))")
                    .font(.system(size: 12)).monospacedDigit()
                Slider(value: $length, in: 8...48, step: 1)
            }
            HStack(spacing: 14) {
                Toggle("a–z", isOn: $useLowercase)
                Toggle("A–Z", isOn: $useUppercase)
                Toggle("0–9", isOn: $useDigits)
                Toggle("$ !", isOn: $useSymbols)
            }
            .font(.system(size: 11))
            .toggleStyle(.checkbox)
            if noOptionActive {
                Text(lang.t("Mindestens eine Zeichenart wählen."))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.orange)
            }

            HStack {
                Button(lang.t("Passwort erzeugen")) { generatePassword() }
                    .disabled(noOptionActive)
                Button(lang.t("UUID erzeugen")) {
                    generated = UUID().uuidString
                    copyToClipboard()
                }
            }

            if !generated.isEmpty {
                HStack(spacing: 8) {
                    Text(generated)
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(copied ? "✓" : lang.t("Kopieren")) { copyToClipboard() }
                }
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                Text(lang.t("Wurde automatisch in die Zwischenablage kopiert."))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .navigationTitle(lang.t("Passwörter"))
    }

    private func generatePassword() {
        var charset = ""
        if useLowercase { charset += "abcdefghijklmnopqrstuvwxyz" }
        if useUppercase { charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if useDigits { charset += "0123456789" }
        if useSymbols { charset += "$!" }
        guard !charset.isEmpty else { return }
        let characters = Array(charset)
        var result = ""
        var bytes = [UInt8](repeating: 0, count: Int(length) * 2)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return }
        var index = 0
        while result.count < Int(length) && index < bytes.count {
            // Rejection Sampling, damit die Verteilung gleichmässig bleibt
            let value = Int(bytes[index])
            index += 1
            if value < (256 / characters.count) * characters.count {
                result.append(characters[value % characters.count])
            }
        }
        generated = result
        copyToClipboard()
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generated, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copied = false
        }
    }
}
