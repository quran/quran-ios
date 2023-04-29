//
//  QuranAudioPlayerDelegateClosures.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import BatchDownloader
import Combine
import Locking
@testable import QuranAudioKit
import QuranKit

class QuranAudioPlayerDelegateClosures: QuranAudioPlayerDelegate {
    enum Event: Equatable {
        case willStartDownloading
        case didStartDownloadingAudioFiles
        case onPlayingStarted
        case onPlaybackPaused
        case onPlaybackResumed
        case onPlaying(AyahNumber)
        case onFailedDownloading
        case onFailedPlayback
        case onPlaybackOrDownloadingCompleted
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

    var willStartDownloadingBlock: (() -> Void)?
    func willStartDownloading() {
        events.sync { $0.append(.willStartDownloading) }
        willStartDownloadingBlock?()
    }

    var didStartDownloadingAudioFiles: ((AnyPublisher<DownloadProgress, Never>) -> Void)?
    func didStartDownloadingAudioFiles(progress: AnyPublisher<DownloadProgress, Never>) {
        events.sync { $0.append(.didStartDownloadingAudioFiles) }
        didStartDownloadingAudioFiles?(progress)
    }

    var onPlayingStartedBlock: (() -> Void)?
    func onPlayingStarted() {
        events.sync { $0.append(.onPlayingStarted) }
        onPlayingStartedBlock?()
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

    var onFailedDownloadingWithErrorBlock: ((Error) -> Void)?
    func onFailedDownloadingWithError(_ error: Error) {
        events.sync { $0.append(.onFailedDownloading) }
        onFailedDownloadingWithErrorBlock?(error)
    }

    var onFailedPlaybackWithErrorBlock: ((Error) -> Void)?
    func onFailedPlaybackWithError(_ error: Error) {
        events.sync { $0.append(.onFailedPlayback) }
        onFailedPlaybackWithErrorBlock?(error)
    }

    var onPlaybackOrDownloadingCompletedBlock: (() -> Void)?
    func onPlaybackOrDownloadingCompleted() {
        events.sync { $0.append(.onPlaybackOrDownloadingCompleted) }
        onPlaybackOrDownloadingCompletedBlock?()
    }
}
