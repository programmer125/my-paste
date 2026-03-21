import AppKit
import ApplicationServices
import Foundation

@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    @Published private(set) var isTrusted = AXIsProcessTrusted()

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    func request() {
        let options = ["AXTrustedCheckOptionPrompt" as CFString: kCFBooleanTrue as CFBoolean] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.refresh()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
