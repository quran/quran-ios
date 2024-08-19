//
//  OperationCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/28/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Utilities

public typealias CacheableOperation<Input, Output> = @Sendable (Input) async throws -> Output

final class OperationCacheableService<Input: Hashable & Sendable, Output: Sendable>: Sendable {
    private struct State: Sendable {
        let cache: Cache<Input, Output>
        var inProgressOperations: [Input: MulticastContinuation<Output, Error>] = [:]
    }

    // MARK: Lifecycle

    init(cache: Cache<Input, Output>, operation: @escaping CacheableOperation<Input, Output>) {
        state = ManagedCriticalState(State(cache: cache))
        self.operation = operation
    }

    // MARK: Internal

    func invalidate() {
        state.withCriticalRegion { state in
            state.inProgressOperations.removeAll()
            state.cache.removeAllObjects()
        }
    }

    func get(_ input: Input) async throws -> Output {
        if let cachedValue = getCached(input) {
            return cachedValue
        }

        return try await withCheckedThrowingContinuation { continuation in
            state.withCriticalRegion { state in
                if let continuations = state.inProgressOperations[input] {
                    continuations.addContinuation(continuation)
                } else {
                    let continuations = MulticastContinuation<Output, Error>()
                    continuations.addContinuation(continuation)
                    state.inProgressOperations[input] = continuations

                    startOperation(input: input, continuations: continuations)
                }
            }
        }
    }

    func getCached(_ input: Input) -> Output? {
        state.withCriticalRegion { state in
            state.cache.object(forKey: input)
        }
    }

    // MARK: Private

    private let state: ManagedCriticalState<State>

    private let operation: CacheableOperation<Input, Output>

    private func startOperation(input: Input, continuations: MulticastContinuation<Output, Error>) {
        Task {
            // Execute.
            let result = await Swift.Result { try await operation(input) }

            state.withCriticalRegion { state in
                // Cache the result.
                if case let .success(value) = result {
                    state.cache.setObject(value, forKey: input)
                }
                continuations.resume(with: result)

                // remove from in progress
                state.inProgressOperations.removeValue(forKey: input)
            }
        }
    }
}
