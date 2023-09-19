#if canImport(AccessMacroImplementation)
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntax
import AccessMacroImplementation
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting

final class ComposableActionTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: [
                "Access": AccessMacro.self
            ],
            operation: super.invokeTest
        )
    }

    func testSimple() {
        assertMacro {
            """
            enum Action {
                @Access
                struct A {}
            }
            """
        } matches: {
            """
            enum Action {
                struct A {}

                public struct AAccessor {
                    let value: A
                    init(_ value: A) {
                        self.value = value
                    }
                }
            }
            """
        }
    }

    func testPublicEnumFileprivateEmit() {
        assertMacro {
            """
            enum Action {
                @Access(emit: .fileprivate)
                public enum Delegate: Equatable {
                    case action
                }
            }
            """
        } matches: {
            """
            enum Action {
                public enum Delegate: Equatable {
                    case action
                }

                public struct DelegateAccessor: Equatable {
                    public let value: Delegate
                    fileprivate init(_ value: Delegate) {
                        self.value = value
                    }
                    fileprivate static let action = Self (.action)
                    public func `is`(_ value: Delegate) -> Bool {
                        self.value == value
                    }
                }
            }
            """
        }
    }

    func testFileprivateEnumEmit() {
        assertMacro {
            """
            enum Action {
                @Access(emit: .fileprivate)
                fileprivate enum Private {
                    case action
                }
            }
            """
        } matches: {
            """
            enum Action {
                fileprivate enum Private {
                    case action
                }

                public struct PrivateAccessor {
                    fileprivate let value: Private
                    fileprivate init(_ value: Private) {
                        self.value = value
                    }
                    fileprivate static let action = Self (.action)
                }
            }
            """
        }
    }

    func testFileprivateAccessPublicEmit() {
        assertMacro {
            """
            enum Action {
                @Access(read: .fileprivate, emit: .public)
                public enum Public {
                    case action
                }
            }
            """
        } matches: {
            """
            enum Action {
                public enum Public {
                    case action
                }

                public struct PublicAccessor {
                    fileprivate let value: Public
                    public init(_ value: Public) {
                        self.value = value
                    }
                    public static let action = Self (.action)
                }
            }
            """
        }
    }

    func testComplexAction() {
        assertMacro {
            """
            public enum Action {
                @Access(read: .fileprivate)
                public enum Public: Equatable {
                    case a(Int)
                }

                @Access(emit: .fileprivate)
                public enum Delegate {
                    case b(value: Int)
                }

                @Access
                fileprivate enum Fileprivate {
                    case c(_ value: Int)
                }

                @Access
                enum Internal {
                    case d(Int), e(Int), f
                }

                case `public`(PublicAccessor)
                case delegate(DelegateAccessor)
                case `fileprivate`(FileprivateAccessor)
                case `internal`(InternalAccessor)
            }
            """
        } matches: {
            """
            public enum Action {
                public enum Public: Equatable {
                    case a(Int)
                }

                public struct PublicAccessor: Equatable {
                    fileprivate let value: Public
                    public init(_ value: Public) {
                        self.value = value
                    }
                    public static func a(_ param0: Int) -> Self {
                        return Self (.a(_: param0))
                    }
                    fileprivate func `is`(_ value: Public) -> Bool {
                        self.value == value
                    }
                }
                public enum Delegate {
                    case b(value: Int)
                }

                public struct DelegateAccessor {
                    public let value: Delegate
                    fileprivate init(_ value: Delegate) {
                        self.value = value
                    }
                    fileprivate static func b(value: Int) -> Self {
                        return Self (.b(value: value))
                    }
                }
                fileprivate enum Fileprivate {
                    case c(_ value: Int)
                }

                public struct FileprivateAccessor {
                    fileprivate let value: Fileprivate
                    fileprivate init(_ value: Fileprivate) {
                        self.value = value
                    }
                    fileprivate static func c(_  value: Int) -> Self {
                        return Self (.c(_ : value))
                    }
                }
                enum Internal {
                    case d(Int), e(Int), f
                }

                public struct InternalAccessor {
                    let value: Internal
                    init(_ value: Internal) {
                        self.value = value
                    }
                    static func d(_ param0: Int) -> Self {
                        return Self (.d(_: param0))
                    }
                    static func e(_ param0: Int) -> Self {
                        return Self (.e(_: param0))
                    }
                    static let f = Self (.f)
                }

                case `public`(PublicAccessor)
                case delegate(DelegateAccessor)
                case `fileprivate`(FileprivateAccessor)
                case `internal`(InternalAccessor)
            }
            """
        }
    }
}
#endif
