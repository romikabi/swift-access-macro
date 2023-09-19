import SwiftSyntax
import SwiftSyntaxMacros

public enum AccessMacro: PeerMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case notNamed
        case custom(String)

        var description: String {
            switch self {
            case .notNamed:
                return "Macro should be applied to a type declaration"
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
        guard let named = declaration.asProtocol(NamedDeclSyntax.self) else {
            throw Error.notNamed
        }

        let access = declaration
            .asProtocol(WithModifiersSyntax.self)?
            .modifiers
            .access
            .map { "\($0)" }?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let property = node.argument(name: "property")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "value"
        let name = "\(named.name)".trimmingCharacters(in: .whitespacesAndNewlines)
        let read = (
            node.argument(name: "read")?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? access
        ).map { "\($0) " } ?? ""
        let emit = (
            node.argument(name: "emit")?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? access
        ).map { "\($0) " } ?? ""
        let genericParameterClause = declaration
            .asProtocol(WithGenericParametersSyntax.self)?
            .genericParameterClause
        let inheritanceClause = declaration
            .asProtocol(DeclGroupSyntax.self)?
            .inheritanceClause
        let typename = join([
            name,
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
            name: "\(raw: name)Accessor",
            genericParameterClause: genericParameterClause,
            inheritanceClause: inheritanceClause.map { clause in
                InheritanceClauseSyntax(inheritedTypesBuilder: {
                    for type in clause.inheritedTypes
                    where allowedInheritances.contains(type.type.trimmedDescription) {
                        type
                    }
                })
            },
            genericWhereClause: declaration
                .asProtocol(WithGenericParametersSyntax.self)?
                .genericWhereClause,
            memberBlockBuilder: {
                """
                \(raw: read)let \(raw: property): \(raw: typename)
                """

                """
                \(raw: emit)init(_ \(raw: property): \(raw: typename)) {
                    self.\(raw: property) = \(raw: property)
                }
                """

                if let declaration = declaration.asProtocol(DeclGroupSyntax.self) {
                    for member in declaration.memberBlock.members {
                        if let enumCase = member.decl.as(EnumCaseDeclSyntax.self) {
                            for f in makers(for: enumCase, emit: emit, context: context) {
                                f
                            }
                        }
                    }
                }

                if let inheritanceClause, inheritanceClause.inheritedTypes.contains(where: {
                    $0.type.trimmedDescription == equatable
                }) {
                    """
                    \(raw: read)func `is`(_ \(raw: property): \(raw: typename)) -> Bool {
                        self.\(raw: property) == \(raw: property)
                    }
                    """
                }
            }
        )

        return [
            accessor.as(DeclSyntax.self)
        ].compactMap { $0 }
    }

    private static let equatable = "Equatable"
    private static let hashable = "Hashable"
    private static let allowedInheritances = [equatable, hashable]
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
