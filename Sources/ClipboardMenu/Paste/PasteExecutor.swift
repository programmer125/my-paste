import AppKit
import ApplicationServices
import Foundation

protocol PasteExecutor {
    func paste(text: String) throws
}

enum PasteError: LocalizedError {
    case accessibilityPermissionRequired
    case eventCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "需要无障碍权限后才能自动执行粘贴。"
        case .eventCreationFailed:
            return "系统粘贴事件创建失败。"
        }
    }
}

final class DefaultPasteExecutor: PasteExecutor {
    func paste(text: String) throws {
        guard AXIsProcessTrusted() else {
            throw PasteError.accessibilityPermissionRequired
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            throw PasteError.eventCreationFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
