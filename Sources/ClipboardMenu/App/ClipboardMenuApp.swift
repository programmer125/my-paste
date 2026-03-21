import SwiftUI

@main
struct ClipboardMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra("Clip", systemImage: "clipboard") {
            MenuContentView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .frame(width: 560, height: 560)
                .padding(16)
        }
    }
}
