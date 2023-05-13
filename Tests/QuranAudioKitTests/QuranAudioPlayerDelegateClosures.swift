//
//  QuranAudioPlayerDelegateClosures.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import AsyncExtensions
import BatchDownloader
import Locking
@testable import QuranAudioKit
import QuranKit
import Utilities

class QuranAudioPlayerDelegateClosures {
    enum Event: Equatable {
        case onPlaybackPaused
        case onPlaybackResumed
        case onPlaying(AyahNumber)
        case onPlaybackEnded
    }

    func makeActions() -> QuranAudioPlayerActions {
        QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.onPlaybackEnded() },
            playbackPaused: { [weak self] in self?.onPlaybackPaused() },
            playbackResumed: {[weak self] in self?.onPlaybackResumed()},
            playing: { [weak self] in self?.onPlaying(ayah: $0)})
    }

    private var events: Protected<[Event]> = Protected([])

    var eventsDiffSinceLastCalled: [Event] {
        events.sync { value in
            let lastValue = value
            // clear the value
            value = []
            return lastValue
        }
    }

    var onPlaybackPausedBlock: (() -> Void)?
    func onPlaybackPaused() {
        events.sync { $0.append(.onPlaybackPaused) }
        onPlaybackPausedBlock?()
    }

    var onPlaybackResumedBlock: (() -> Void)?
    func onPlaybackResumed() {
        events.sync { $0.append(.onPlaybackResumed) }
        onPlaybackResumedBlock?()
    }

    var onPlayingBlock: (() -> Void)?
    func onPlaying(ayah: AyahNumber) {
        events.sync { $0.append(.onPlaying(ayah)) }
        onPlayingBlock?()
    }

    var onPlaybackEndedBlock: (() -> Void)?
    func onPlaybackEnded() {
        events.sync { $0.append(.onPlaybackEnded) }
        onPlaybackEndedBlock?()
    }
}
