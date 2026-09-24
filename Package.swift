// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreeSlots",
    platforms: [.macOS(.v14)],
    targets: [
        // 空き時間の計算とテキスト整形。UI や EventKit に依存しないのでテストしやすい。
        .target(name: "FreeSlotsCore"),
        .executableTarget(
            name: "FreeSlots",
            dependencies: ["FreeSlotsCore"]
        ),
        .testTarget(
            name: "FreeSlotsCoreTests",
            dependencies: ["FreeSlotsCore"]
        ),
    ]
)
