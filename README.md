# ClipboardMenu

一个常驻菜单栏的 macOS 剪贴板工具，使用 SwiftUI + AppKit 构建。

## 项目结构

```text
.
├── Package.swift
├── Sources
│   ├── ClipboardCore
│   │   ├── History
│   │   ├── Models
│   │   └── Settings
│   └── ClipboardMenu
│       ├── Accessibility
│       ├── App
│       ├── Hotkey
│       ├── Paste
│       ├── Popup
│       ├── Services
│       └── Views
├── Tests
│   ├── ClipboardCoreTests
│   └── ClipboardMenuTests
└── scripts
```

## 本地开发

```bash
swift build
swift test
```

## 打包本地 `.app`

```bash
./scripts/package_app.sh
```

默认会生成：

```text
dist/ClipboardMenu.app
```

可通过环境变量覆盖元数据：

```bash
APP_NAME=ClipboardMenu \
BUNDLE_ID=com.duyx.clipboardmenu \
SHORT_VERSION=0.1.0 \
BUILD_VERSION=1 \
./scripts/package_app.sh
```

建议将生成的 `.app` 拖入 `/Applications` 后再验证开机自启。

## 资源占用与泄漏检查

1. 启动应用后记录进程采样：

```bash
./scripts/sample_process_usage.sh ClipboardMenu 60 2
```

2. 检查泄漏：

```bash
leaks "$(pgrep -x ClipboardMenu | head -n 1)"
```

3. 采集 Instruments 轨迹：

```bash
xcrun xctrace record \
  --template 'Time Profiler' \
  --launch dist/ClipboardMenu.app \
  --time-limit 30s \
  --output /tmp/clipboardmenu-time-profiler.trace
```

建议至少覆盖以下场景：

- 空闲运行 30 分钟，观察 CPU 是否保持低位。
- 连续复制 1000 次短文本，观察 RSS 是否回落。
- 连续打开/关闭历史弹窗，确认内存不会持续增长。
