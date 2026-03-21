import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let minMaxItems = 50
    public static let maxMaxItems = 500

    public var hotkey: Hotkey
    public var maxItems: Int
    public var launchAtLogin: Bool

    public init(hotkey: Hotkey = .defaultHotkey, maxItems: Int = 200, launchAtLogin: Bool = true) {
        self.hotkey = hotkey
        self.maxItems = Self.clampedMaxItems(maxItems)
        self.launchAtLogin = launchAtLogin
    }

    public static func clampedMaxItems(_ value: Int) -> Int {
        min(max(value, minMaxItems), maxMaxItems)
    }
}
