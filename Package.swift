// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ClipboardMenu",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ClipboardCore", targets: ["ClipboardCore"]),
        .executable(name: "ClipboardMenu", targets: ["ClipboardMenu"])
    ],
    targets: [
        .target(
            name: "ClipboardCore"
        ),
        .executableTarget(
            name: "ClipboardMenu",
            dependencies: ["ClipboardCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "ClipboardCoreTests",
            dependencies: ["ClipboardCore"]
        )
    ]
)
