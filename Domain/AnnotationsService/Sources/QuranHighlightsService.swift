//
//  QuranHighlightsService.swift
//
//
//  Created by Mohamed Afifi on 2023-12-23.
//

import Combine
import QuranAnnotations
import VLogging

public final class QuranHighlightsService {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @Published public var highlights = QuranHighlights() {
        didSet {
            logger.info("Highlights updated")
        }
    }

    public var scrolling: AnyPublisher<Void, Never> {
        $highlights
            .zip($highlights.dropFirst())
            .filter { oldValue, newValue in
                newValue.needsScrolling(comparingTo: oldValue)
            }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    public func reset() {
        highlights = QuranHighlights()
    }
}
