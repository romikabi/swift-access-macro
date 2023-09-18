// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Access",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "Access",
            targets: ["Access"]
        ),
        .executable(
            name: "AccessClient",
            targets: ["AccessClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "AccessMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Access", dependencies: ["AccessMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "AccessClient", dependencies: ["Access"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "AccessTests",
            dependencies: [
                "AccessMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
