import ClipboardCore
import Foundation

enum HotkeyFormatter {
    static let commandMask: UInt32 = 1 << 8
    static let shiftMask: UInt32 = 1 << 9
    static let optionMask: UInt32 = 1 << 11
    static let controlMask: UInt32 = 1 << 12

    static let keyOptions: [(name: String, keyCode: UInt32)] = [
        ("A", 0), ("S", 1), ("D", 2), ("F", 3), ("H", 4), ("G", 5),
        ("Z", 6), ("X", 7), ("C", 8), ("V", 9), ("B", 11), ("Q", 12),
        ("W", 13), ("E", 14), ("R", 15), ("Y", 16), ("T", 17), ("1", 18),
        ("2", 19), ("3", 20), ("4", 21), ("6", 22), ("5", 23), ("=", 24),
        ("9", 25), ("7", 26), ("-", 27), ("8", 28), ("0", 29), ("]", 30),
        ("O", 31), ("U", 32), ("[", 33), ("I", 34), ("P", 35), ("L", 37),
        ("J", 38), ("K", 40), (";", 41), ("\\", 42), (",", 43), ("/", 44),
        ("N", 45), ("M", 46), (".", 47), ("`", 50)
    ]

    static func display(_ hotkey: Hotkey) -> String {
        var prefix = ""
        if includesCommand(hotkey) { prefix += "⌘" }
        if includesShift(hotkey) { prefix += "⇧" }
        if includesOption(hotkey) { prefix += "⌥" }
        if includesControl(hotkey) { prefix += "⌃" }

        let keyName = keyOptions.first(where: { $0.keyCode == hotkey.keyCode })?.name ?? "KeyCode(\(hotkey.keyCode))"
        return prefix + keyName
    }

    static func includesCommand(_ hotkey: Hotkey) -> Bool {
        hotkey.carbonModifiers & commandMask != 0
    }

    static func includesShift(_ hotkey: Hotkey) -> Bool {
        hotkey.carbonModifiers & shiftMask != 0
    }

    static func includesOption(_ hotkey: Hotkey) -> Bool {
        hotkey.carbonModifiers & optionMask != 0
    }

    static func includesControl(_ hotkey: Hotkey) -> Bool {
        hotkey.carbonModifiers & controlMask != 0
    }

    static func updating(
        _ hotkey: Hotkey,
        keyCode: UInt32? = nil,
        command: Bool? = nil,
        shift: Bool? = nil,
        option: Bool? = nil,
        control: Bool? = nil
    ) -> Hotkey {
        var modifiers = hotkey.carbonModifiers

        if let command {
            modifiers = command ? (modifiers | commandMask) : (modifiers & ~commandMask)
        }
        if let shift {
            modifiers = shift ? (modifiers | shiftMask) : (modifiers & ~shiftMask)
        }
        if let option {
            modifiers = option ? (modifiers | optionMask) : (modifiers & ~optionMask)
        }
        if let control {
            modifiers = control ? (modifiers | controlMask) : (modifiers & ~controlMask)
        }

        return Hotkey(keyCode: keyCode ?? hotkey.keyCode, carbonModifiers: modifiers)
    }

    static func hasAnyModifier(_ hotkey: Hotkey) -> Bool {
        includesCommand(hotkey) || includesShift(hotkey) || includesOption(hotkey) || includesControl(hotkey)
    }
}
