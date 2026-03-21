import AppKit
import Foundation

final class HistoryPanel: NSPanel {
    var keyDownHandler: ((NSEvent) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        keyDownHandler?(event)
    }
}
