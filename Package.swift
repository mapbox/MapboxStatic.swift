// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxStatic",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .watchOS(.v5), .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MapboxStatic",
            targets: ["MapboxStatic"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/raphaelmor/Polyline.git", from: "5.0.2"),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MapboxStatic",
            dependencies: ["Polyline"],
            exclude: ["Info.plist"]),
        .testTarget(
            name: "MapboxStaticTests",
            dependencies: [
                "MapboxStatic",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("fixtures"),
            ]),
    ]
)
