import Access

public enum Action {
    @Access(read: .fileprivate)
    public enum Public {
        case publicAction1
    }

    @Access(emit: .fileprivate)
    public enum Delegate {
        case delegateAction1
    }

    @Access
    fileprivate enum Fileprivate {
        case fileprivateAction1
    }

    @Access
    enum Internal {
        case internalAction1
    }

    case `public`(PublicAccessor)
    case delegate(DelegateAccessor)
    case `fileprivate`(FileprivateAccessor)
    case `internal`(InternalAccessor)
}

let actions: [Action] = [
    .public(.init(.publicAction1)),
    .delegate(.init(.delegateAction1)),
    .fileprivate(.init(.fileprivateAction1)),
    .internal(.init(.internalAction1)),
]

func handleInTheSameFile(_ action: Action) {
    switch action {
    case .public(let action):
        switch action.value {
        case .publicAction1: break
        }
    case .delegate(let action):
        switch action.value {
        case .delegateAction1: break
        }
    case .fileprivate(let action):
        switch action.value {
        case .fileprivateAction1: break
        }
    case .internal(let action):
        switch action.value {
        case .internalAction1: break
        }
    }
}
