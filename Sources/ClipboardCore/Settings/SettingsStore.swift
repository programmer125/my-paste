import Foundation

public final class SettingsStore: @unchecked Sendable {
    public enum Keys {
        public static let appSettings = "clipboardmenu.appsettings"
    }

    private var settings: AppSettings

    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "clipboardmenu.settings", qos: .userInitiated)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.appSettings),
           let decoded = try? decoder.decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }

    public func updateHotkey(_ hotkey: Hotkey) {
        queue.sync {
            settings.hotkey = hotkey
            persist()
        }
    }

    public func updateMaxItems(_ maxItems: Int) {
        queue.sync {
            settings.maxItems = AppSettings.clampedMaxItems(maxItems)
            persist()
        }
    }

    public func updateLaunchAtLogin(_ enabled: Bool) {
        queue.sync {
            settings.launchAtLogin = enabled
            persist()
        }
    }

    public func reload() {
        queue.sync {
            if let data = defaults.data(forKey: Keys.appSettings),
               let decoded = try? decoder.decode(AppSettings.self, from: data) {
                settings = decoded
            }
        }
    }

    public func currentSettings() -> AppSettings {
        queue.sync { settings }
    }

    private func persist() {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: Keys.appSettings)
        }
    }
}
