// Erzeugt Resources/AppIcon.icns: BarBox-Motiv «Balken über Box» —
// weisser Menübalken über offener weisser Box auf blauem Squircle (Konzept A).
// Aufruf: swift scripts/make_icon.swift <Zielordner>
import AppKit
import Foundation

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"
let iconsetDir = outDir + "/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let blue = NSColor(calibratedRed: 0.18, green: 0.42, blue: 0.90, alpha: 1) // #2E6BE6
let blueTop = NSColor(calibratedRed: 0.24, green: 0.48, blue: 0.94, alpha: 1)
let blueBottom = NSColor(calibratedRed: 0.14, green: 0.34, blue: 0.78, alpha: 1)

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
    let w = rect.width

    // Hilfsfunktionen: Bruchteile des Inhaltsquadrats (x von links, y von unten)
    func fx(_ f: CGFloat) -> CGFloat { rect.minX + f * w }
    func fy(_ f: CGFloat) -> CGFloat { rect.minY + f * w }
    func frect(_ x: CGFloat, _ y: CGFloat, _ fw: CGFloat, _ fh: CGFloat) -> NSRect {
        NSRect(x: fx(x), y: fy(y), width: fw * w, height: fh * w)
    }

    // Blaues Squircle mit sanftem Verlauf
    let radius = w * 0.225
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGradient(starting: blueTop, ending: blueBottom)!.draw(in: squircle, angle: -90)

    // Menübalken (weiss) mit Menü-Pille und zwei Status-Punkten (blau)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: frect(0.157, 0.729, 0.686, 0.114),
                 xRadius: 0.057 * w, yRadius: 0.057 * w).fill()
    blue.setFill()
    NSBezierPath(roundedRect: frect(0.20, 0.762, 0.171, 0.046),
                 xRadius: 0.023 * w, yRadius: 0.023 * w).fill()
    for cx in [0.686, 0.764] {
        NSBezierPath(ovalIn: frect(CGFloat(cx) - 0.023, 0.763, 0.046, 0.046)).fill()
    }

    // Offene Box: Deckel-Trapez + Korpus (weiss)
    NSColor.white.setFill()
    let lid = NSBezierPath()
    lid.move(to: NSPoint(x: fx(0.250), y: fy(0.514)))
    lid.line(to: NSPoint(x: fx(0.750), y: fy(0.514)))
    lid.line(to: NSPoint(x: fx(0.793), y: fy(0.414)))
    lid.line(to: NSPoint(x: fx(0.207), y: fy(0.414)))
    lid.close()
    lid.fill()
    NSBezierPath(roundedRect: frect(0.25, 0.143, 0.50, 0.28),
                 xRadius: 0.043 * w, yRadius: 0.043 * w).fill()

    // Blaue Details: Lasche und zwei Inhaltszeilen
    blue.setFill()
    NSBezierPath(roundedRect: frect(0.343, 0.386, 0.314, 0.062),
                 xRadius: 0.028 * w, yRadius: 0.028 * w).fill()
    NSBezierPath(roundedRect: frect(0.336, 0.310, 0.328, 0.036),
                 xRadius: 0.018 * w, yRadius: 0.018 * w).fill()
    blue.withAlphaComponent(0.5).setFill()
    NSBezierPath(roundedRect: frect(0.336, 0.232, 0.214, 0.036),
                 xRadius: 0.018 * w, yRadius: 0.018 * w).fill()

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
