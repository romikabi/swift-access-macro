import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AccessPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AccessMacro.self
    ]
}
