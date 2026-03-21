import Foundation

public struct Hotkey: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    public static let defaultHotkey = Hotkey(keyCode: 9, carbonModifiers: 768)
}
