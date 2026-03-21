import Foundation
import ServiceManagement

final class LaunchAtLoginManager {
    enum LaunchError: LocalizedError {
        case unsupported
        case registrationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .unsupported:
                return "当前环境不支持开机自启配置。"
            case .registrationFailed(let error):
                return "更新开机自启失败: \(error.localizedDescription)"
            }
        }
    }

    func apply(enabled: Bool) throws {
        guard #available(macOS 13.0, *) else {
            throw LaunchError.unsupported
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw LaunchError.registrationFailed(error)
        }
    }
}
