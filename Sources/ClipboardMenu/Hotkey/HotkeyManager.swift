import Carbon
import ClipboardCore
import Foundation

final class HotkeyManager {
    enum HotkeyError: LocalizedError {
        case registrationFailed(OSStatus)
        case eventHandlerFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .registrationFailed(let status):
                if status == eventHotKeyExistsErr {
                    return "全局快捷键已被其他应用占用，请在设置中更换。"
                }
                return "注册全局快捷键失败 (\(status))。"
            case .eventHandlerFailed(let status):
                return "安装快捷键事件处理器失败 (\(status))。"
            }
        }
    }

    typealias Handler = () -> Void

    private final class WeakBox {
        weak var value: HotkeyManager?

        init(_ value: HotkeyManager) {
            self.value = value
        }
    }

    private static let signature: OSType = 0x434C504D // CLPM
    nonisolated(unsafe) private static var managers: [UInt32: WeakBox] = [:]
    nonisolated(unsafe) private static var eventHandlerRef: EventHandlerRef?

    private var hotkeyRef: EventHotKeyRef?
    private var hotkeyID = EventHotKeyID(signature: signature, id: 0)

    var onHotkey: Handler?

    func register(_ hotkey: Hotkey) throws {
        try Self.ensureEventHandlerInstalled()

        unregister()

        let id = UInt32(truncatingIfNeeded: ObjectIdentifier(self).hashValue)
        hotkeyID = EventHotKeyID(signature: Self.signature, id: id)

        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        guard status == noErr else {
            throw HotkeyError.registrationFailed(status)
        }

        Self.managers[id] = WeakBox(self)
    }

    func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        Self.managers[hotkeyID.id] = nil
    }

    private static func ensureEventHandlerInstalled() throws {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, _ in
                guard let eventRef else { return noErr }
                return HotkeyManager.handleHotkeyEvent(eventRef)
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        guard status == noErr else {
            throw HotkeyError.eventHandlerFailed(status)
        }
    }

    private static func handleHotkeyEvent(_ event: EventRef) -> OSStatus {
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else { return status }

        if let manager = managers[hotkeyID.id]?.value {
            manager.onHotkey?()
            return noErr
        }

        return OSStatus(eventNotHandledErr)
    }
}
