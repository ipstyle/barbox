import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class TimerManager: ObservableObject {
    @Published private(set) var endDate: Date?
    @Published private(set) var remaining: TimeInterval = 0

    private var ticker: Timer?
    private let notificationID = "barbox.timer"

    var isRunning: Bool { endDate != nil }

    func start(minutes: Int) {
        cancel()
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        endDate = end
        remaining = end.timeIntervalSinceNow
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        scheduleNotification(minutes: minutes)
    }

    func cancel() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
        remaining = 0
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            ticker?.invalidate()
            ticker = nil
            self.endDate = nil
        }
    }

    private func scheduleNotification(minutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = LanguageStore.current("Timer abgelaufen")
            content.body = "\(minutes)" + LanguageStore.current(" Minuten sind um.")
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
            center.add(UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger))
        }
    }
}

struct TimerView: View {
    @EnvironmentObject private var timerManager: TimerManager
    @EnvironmentObject private var lang: LanguageStore
    @State private var customMinutes = 10

    var body: some View {
        VStack(spacing: 16) {
            if timerManager.isRunning {
                Text(formatted(timerManager.remaining))
                    .font(.system(size: 44, weight: .light).monospacedDigit())
                Button(lang.t("Abbrechen")) { timerManager.cancel() }
            } else {
                Text(lang.t("Schnell-Timer mit Mitteilung am Ende"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach([5, 15, 25, 60], id: \.self) { minutes in
                        Button("\(minutes) min") { timerManager.start(minutes: minutes) }
                    }
                }
                HStack(spacing: 8) {
                    Stepper(lang.t("Eigene Dauer: ") + "\(customMinutes) min", value: $customMinutes, in: 1...240)
                        .font(.system(size: 12))
                    Button(lang.t("Start")) { timerManager.start(minutes: customMinutes) }
                }
            }
            Spacer()
        }
        .padding(16)
        .navigationTitle(lang.t("Timer"))
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
