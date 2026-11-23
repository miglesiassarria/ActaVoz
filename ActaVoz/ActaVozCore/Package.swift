// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ActaVozCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ActaVozCore", targets: ["ActaVozCore"])
    ],
    targets: [
        .target(name: "ActaVozCore", path: "Sources/ActaVozCore"),
        .testTarget(name: "ActaVozCoreTests", dependencies: ["ActaVozCore"], path: "Tests/ActaVozCoreTests")
    ]
)
