//
//  MulticastContinuation.swift
//
//
//  Created by Mohamed Afifi on 2023-04-30.
//

import Foundation

public struct MulticastContinuation<T, E: Error> {
    private struct State {
        var continuations: [CheckedContinuation<T, E>] = []
        var result: Result<T, E>?
    }

    private let state = ManagedCriticalState(State())

    public var isPending: Bool {
        state.withCriticalRegion { state in
            state.result == nil
        }
    }

    public init() { }

    public func addContinuation(_ continuation: CheckedContinuation<T, E>) {
        state.withCriticalRegion { state in
            if let result = state.result {
                continuation.resume(with: result)
            } else {
                state.continuations.append(continuation)
            }
        }
    }

    public func resume(with result: Result<T, E>) {
        state.withCriticalRegion { state in
            state.result = result
            for continuation in state.continuations {
                continuation.resume(with: result)
            }
            state.continuations.removeAll()
        }
    }

    public func resume(returning value: T) {
        resume(with: .success(value))
    }

    public func resume(throwing error: E) {
        resume(with: .failure(error))
    }
}
