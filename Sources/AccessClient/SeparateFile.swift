func handleInASeparateFile(_ action: Action) {
    switch action {
//  case .public(let action):
//      switch action.value { // 'value' is inaccessible due to 'fileprivate' protection level
//      case .publicAction1: break
//      }
    case .public:
        break
    case .delegate(let action):
        switch action.value {
        case .delegateAction1: break
        }
//  case .fileprivate(let action):
//      switch action.value { // 'value' is inaccessible due to 'fileprivate' protection level
//      case .fileprivateAction1: break
//      }
    case .fileprivate:
        break
    case .internal(let action):
        switch action.value {
        case .internalAction1: break
        }
    }
}
