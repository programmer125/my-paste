import SwiftUI

struct MenuContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            statusHeader

            menuDivider

            VStack(spacing: 0) {
                menuRow("显示粘贴历史", shortcut: model.hotkeyDisplay) {
                    model.showHistoryPopup()
                }

                if model.permissionManager.isTrusted {
                    statusRow("无障碍权限已授权", icon: "checkmark")
                } else {
                    menuRow("申请无障碍权限") {
                        model.requestAccessibilityPermission()
                    }
                    menuRow("打开系统设置") {
                        model.openAccessibilitySettings()
                    }
                }
            }
            .padding(.vertical, 4)

            menuDivider

            VStack(spacing: 0) {
                menuRow("偏好设置…", shortcut: "⌘,") {
                    model.openSettingsWindow()
                }
                menuRow("清空历史") {
                    model.clearHistory()
                }
            }
            .padding(.vertical, 4)

            if let errorMessage = model.errorMessage {
                menuDivider

                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
            }

            menuDivider

            menuRow("退出", shortcut: "⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var statusHeader: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(model.permissionManager.isTrusted ? Color.green : Color.orange)
                .frame(width: 12, height: 12)

            Text("Clipboard: \(model.permissionManager.isTrusted ? "On" : "Limited")")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.82))

            Spacer()

            Text("\(model.historyItems.count) 条")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var menuDivider: some View {
        Divider()
            .overlay(Color.black.opacity(0.1))
            .padding(.horizontal, 12)
    }

    private func statusRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .frame(width: 18)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.85))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    private func menuRow(_ title: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.88))

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.26))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
