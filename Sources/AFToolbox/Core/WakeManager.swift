import Foundation
import IOKit.pwr_mgt

@MainActor
final class WakeManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var until: Date?

    private var assertionID: IOPMAssertionID = 0
    private var expiryTimer: Timer?

    func toggle() {
        if isActive { stop() } else { start(minutes: nil) }
    }

    func start(minutes: Int?) {
        stop()
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "AF-Toolbox: Mac wach halten" as CFString,
            &id
        )
        guard result == kIOReturnSuccess else { return }
        assertionID = id
        isActive = true
        if let minutes {
            until = Date().addingTimeInterval(TimeInterval(minutes * 60))
            expiryTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        } else {
            until = nil
        }
    }

    func stop() {
        if isActive {
            IOPMAssertionRelease(assertionID)
        }
        isActive = false
        until = nil
        expiryTimer?.invalidate()
        expiryTimer = nil
    }
}
