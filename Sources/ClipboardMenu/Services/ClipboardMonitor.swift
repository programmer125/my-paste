import AppKit
import Foundation

final class ClipboardMonitor: @unchecked Sendable {
    typealias ChangeHandler = (String) -> Void

    private let interval: TimeInterval
    var onChange: ChangeHandler?
    private let pasteboard = NSPasteboard.general

    private var timer: Timer?
    private var lastChangeCount: Int

    init(interval: TimeInterval = 0.3) {
        self.interval = interval
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }

        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pollPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let text = pasteboard.string(forType: .string) else { return }
        onChange?(text)
    }
}
