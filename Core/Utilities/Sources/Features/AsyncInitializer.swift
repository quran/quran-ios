//
//  AsyncInitializer.swift
//
//
//  Created by Mohamed Afifi on 2023-11-26.
//

public struct AsyncInitializer {
    // MARK: Lifecycle

    public init() {
        var continuation: AsyncStream<Void>.Continuation!
        let stream = AsyncStream<Void> { continuation = $0 }
        self.continuation = continuation
        self.stream = stream
    }

    // MARK: Public

    public private(set) var initialized = false

    public mutating func initialize() {
        initialized = true
        continuation.finish()
    }

    public func awaitInitialization() async {
        if initialized {
            return
        }
        // Wait until the stream finishes
        for await _ in stream {}
    }

    // MARK: Private

    private let continuation: AsyncStream<Void>.Continuation
    private let stream: AsyncStream<Void>
}
