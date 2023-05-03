//
//  MulticastContinuation.swift
//
//
//  Created by Mohamed Afifi on 2023-04-30.
//

import Foundation

public actor MulticastContinuation<T, E: Error> {
    private(set) var continuations: [CheckedContinuation<T, E>] = []
    public private(set) var result: Result<T, E>?

    public var isPending: Bool {
        result == nil
    }

    public init() { }

    public func addContinuation(_ continuation: CheckedContinuation<T, E>) {
        if let result {
            continuation.resume(with: result)
        } else {
            continuations.append(continuation)
        }
    }

    public func resume(with result: Result<T, E>) {
        self.result = result
        for continuation in continuations {
            continuation.resume(with: result)
        }
        continuations.removeAll()
    }

    public func resume(returning value: T) {
        resume(with: .success(value))
    }

    public func resume(throwing error: E) {
        resume(with: .failure(error))
    }
}
