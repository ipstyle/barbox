// Erzeugt Resources/AppIcon.icns: Drehschlüssel auf dunklem, abgerundetem Hintergrund.
// Aufruf: swift scripts/make_icon.swift <Zielordner>
import AppKit
import Foundation

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"
let iconsetDir = outDir + "/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

func renderIcon(px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(px)
    // macOS-Icons haben Rand: Inhalt auf ~82 % der Kachel
    let inset = s * 0.09
    let rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(starting: NSColor(calibratedRed: 0.28, green: 0.32, blue: 0.40, alpha: 1),
                              ending: NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.19, alpha: 1))!
    gradient.draw(in: path, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "wrench.adjustable", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symSize = symbol.size
        let scale = (rect.width * 0.58) / max(symSize.width, symSize.height)
        let drawSize = NSSize(width: symSize.width * scale, height: symSize.height * scale)
        let drawRect = NSRect(x: rect.midX - drawSize.width / 2,
                              y: rect.midY - drawSize.height / 2,
                              width: drawSize.width, height: drawSize.height)
        // Symbol weiss einfärben
        let tinted = NSImage(size: drawSize)
        tinted.lockFocus()
        symbol.draw(in: NSRect(origin: .zero, size: drawSize))
        NSColor.white.set()
        NSRect(origin: .zero, size: drawSize).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: drawRect)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let variants: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

for (px, name) in variants {
    let rep = renderIcon(px: px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name).png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", outDir + "/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(atPath: iconsetDir)
print(task.terminationStatus == 0 ? "AppIcon.icns erzeugt" : "iconutil fehlgeschlagen")
