// swift-tools-version:5.9
import PackageDescription

var targets: [Target] = [
    .target(name: "GyaimCore"),
    .testTarget(name: "GyaimCoreTests", dependencies: ["GyaimCore"]),
]
#if os(macOS)
targets.append(.executableTarget(name: "Gyaim", dependencies: ["GyaimCore"]))
#endif

let package = Package(
    name: "Gyaim",
    platforms: [.macOS(.v13)],
    targets: targets
)
