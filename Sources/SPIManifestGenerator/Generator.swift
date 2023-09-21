import Foundation
import SPIManifest
import Yams

@main
enum Generator {
    static func main() throws {
        let manifest = Manifest(
            version: 1,
            builder: Manifest.Builder(
                configs: Platform.allCases.map { platform in
                    .init(
                        platform: platform.rawValue,
                        scheme: "AccessMacro"
                    )
                }
            )
        )

        let yml = try YAMLEncoder().encode(manifest)

        try yml.write(
            to: URL(fileURLWithPath: #file, isDirectory: false)
                .deletingLastPathComponent() // SPIManifestGenerator
                .deletingLastPathComponent() // Sources
                .deletingLastPathComponent() // Root
                .appendingPathComponent(".spi.yml"),
            atomically: true,
            encoding: .utf8
        )
    }
}
