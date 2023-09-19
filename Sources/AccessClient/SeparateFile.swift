func handleInASeparateFile(_ action: Action) {
    switch action {
//  case .public(let action):
//      switch action.value { // 'value' is inaccessible due to 'fileprivate' protection level
//      case .a: break
//      }
    case .public:
        break
    case .delegate(let action):
        switch action.value {
        case .b: break
        }
//  case .fileprivate(let action):
//      switch action.value { // 'value' is inaccessible due to 'fileprivate' protection level
//      case .c: break
//      }
    case .fileprivate:
        break
    case .internal(let action):
        switch action.value {
        case .d, .e, .f: break
        }
    }
}
