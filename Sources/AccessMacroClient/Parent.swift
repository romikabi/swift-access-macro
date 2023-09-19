import ComposableArchitecture
import Foundation

struct Parent: Reducer {
    struct State: Equatable {
        var child = Child.State()
    }

    enum Action {
        case initialize
        case child(Child.Action)
    }

    @ReducerBuilder<State, Action>
    var body: some ReducerOf<Self> {
        Scope(state: \.child, action: /Action.child) {
            Child()
        }
        Reduce { state, action in
            switch action {
            case .initialize:
                return .send(.child(.public(.load(URL(string: "https://google.com")!))))
            case .child(let action):
                switch action {
                case .delegate(let action):
                    switch action.value {
                    case .didFinishLoading:
                        print("loading finished")
                        return .none
                    }
             // case .public(let action):
             //     switch action.value {} // 'value' is inaccessible due to 'fileprivate' protection level
                case .public:
                    return .none
             // case .fileprivate:
             //     return .send(.child(.fileprivate(.loadingFinished))) // 'loadingFinished' is inaccessible due to 'fileprivate' protection level
                case .fileprivate:
                    return .none
                }
            }
        }
    }
}
