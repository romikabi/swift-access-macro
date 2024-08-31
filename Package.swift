// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-access-macro",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "AccessMacro",
            targets: ["AccessMacro"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.1.0"),
        .package(url: "https://github.com/SwiftPackageIndex/SPIManifest.git", from: "0.12.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "AccessMacroImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "AccessMacro", dependencies: ["AccessMacroImplementation"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "AccessMacroClient",
            dependencies: [
                "AccessMacro",
            ]
        ),

        .executableTarget(
            name: "SPIManifestGenerator",
            dependencies: [
                .product(name: "SPIManifest", package: "SPIManifest"),
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "AccessMacroTests",
            dependencies: [
                "AccessMacroImplementation",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
