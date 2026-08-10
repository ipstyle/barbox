import Foundation
import IOKit

/// CPU-, GPU- und RAM-Auslastung für die Menüleisten-Anzeige und die Info-Ansicht.
@MainActor
final class StatsModel: ObservableObject {
    @Published var cpu: Int = 0
    @Published var gpu: Int?
    @Published var mem: Int = 0

    private var previousLoad = host_cpu_load_info_data_t()
    private var timer: Timer?

    var menuTitle: String {
        var parts = ["C\(cpu)", ]
        if let gpu { parts.append("G\(gpu)") }
        parts.append("M\(mem)")
        return "AF-T " + parts.joined(separator: " ")
    }

    init() {
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
    }

    func sample() {
        sampleCPU()
        gpu = Self.gpuUsage()
        mem = Self.memoryUsage()
    }

    private func sampleCPU() {
        var load = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let user = Double(load.cpu_ticks.0 &- previousLoad.cpu_ticks.0)
        let system = Double(load.cpu_ticks.1 &- previousLoad.cpu_ticks.1)
        let idle = Double(load.cpu_ticks.2 &- previousLoad.cpu_ticks.2)
        let nice = Double(load.cpu_ticks.3 &- previousLoad.cpu_ticks.3)
        previousLoad = load
        let total = user + system + idle + nice
        guard total > 0 else { return }
        cpu = Int(((user + system + nice) / total * 100).rounded())
    }

    private static func gpuUsage() -> Int? {
        var iterator = io_iterator_t()
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            let ok = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS
            IOObjectRelease(entry)
            if ok,
               let dict = properties?.takeRetainedValue() as? [String: Any],
               let performance = dict["PerformanceStatistics"] as? [String: Any],
               let utilization = performance["Device Utilization %"] as? Int {
                return utilization
            }
            entry = IOIteratorNext(iterator)
        }
        return nil
    }

    private static func memoryUsage() -> Int {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let used = (UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * UInt64(pageSize)
        let total = ProcessInfo.processInfo.physicalMemory
        guard total > 0 else { return 0 }
        return Int((Double(used) / Double(total) * 100).rounded())
    }
}
