import AppKit
import CoreWLAN
import Foundation
import IOBluetooth
import IOKit.ps

@MainActor
final class SystemStatusModel: ObservableObject {
    @Published var batteryPercent: Int?
    @Published var batteryCharging = false
    @Published var wifiOn: Bool?
    @Published var bluetoothOn: Bool?
    @Published var airDropMode: String? // "Off", "Contacts Only", "Everyone"
    @Published var busy = false

    private(set) var wifiInterfaceName = "en0"
    let blueutilPath: String? = ["/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }

    private var timer: Timer?

    func startPolling() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        refreshBattery()
        if let interface = CWWiFiClient.shared().interface() {
            wifiInterfaceName = interface.interfaceName ?? "en0"
            wifiOn = interface.powerOn()
        } else {
            wifiOn = nil
        }
        if let controller = IOBluetoothHostController.default() {
            bluetoothOn = controller.powerState == kBluetoothHCIPowerStateON
        } else {
            bluetoothOn = nil
        }
        airDropMode = CFPreferencesCopyAppValue("DiscoverableMode" as CFString,
                                                "com.apple.sharingd" as CFString) as? String
    }

    private func refreshBattery() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            batteryPercent = nil
            return
        }
        for source in list {
            guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                  let current = description[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0 else { continue }
            batteryPercent = Int((Double(current) / Double(maximum) * 100).rounded())
            batteryCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
            return
        }
        batteryPercent = nil
    }

    func setWifi(on: Bool) {
        guard !busy else { return }
        busy = true
        let interface = wifiInterfaceName
        Task {
            _ = await Shell.runAsync("/usr/sbin/networksetup", ["-setairportpower", interface, on ? "on" : "off"])
            try? await Task.sleep(nanoseconds: 600_000_000)
            refresh()
            busy = false
        }
    }

    func setAirDropMode(_ mode: String) {
        guard !busy else { return }
        busy = true
        Task {
            _ = await Shell.runAsync("/usr/bin/defaults", ["write", "com.apple.sharingd", "DiscoverableMode", "-string", mode])
            _ = await Shell.runAsync("/usr/bin/killall", ["sharingd"])
            try? await Task.sleep(nanoseconds: 800_000_000)
            refresh()
            busy = false
        }
    }

    func setBluetooth(on: Bool) {
        guard let blueutil = blueutilPath, !busy else { return }
        busy = true
        Task {
            _ = await Shell.runAsync(blueutil, ["-p", on ? "1" : "0"])
            try? await Task.sleep(nanoseconds: 600_000_000)
            refresh()
            busy = false
        }
    }
}
