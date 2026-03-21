import AppKit
import ClipboardCore
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var historyItems: [ClipboardItem] = []
    @Published private(set) var settings: AppSettings
    @Published var errorMessage: String?

    let permissionManager = AccessibilityPermissionManager()

    private let settingsStore: SettingsStore
    private let historyStore: FileHistoryStore
    private let clipboardMonitor: ClipboardMonitor
    private let hotkeyManager = HotkeyManager()
    private let popupController: PopupController
    private let launchAtLoginManager = LaunchAtLoginManager()

    private var started = false

    private init() {
        let settingsStore = SettingsStore()
        self.settingsStore = settingsStore
        self.settings = settingsStore.currentSettings()

        let historyFileURL = Self.historyFileURL()
        self.historyStore = FileHistoryStore(
            fileURL: historyFileURL,
            maxItemsProvider: { settingsStore.currentSettings().maxItems }
        )

        self.clipboardMonitor = ClipboardMonitor()
        let historyStore = self.historyStore

        self.popupController = PopupController(
            caretLocator: AccessibilityCaretLocator(),
            pasteExecutor: DefaultPasteExecutor(),
            historyProvider: { [weak historyStore] in
                return historyStore?.items() ?? []
            },
            onError: { _ in }
        )

        self.clipboardMonitor.onChange = { [weak self] text in
            self?.historyStore.add(text)
            self?.reloadHistory()
        }

        self.popupController.onError = { [weak self] message in
            self?.errorMessage = message
        }

        _ = historyStore.load()
        self.historyItems = historyStore.items()

        hotkeyManager.onHotkey = { [weak self] in
            self?.showHistoryPopup()
        }
    }

    func start() {
        guard !started else { return }
        started = true

        permissionManager.refresh()
        reloadHistory()
        registerHotkey()
        applyLaunchAtLogin(settings.launchAtLogin)
        clipboardMonitor.start()
    }

    func stop() {
        clipboardMonitor.stop()
        hotkeyManager.unregister()
        started = false
    }

    func showHistoryPopup() {
        popupController.show()
    }

    func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func updateHotkey(_ hotkey: Hotkey) {
        guard HotkeyFormatter.hasAnyModifier(hotkey) else {
            errorMessage = "快捷键必须至少包含一个修饰键 (⌘/⇧/⌥/⌃)。"
            return
        }

        settingsStore.updateHotkey(hotkey)
        syncSettingsFromStore()
        registerHotkey()
    }

    func updateMaxItems(_ maxItems: Int) {
        settingsStore.updateMaxItems(maxItems)
        syncSettingsFromStore()
        historyStore.update(maxItems: settings.maxItems)
        reloadHistory()
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        settingsStore.updateLaunchAtLogin(enabled)
        syncSettingsFromStore()
        applyLaunchAtLogin(enabled)
    }

    func clearHistory() {
        historyStore.clear()
        reloadHistory()
    }

    func requestAccessibilityPermission() {
        permissionManager.request()
    }

    func openAccessibilitySettings() {
        permissionManager.openSystemSettings()
    }

    func refreshPermission() {
        permissionManager.refresh()
    }

    var hotkeyDisplay: String {
        HotkeyFormatter.display(settings.hotkey)
    }

    private func registerHotkey() {
        do {
            try hotkeyManager.register(settings.hotkey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginManager.apply(enabled: enabled)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncSettingsFromStore() {
        settingsStore.reload()
        settings = settingsStore.currentSettings()
    }

    private func reloadHistory() {
        historyItems = historyStore.items()
    }

    private static func historyFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        return appSupport
            .appendingPathComponent("ClipboardMenu", isDirectory: true)
            .appendingPathComponent("history.json", isDirectory: false)
    }
}
