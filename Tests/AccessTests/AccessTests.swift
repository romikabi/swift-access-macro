#if canImport(AccessMacros)
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntax
import AccessMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ComposableActionTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Access": AccessMacro.self
    ]

    func testSimple() {
        assertMacroExpansion(
            """
            enum Action {
                @Access
                struct A {}
            }
            """,
            expandedSource: """
            enum Action {
                struct A {}

                public struct AAccessor {
                    let value: A
                    init(_ value: A) {
                        self.value = value
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testPublicEnumFileprivateEmit() {
        assertMacroExpansion(
            """
            enum Action {
                @Access(emit: .fileprivate)
                public enum Delegate {
                    case action
                }
            }
            """,
            expandedSource: """
            enum Action {
                public enum Delegate {
                    case action
                }

                public struct DelegateAccessor {
                    public let value: Delegate
                    fileprivate init(_ value: Delegate) {
                        self.value = value
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testFileprivateEnumEmit() {
        assertMacroExpansion(
            """
            enum Action {
                @Access(emit: .fileprivate)
                fileprivate enum Private {
                    case action
                }
            }
            """,
            expandedSource: """
            enum Action {
                fileprivate enum Private {
                    case action
                }

                public struct PrivateAccessor {
                    fileprivate let value: Private
                    fileprivate init(_ value: Private) {
                        self.value = value
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testFileprivateAccessPublicEmit() {
        assertMacroExpansion(
            """
            enum Action {
                @Access(read: .fileprivate, emit: .public)
                public enum Public {
                    case action
                }
            }
            """,
            expandedSource: """
            enum Action {
                public enum Public {
                    case action
                }

                public struct PublicAccessor {
                    fileprivate let value: Public
                    public init(_ value: Public) {
                        self.value = value
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
#endif
