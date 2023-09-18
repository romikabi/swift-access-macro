import SwiftSyntax
import SwiftSyntaxMacros

public struct AccessMacro: PeerMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case notModifiable
        case notNamed
        case custom(String)

        var description: String {
            switch self {
            case .notModifiable:
                return "Declaration should have an access level"
            case .notNamed:
                return "Declaration should have a name"
            case let .custom(description):
                return description
            }
        }
    }

    public static func expansion<Context, Declaration>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] where Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol {
        guard let modified = declaration.asProtocol(WithModifiersSyntax.self) else {
            throw Error.notModifiable
        }

        guard let named = declaration.asProtocol(NamedDeclSyntax.self) else {
            throw Error.notNamed
        }

        let access = modified.modifiers.access.map { "\($0) " } ?? ""
        let identifier = "\(named.name)".trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = "Accessor"
        let wrapper = identifier + suffix
        let inheritance = declaration
            .asProtocol(DeclGroupSyntax.self)?
            .inheritanceClause?.description ?? ""
        let read = node
            .argument(name: "read")
            .map { $0 + " " } ?? access
        let emit = node
            .argument(name: "emit")
            .map { $0 + " " } ?? access
        let propertyName = node
            .argument(name: "propertyName")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "value"

        return [
            """
            public struct \(raw: wrapper)\(raw: inheritance){
                \(raw: read)let \(raw: propertyName): \(raw: identifier)

                \(raw: emit)init(_ \(raw: propertyName): \(raw: identifier)) {
                    self.\(raw: propertyName) = \(raw: propertyName)
                }
            }
            """
        ]
    }
}

extension DeclModifierListSyntax {
    fileprivate var access: Keyword? {
        [Keyword.public, .private, .internal, .fileprivate].first { access in
            map(\.name.tokenKind).contains(.keyword(access))
        }
    }
}

extension AttributeSyntax {
    fileprivate func argument(name: String) -> String? {
        arguments?
            .as(LabeledExprListSyntax.self)?
            .first { $0.label?.tokenKind == .identifier(name) }?
            .as(LabeledExprSyntax.self)?
            .expression
            .as(MemberAccessExprSyntax.self)?
            .declName
            .baseName
            .description
    }
}
