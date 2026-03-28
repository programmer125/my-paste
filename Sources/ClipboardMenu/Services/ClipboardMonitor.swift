import AppKit
import Foundation

@MainActor
final class ClipboardMonitor {
    typealias ChangeHandler = (String) -> Void

    private let activeInterval: TimeInterval
    private let idleInterval: TimeInterval
    private let idleThreshold: TimeInterval
    private let leeway: DispatchTimeInterval
    var onChange: ChangeHandler?
    private let pasteboard = NSPasteboard.general

    private var timer: DispatchSourceTimer?
    private var lastChangeCount: Int
    private var lastActivityAt = Date()
    private var scheduledInterval: TimeInterval?

    init(
        activeInterval: TimeInterval = 0.25,
        idleInterval: TimeInterval = 1.0,
        idleThreshold: TimeInterval = 8.0,
        leeway: DispatchTimeInterval = .milliseconds(200)
    ) {
        self.activeInterval = activeInterval
        self.idleInterval = idleInterval
        self.idleThreshold = idleThreshold
        self.leeway = leeway
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            pokeActivity()
            return
        }

        lastChangeCount = pasteboard.changeCount
        lastActivityAt = Date()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in
            self?.pollPasteboard()
        }
        self.timer = timer
        scheduleTimer(interval: activeInterval)
        timer.resume()
    }

    func stop() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
        scheduledInterval = nil
    }

    func pokeActivity() {
        lastActivityAt = Date()
        scheduleTimer(interval: activeInterval)
    }

    private func pollPasteboard() {
        refreshTimerScheduleIfNeeded()

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        lastActivityAt = Date()
        scheduleTimer(interval: activeInterval)

        guard let text = pasteboard.string(forType: .string) else { return }
        onChange?(text)
    }

    private func refreshTimerScheduleIfNeeded() {
        let nextInterval = Date().timeIntervalSince(lastActivityAt) >= idleThreshold
            ? idleInterval
            : activeInterval
        scheduleTimer(interval: nextInterval)
    }

    private func scheduleTimer(interval: TimeInterval) {
        guard let timer, scheduledInterval != interval else { return }

        scheduledInterval = interval
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: leeway)
    }
}
