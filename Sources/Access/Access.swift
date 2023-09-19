/// Generates a wrapper with specified access levels.
/// The wrapper gets the same inheritance clause as a declaration
/// (e.g. conforms to Equatable if the declaration does).
/// The wrapper itself is always `public`,
/// access level to it's members is controlled by parameters.
/// - Parameters:
///   - read: Access modifier for wrapper's `value` property.
///   Should be the same or more strict than than the declaration modifier.
///   Use `nil` to inherit the declaration modifier.
///   - emit: Access modifier for wrapper's `init`, as well as a helper `static func`.
///   Should be the same or more strict than than the declaration modifier.
///   Use `nil` to inherit the declaration modifier.
///   - property: The name of the wrapper property, containing declaration.
///   Use `nil` to use the default `value`.
///
/// Example expansion:
///   ```
///   @Access(emit: .fileprivate)
///   public enum Foo {
///       case a
///       case b
///   }
///   ```
///   ```
///   public struct FooAccessor {
///       public let value: Foo
///
///       fileprivate init(_ value: Foo) {
///           self.value = value
///       }
///   }
///   ```
@attached(peer, names: suffixed(Accessor))
public macro Access(
    read: AccessType? = nil,
    emit: AccessType? = nil,
    property: String? = nil
) = #externalMacro(module: "AccessMacros", type: "AccessMacro")
