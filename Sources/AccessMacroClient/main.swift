import ComposableArchitecture
import Foundation

let store = Store(initialState: .init()) {
    Parent()
}

store.send(.initialize)

try await Task.sleep(nanoseconds: NSEC_PER_SEC)
