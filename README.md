# Swift Access Macro
`@Access` macro is designed to simplify granular access level control for your Swift types.
```swift
@Access(emit: .fileprivate)
enum Action {
    case didStart
    case didFinish
}

// generates ⬇️

public struct ActionAccessor {
    let value: Action
    fileprivate init(_ value: Action) {
        self.value = value
    }
    fileprivate static let didStart = Self(.didStart)
    fileprivate static let didFinish = Self(.didFinish)
}
```

## Motivation

There are some discussions about action boundaries in [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture/tree/main):
* [TCA Action Boundaries](https://www.merowing.info/boundries-in-tca/)
* [Thoughts on "Action Boundaries" to keep Actions organized and their intent explicit](https://github.com/pointfreeco/swift-composable-architecture/discussions/1440)

The idea is that we want to avoid making a flat `Action` enum containing all actions, and instead opt for a more nested structure:

```swift
public enum Action {
    public enum Public: Equatable {
        case load(URL)
    }

    public enum Delegate: Equatable {
        case didFinishLoading
    }

    fileprivate enum Fileprivate {
        case progressChanged(Double)
        case loadingFinished
    }

    case `public`(Public)
    case delegate(Delegate)
    case `fileprivate`(Fileprivate)
}
```

That way we can write exhaustive switches over comprehensible subsets of actions, instead of falling back to `default`.

The problem with this approach that I see is that out of the box it doesn't prevent misuse, any action can still be emitted and read anywhere, it's just a bit harder to do accidentally. Better situation can be achieved with custom lint rules, but I believe the type system can be utilised for a better solution.

## `@Access` macro
The `@Access` macro creates a `public struct` wrapping the annotated type and lets you specify access level for `read` and `emit` separately. `read` affects which part of the app can read the actual value of the type (e.g. `switch` over the action). `emit` affects which part of the app can create an instance of the type. See previous example improved:
```swift
public enum Action {
    // Public action can be created anywhere, can be read only in the file scope
    @Access(read: .fileprivate)
    public enum Public: Equatable {
        case load(URL)
    }

    // Delegate action can only be created in the file scope, but can be 
    // accessed anywhere
    @Access(emit: .fileprivate)
    public enum Delegate: Equatable {
        case didFinishLoading
    }

    // Fileprivate action inherits `fileprivate` modifier for both reading and emitting,
    // forbidding both outside of the file scope, but still letting the action 
    // be a part of a public enum
    @Access
    fileprivate enum Fileprivate {
        case progressChanged(Double)
        case loadingFinished
    }

    case `public`(PublicAccessor)
    case delegate(DelegateAccessor)
    case `fileprivate`(FileprivateAccessor)
}
```
By placing the action declaration in the same file as the TCA `Reducer` we can limit `Fileprivate` action to be only visible in that file, 
while allowing parent reducers read `Delegate` action and emit `Public` action, forbidding the rest.
The downside of the approach is that the whole action can't be switched over using single `switch` and a separate `switch` statements are required over `action.value`, 
but that can be benefitial for ensuring less catch all `default` statements and also can be mitigated by using a generated `is` function for `Equatable` types.

## Features
- [X] Generate a wrapper with separate access levels to `let value` and `init(value)`
- [X] Generate properties to instantiate simple cases of a wrapped enum
```swift
case didStart
// of a wrapped type
// yields
fileprivate static let didStart = Self(.didStart)
// on a wrapper, keeping the action creation syntax intact
```
- [X] Generate functions instantiate cases of a wrapped enum with associated values
```swift
case didStart(at: Date)
// of a wrapped type
// yields
fileprivate static func didStart(at: Date) -> Self {
    return Self(.didStart(at: at))
}
// on a wrapper, keeping the action creation syntax intact
```
- [X] Derive conformances to `Equatable` and `Hashable`
- [X] Generate an `is` function to use in conjunction with `where` inside a switch
- [X] Derive generics
- [X] Allow custom property name instead of `value`
- [ ] Generate other type members that delegate to a wrapped type
