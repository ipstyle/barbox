import AudioToolbox
import CoreAudio
import CoreGraphics
import Foundation

#if MAS_BUILD
/// Store-Variante: Für die Helligkeit gibt es kein öffentliches API — der Regler
/// entfällt (current() == nil blendet ihn aus). Lautstärke läuft über CoreAudio
/// statt osascript.
enum Brightness {
    static func current() -> Double? { nil }
    static func set(_ value: Double) {}
}

enum VolumeControl {
    private static var volumeAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)

    static func current() async -> Int? {
        guard let device = AudioDevices.defaultOutput() else { return nil }
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(device, &volumeAddress, 0, nil, &size, &volume) == noErr else {
            return nil
        }
        return Int((volume * 100).rounded())
    }

    static func set(_ value: Int) async {
        guard let device = AudioDevices.defaultOutput() else { return }
        var volume = Float32(min(max(value, 0), 100)) / 100
        AudioObjectSetPropertyData(device, &volumeAddress, 0, nil,
                                   UInt32(MemoryLayout<Float32>.size), &volume)
    }
}
#else
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
#endif
