import Foundation

@main
struct ParentReducer {
    struct State: Equatable {
        var child = ChildReducer.State()
    }

    enum Action {
        case initialize
        case child(ChildReducer.Action)
    }

    public func reduce(into state: inout State, action: Action) {
//      Scope(state: \.child, action: /Action.child) {
//          ChildReducer()
//      }
        switch action {
        case .initialize:
            break
        case .child(let action):
            switch action {
            case .delegate(let action):
                switch action.value {
                case .didFinishLoading:
                    print("loading finished")
                }
//          case .public(let action):
//              switch action.value {} // 'value' is inaccessible due to 'fileprivate' protection level
            case .public:
                break
//          case .fileprivate:
//              return .send(.child(.fileprivate(.loadingFinished))) // 'loadingFinished' is inaccessible due to 'fileprivate' protection level
            case .fileprivate:
                break
            }
        }
    }

    static func main() {}
}
