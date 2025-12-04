//
//  QueuePlayerFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import QueuePlayer
@testable import QuranAudioKit

@MainActor
class QueuePlayerFake: QueuingPlayer {
    // MARK: Lifecycle

    nonisolated init() {
    }

    // MARK: Internal

    enum PlayingState: Equatable, Encodable {
        case playing(AudioRequest)
        case paused(AudioRequest)
        case stopped

        // MARK: Internal

        var isPaused: Bool {
            switch self {
            case .paused: return true
            default: return false
            }
        }

        var isPlaying: Bool {
            switch self {
            case .playing: return true
            default: return false
            }
        }

        var isStopped: Bool {
            switch self {
            case .stopped: return true
            default: return false
            }
        }
    }

    var actions: QueuePlayerActions?

    var state: PlayingState = .stopped
    var location = 0

    func play(request: AudioRequest, rate: Float) {
        state = .playing(request)
        location = 0
    }

    func pause() {
        if case .playing(let request) = state {
            state = .paused(request)
        }
    }

    func resume() {
        if case .paused(let request) = state {
            state = .playing(request)
        }
    }

    func stop() {
        state = .stopped
    }

    func stepForward() {
        location += 1
    }

    func stepBackward() {
        location -= 1
    }

    func setRate(_ rate: Float) {
    }
}

extension QueuePlayerFake.PlayingState {
    private enum CaseCodingKeys: String, CodingKey {
        case playing
        case paused
        case stopped
    }

    private enum AssociatedValueCodingKeys: String, CodingKey {
        case _0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKeys.self)
        switch self {
        case .playing(let request):
            var nested = container.nestedContainer(keyedBy: AssociatedValueCodingKeys.self, forKey: .playing)
            try nested.encode(EncodableAudioRequest(request: request), forKey: ._0)
        case .paused(let request):
            var nested = container.nestedContainer(keyedBy: AssociatedValueCodingKeys.self, forKey: .paused)
            try nested.encode(EncodableAudioRequest(request: request), forKey: ._0)
        case .stopped:
            _ = container.nestedContainer(keyedBy: AssociatedValueCodingKeys.self, forKey: .stopped)
        }
    }
}
