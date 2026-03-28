import AppKit
import Foundation

final class HistoryPanel: NSPanel {
    var keyDownHandler: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        guard keyDownHandler?(event) == true else {
            super.keyDown(with: event)
            return
        }
    }
}
