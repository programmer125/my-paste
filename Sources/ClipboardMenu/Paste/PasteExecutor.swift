import AppKit
import Foundation

protocol PasteExecutor {
    func copy(text: String) throws
}

enum PasteError: LocalizedError {
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .copyFailed:
            return "复制到剪贴板失败。"
        }
    }
}

final class DefaultPasteExecutor: PasteExecutor {
    func copy(text: String) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if !pasteboard.setString(text, forType: .string) {
            throw PasteError.copyFailed
        }
    }
}
