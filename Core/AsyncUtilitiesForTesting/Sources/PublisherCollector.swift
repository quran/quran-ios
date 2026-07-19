//
//  PublisherCollector.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import Combine

public final class PublisherCollector<T> {
    // MARK: Lifecycle

    public init<P: Publisher>(_ publisher: P) where P.Output == T, P.Failure == Never {
        cancellable = publisher.sink(receiveValue: { [weak self] item in
            self?.items.append(item)
        })
    }

    // MARK: Public

    public var cancellable: AnyCancellable?
    public var items: [T] = []
}
