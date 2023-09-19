import AccessMacro
import ComposableArchitecture
import Foundation

public struct Child: Reducer {
    public struct State: Equatable {
        var url: URL?
        var progress: Double?
    }

    public enum Action {
        @Access(read: .fileprivate)
        public enum Public: Equatable {
            case load(URL)
        }

        @Access(emit: .fileprivate)
        public enum Delegate: Equatable {
            case didFinishLoading
        }

        @Access
        fileprivate enum Fileprivate {
            case progressChanged(Double)
            case loadingFinished
        }

        case `public`(PublicAccessor)
        case delegate(DelegateAccessor)
        case `fileprivate`(FileprivateAccessor)
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .public(let action):
            switch action.value {
            case .load(let url):
                state.url = url
                return .run { send in
                    for step in 1...5 {
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
                        await send(.fileprivate(.progressChanged(Double(step) / 5)))
                    }
                    await send(.fileprivate(.loadingFinished))
                }
            }
        case .fileprivate(let action):
            switch action.value {
            case .progressChanged(let progress):
                state.progress = progress
                print("progress is \(progress)")
                return .none
            case .loadingFinished:
                state.progress = 1
                return .send(.delegate(.didFinishLoading))
            }
        case .delegate:
            return .none
        }
    }
}
