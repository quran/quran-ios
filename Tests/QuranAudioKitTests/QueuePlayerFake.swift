//
//  QueuePlayerFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
import QueuePlayer
@testable import QuranAudioKit

class QueuePlayerFake: QueuingPlayer {
    var actions: QueuePlayerActions?

    var state: PlayingState = .stopped
    enum PlayingState: Equatable, Encodable {
        case playing(AudioRequest)
        case paused(AudioRequest)
        case stopped

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

    var location = 0

    func play(request: AudioRequest) {
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
}
