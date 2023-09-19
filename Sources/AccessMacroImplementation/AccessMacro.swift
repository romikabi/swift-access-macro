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

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let params = try Params(node: node, declaration: declaration)
        let genericParameterClause = declaration
            .asProtocol(WithGenericParametersSyntax.self)?
            .genericParameterClause
        let inheritanceClause = declaration
            .asProtocol(DeclGroupSyntax.self)?
            .inheritanceClause
        let typename = join([
            params.name,
            genericParameterClause.map { generics in
                join([
                    "<",
                    join(separator: ", ", generics.parameters.map { generic in
                        join(separator: " ", [
                            generic.eachKeyword.map { _ in "repeat each" },
                            generic.name.trimmedDescription,
                        ])
                    }),
                    ">",
                ])
            }
        ])

        let accessor = StructDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: "\(raw: params.name)Accessor",
            genericParameterClause: genericParameterClause,
            inheritanceClause: inheritanceClause.map { clause in
                InheritanceClauseSyntax(inheritedTypesBuilder: {
                    for type in clause.inheritedTypes
                    where ["Equatable", "Hashable"] .contains(type.type.trimmedDescription) {
                        type
                    }
                })
            },
            genericWhereClause: declaration
                .asProtocol(WithGenericParametersSyntax.self)?
                .genericWhereClause,
            memberBlockBuilder: {
                """
                \(raw: params.read)let \(raw: params.property): \(raw: typename)
                """

                """
                \(raw: params.emit)init(_ \(raw: params.property): \(raw: typename)) {
                    self.\(raw: params.property) = \(raw: params.property)
                }
                """

                if let declaration = declaration.asProtocol(DeclGroupSyntax.self) {
                    for member in declaration.memberBlock.members {
                        if let enumCase = member.decl.as(EnumCaseDeclSyntax.self) {
                            for f in makers(for: enumCase, emit: params.emit, context: context) {
                                f
                            }
                        }
                    }
                }

                if let inheritanceClause, inheritanceClause.inheritedTypes.contains(where: {
                    $0.type.trimmedDescription == "Equatable"
                }) {
                    """
                    \(raw: params.read)func `is`(_ \(raw: params.property): \(raw: typename)) -> Bool {
                        self.\(raw: params.property) == \(raw: params.property)
                    }
                    """
                }
            }
        )

        return [
            accessor.as(DeclSyntax.self)
        ].compactMap { $0 }
    }

    private struct Params {
        var name: String
        var read: String
        var emit: String
        var property: String

        init(node: AttributeSyntax, declaration: some SyntaxProtocol) throws {
            guard let modified = declaration.asProtocol(WithModifiersSyntax.self) else {
                throw Error.notModifiable
            }

            guard let named = declaration.asProtocol(NamedDeclSyntax.self) else {
                throw Error.notNamed
            }

            let access = modified
                .modifiers
                .access
                .map { "\($0)" }?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let read = node.argument(name: "read")?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let emit = node.argument(name: "emit")?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let property = node.argument(name: "property")?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "value"

            self.name = "\(named.name)".trimmingCharacters(in: .whitespacesAndNewlines)
            self.property = property
            self.read = (read ?? access).map { "\($0) " } ?? ""
            self.emit = (emit ?? access).map { "\($0) " } ?? ""
        }
    }
}

private func makers(
    for enumCase: EnumCaseDeclSyntax,
    emit: String,
    context: some MacroExpansionContext
) -> [DeclSyntax] {
    enumCase.elements.map { c in
        let parameters = c.parameterClause?.parameters.enumerated().map { (index, parameter) in
            (
                first: parameter.firstName ?? .wildcardToken(),
                second: secondName(first: parameter.firstName, second: parameter.secondName, at: index),
                type: parameter.type
            )
        } ?? []
        if parameters.isEmpty {
            return """
            \(raw: emit)static let \(raw: c.name) = Self(.\(raw: c.name))
            """
        } else {
            let signatureParams = parameters.map {
                "\($0.first)"
                + ($0.second.map { " \($0)" } ?? "")
                + ": \($0.type)"
            }.joined(separator: ", ")
            let callParams = parameters.map {
                "\($0.first): \($0.second ?? $0.first)"
            }.joined(separator: ", ")
            return """
            \(raw: emit)static func \(raw: c.name)(\(raw: signatureParams)) -> Self {
                return Self(.\(raw: c.name)(\(raw: callParams)))
            }
            """
        }
    }
}

private func secondName(first: TokenSyntax?, second: TokenSyntax?, at index: Int) -> TokenSyntax? {
    if let second { return second }
    if let first, first != .wildcardToken() { return nil }
    return "param\(raw: index)"
}

private func join(separator: String = "", _ strings: [String?]) -> String {
    strings.compactMap { $0 }.joined(separator: separator)
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
