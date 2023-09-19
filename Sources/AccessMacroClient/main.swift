import AccessMacro

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

let actions: [Action] = [
    .public(.a(1)),
    .delegate(.b(value: 2)),
    .fileprivate(.c(3)),
    .internal(.d(4)),
    .internal(.d(5)),
    .internal(.f),
]

func handleInTheSameFile(_ action: Action) {
    switch action {
    case .public(let action) where action.is(.a(1)):
        break
    case .public(let action):
        switch action.value {
        case .a: break
        }
    case .delegate(let action):
        switch action.value {
        case .b: break
        }
    case .fileprivate(let action):
        switch action.value {
        case .c: break
        }
    case .internal(let action):
        switch action.value {
        case .d, .e, .f: break
        }
    }
}
