//
//  VerseOverlayService.swift
//
//
//  Created by Mohamed Afifi on 2023-12-23.
//

import Combine
import QuranAnnotations
import VLogging

public final class VerseOverlayService {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @Published public var overlays = VerseOverlays() {
        didSet {
            logger.info("Verse overlays updated")
        }
    }

    /// Signals playback or navigation target changes using the complete overlay state.
    public var scrollRequests: AnyPublisher<Void, Never> {
        $overlays
            .zip($overlays.dropFirst())
            .filter { oldValue, newValue in
                newValue.needsScrolling(comparingTo: oldValue)
            }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    public func reset() {
        overlays = VerseOverlays()
    }
}
