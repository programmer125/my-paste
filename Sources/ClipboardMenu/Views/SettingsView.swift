import ClipboardCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                settingsHeader

                settingsCard(title: "快捷键") {
                    VStack(spacing: 10) {
                        infoRow(left: "当前快捷键", right: model.hotkeyDisplay)

                        Picker("按键", selection: keyCodeBinding) {
                            ForEach(HotkeyFormatter.keyOptions, id: \.keyCode) { option in
                                Text(option.name).tag(option.keyCode)
                            }
                        }

                        Toggle("Command ⌘", isOn: commandBinding)
                        Toggle("Shift ⇧", isOn: shiftBinding)
                        Toggle("Option ⌥", isOn: optionBinding)
                        Toggle("Control ⌃", isOn: controlBinding)
                    }
                }

                settingsCard(title: "历史记录") {
                    VStack(spacing: 10) {
                        Stepper(value: maxItemsBinding, in: AppSettings.minMaxItems...AppSettings.maxMaxItems, step: 10) {
                            Text("最大条数: \(model.settings.maxItems)")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Button(role: .destructive) {
                            model.clearHistory()
                        } label: {
                            Text("清空历史")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                settingsCard(title: "启动与权限") {
                    VStack(spacing: 10) {
                        Toggle("开机自启", isOn: launchAtLoginBinding)

                        if model.permissionManager.isTrusted {
                            infoRow(left: "无障碍权限", right: "已授权", rightColor: .green)
                        } else {
                            Text("无障碍权限未授权，可能影响光标定位和自动粘贴")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 10) {
                                Button("申请权限") {
                                    model.requestAccessibilityPermission()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("打开系统设置") {
                                    model.openAccessibilitySettings()
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                if let errorMessage = model.errorMessage {
                    settingsCard(title: "状态") {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .underPageBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            model.refreshPermission()
        }
    }

    private var settingsHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("Clipboard 偏好设置")
                    .font(.system(size: 20, weight: .bold))
                Text("自定义热键、历史保留和权限行为")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private func infoRow(left: String, right: String, rightColor: Color = .secondary) -> some View {
        HStack {
            Text(left)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Text(right)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(rightColor)
        }
    }

    private var keyCodeBinding: Binding<UInt32> {
        Binding(
            get: { model.settings.hotkey.keyCode },
            set: { keyCode in
                let hotkey = HotkeyFormatter.updating(model.settings.hotkey, keyCode: keyCode)
                model.updateHotkey(hotkey)
            }
        )
    }

    private var commandBinding: Binding<Bool> {
        Binding(
            get: { HotkeyFormatter.includesCommand(model.settings.hotkey) },
            set: { enabled in
                let hotkey = HotkeyFormatter.updating(model.settings.hotkey, command: enabled)
                model.updateHotkey(hotkey)
            }
        )
    }

    private var shiftBinding: Binding<Bool> {
        Binding(
            get: { HotkeyFormatter.includesShift(model.settings.hotkey) },
            set: { enabled in
                let hotkey = HotkeyFormatter.updating(model.settings.hotkey, shift: enabled)
                model.updateHotkey(hotkey)
            }
        )
    }

    private var optionBinding: Binding<Bool> {
        Binding(
            get: { HotkeyFormatter.includesOption(model.settings.hotkey) },
            set: { enabled in
                let hotkey = HotkeyFormatter.updating(model.settings.hotkey, option: enabled)
                model.updateHotkey(hotkey)
            }
        )
    }

    private var controlBinding: Binding<Bool> {
        Binding(
            get: { HotkeyFormatter.includesControl(model.settings.hotkey) },
            set: { enabled in
                let hotkey = HotkeyFormatter.updating(model.settings.hotkey, control: enabled)
                model.updateHotkey(hotkey)
            }
        )
    }

    private var maxItemsBinding: Binding<Int> {
        Binding(
            get: { model.settings.maxItems },
            set: { newValue in
                model.updateMaxItems(newValue)
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.settings.launchAtLogin },
            set: { enabled in
                model.updateLaunchAtLogin(enabled)
            }
        )
    }
}
