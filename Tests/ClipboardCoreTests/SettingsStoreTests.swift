import ClipboardCore
import Foundation

#if canImport(XCTest)
import XCTest

final class SettingsStoreTests: XCTestCase {
    func testUpdateMaxItemsShouldClampValue() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.updateMaxItems(9999)
        XCTAssertEqual(store.currentSettings().maxItems, AppSettings.maxMaxItems)

        store.updateMaxItems(1)
        XCTAssertEqual(store.currentSettings().maxItems, AppSettings.minMaxItems)
    }

    func testUpdateValuesShouldPersist() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var store: SettingsStore? = SettingsStore(defaults: defaults)
        store?.updateMaxItems(260)
        store?.updateLaunchAtLogin(false)
        store?.updateHotkey(Hotkey(keyCode: 8, carbonModifiers: 256))

        store = nil

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.currentSettings().maxItems, 260)
        XCTAssertEqual(reloaded.currentSettings().launchAtLogin, false)
        XCTAssertEqual(reloaded.currentSettings().hotkey, Hotkey(keyCode: 8, carbonModifiers: 256))
    }
}
#else
struct SettingsStoreTestsUnavailable {}
#endif
