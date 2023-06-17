//
//  QuranAudioPlayerDelegateClosures.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import BatchDownloader
import Locking
import QuranKit
import Utilities
@testable import QuranAudioKit

@MainActor
class QuranAudioPlayerDelegateClosures {
    // MARK: Lifecycle

    nonisolated init() {
    }

    // MARK: Internal

    enum Event: Equatable {
        case onPlaybackPaused
        case onPlaybackResumed
        case onPlaying(AyahNumber)
        case onPlaybackEnded
    }

    var onPlaybackPausedBlock: (() -> Void)?
    var onPlaybackResumedBlock: (() -> Void)?
    var onPlayingBlock: (() -> Void)?
    var onPlaybackEndedBlock: (() -> Void)?

    var eventsDiffSinceLastCalled: [Event] {
        events.sync { value in
            let lastValue = value
            // clear the value
            value = []
            return lastValue
        }
    }

    func makeActions() -> QuranAudioPlayerActions {
        QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.onPlaybackEnded() },
            playbackPaused: { [weak self] in self?.onPlaybackPaused() },
            playbackResumed: { [weak self] in self?.onPlaybackResumed() },
            playing: { [weak self] in self?.onPlaying(ayah: $0) }
        )
    }

    func onPlaybackPaused() {
        events.sync { $0.append(.onPlaybackPaused) }
        onPlaybackPausedBlock?()
    }

    func onPlaybackResumed() {
        events.sync { $0.append(.onPlaybackResumed) }
        onPlaybackResumedBlock?()
    }

    func onPlaying(ayah: AyahNumber) {
        events.sync { $0.append(.onPlaying(ayah)) }
        onPlayingBlock?()
    }

    func onPlaybackEnded() {
        events.sync { $0.append(.onPlaybackEnded) }
        onPlaybackEndedBlock?()
    }

    // MARK: Private

    private var events: Protected<[Event]> = Protected([])
}
