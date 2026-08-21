//
//  QuranFontSource.swift
//

import Combine

public struct QuranFontSource {
    // MARK: Lifecycle

    public init<P: Publisher>(current: @escaping () -> QuranFont, updates: P)
        where P.Output == QuranFont, P.Failure == Never
    {
        currentValue = current
        let updates = updates.eraseToAnyPublisher()
        self.updates = Deferred {
            updates
                .prepend(current())
                .removeDuplicates()
                .dropFirst()
        }
        .eraseToAnyPublisher()
    }

    public init(_ quranFont: QuranFont) {
        currentValue = { quranFont }
        updates = Empty<QuranFont, Never>(completeImmediately: false)
            .eraseToAnyPublisher()
    }

    // MARK: Public

    public var current: QuranFont { currentValue() }
    public let updates: AnyPublisher<QuranFont, Never>

    // MARK: Private

    private let currentValue: () -> QuranFont
}
