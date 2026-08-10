import CoreGraphics
import Foundation

/// Display-Helligkeit über das private DisplayServices-Framework (per dlsym,
/// kein Linken nötig). Externe Displays unterstützen das oft nicht — dann nil.
enum Brightness {
    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let functions: (get: GetFn, set: SetFn)? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW),
              let getSym = dlsym(handle, "DisplayServicesGetBrightness"),
              let setSym = dlsym(handle, "DisplayServicesSetBrightness") else { return nil }
        return (unsafeBitCast(getSym, to: GetFn.self), unsafeBitCast(setSym, to: SetFn.self))
    }()

    static func current() -> Double? {
        guard let functions else { return nil }
        var value: Float = 0
        guard functions.get(CGMainDisplayID(), &value) == 0 else { return nil }
        return Double(value)
    }

    static func set(_ value: Double) {
        _ = functions?.set(CGMainDisplayID(), Float(min(max(value, 0), 1)))
    }
}

/// Systemlautstärke über osascript — braucht keine Freigabe.
enum VolumeControl {
    static func current() async -> Int? {
        let result = await Shell.runAsync("/usr/bin/osascript", ["-e", "output volume of (get volume settings)"])
        return Int(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func set(_ value: Int) async {
        _ = await Shell.runAsync("/usr/bin/osascript", ["-e", "set volume output volume \(min(max(value, 0), 100))"])
    }
}
