//
//  Player.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 5/4/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

@MainActor
final class Player {
    // MARK: Lifecycle

    deinit {
        rateObservation?.invalidate()
        statusObservation?.invalidate()
        if let endObservation {
            NotificationCenter.default.removeObserver(endObservation)
        }
        if let failureObservation {
            NotificationCenter.default.removeObserver(failureObservation)
        }
        durationTask?.cancel()
        // Releasing `asset` stops its remote load once no other player shares it.
    }

    init(asset: PlayerAsset, knownDuration: TimeInterval? = nil) {
        self.asset = asset
        playerItem = AVPlayerItem(asset: asset.urlAsset)
        playerItem.audioTimePitchAlgorithm = .spectral
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false

        rateObservation = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] _, change in
            if let rate = change.newValue {
                guard let self else { return }
                Task {
                    await self.onRateChanged?(rate)
                }
            }
        }

        endObservation = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onPlayedToEnd?()
            }
        }

        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            let error = item.error ?? PlaybackError.failed
            Task { @MainActor [weak self] in
                self?.onFailed?(error)
            }
        }
        failureObservation = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error ?? PlaybackError.failed
            MainActor.assumeIsolated {
                self?.onFailed?(error)
            }
        }

        if let knownDuration {
            duration = knownDuration
            return
        }

        // Even an estimated duration reads the file's start (streaming, over the network),
        // so never read it synchronously on the main thread.
        // Capture only the `AVURLAsset`: holding `asset` would keep its remote load from being cancelled.
        let urlAsset = asset.urlAsset
        durationTask = Task { [weak self] in
            do {
                let duration = Self.seconds(ofLoadedDuration: try await urlAsset.load(.duration))
                guard !Task.isCancelled, let self else { return }
                guard duration > 0 else {
                    onFailed?(PlaybackError.failed)
                    return
                }
                self.duration = duration
                onDurationLoaded?(duration)
            } catch {
                guard !Task.isCancelled else { return }
                self?.onFailed?(error)
            }
        }
    }

    // MARK: Internal

    var onRateChanged: (@Sendable @MainActor (Float) -> Void)?
    var onDurationLoaded: (@Sendable @MainActor (TimeInterval) -> Void)?
    var onPlayedToEnd: (@Sendable @MainActor () -> Void)?
    var onFailed: (@Sendable @MainActor (Error) -> Void)?

    let asset: PlayerAsset
    let playerItem: AVPlayerItem

    /// The file's duration, or `nil` while it loads.
    private(set) var duration: TimeInterval?

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    /// Zero for a failed or non-numeric load, which the caller treats as a playback failure. The load returns
    /// `.indefinite` without throwing, e.g. when a server doesn't answer the byte-range probe with a 206.
    static func seconds(ofLoadedDuration duration: CMTime?) -> TimeInterval {
        guard let duration, duration.isNumeric else {
            return 0
        }
        return duration.seconds
    }

    // MARK: Internal helpers (read-only)

    var isPlaying: Bool {
        player.rate != 0
    }

    func waitUntilReady() async throws {
        try Task.checkCancellation()
        guard !isStopped else { throw CancellationError() }
        let (stream, continuation) = AsyncThrowingStream<Void, Error>.makeStream()
        let waiterID = UUID()
        readinessWaiters[waiterID] = continuation
        let observation = playerItem.observe(\.status, options: [.initial, .new]) { item, _ in
            switch item.status {
            case .readyToPlay:
                continuation.yield(())
                continuation.finish()
            case .failed:
                continuation.finish(throwing: item.error ?? PlaybackError.failed)
            case .unknown:
                break
            @unknown default:
                continuation.finish(throwing: PlaybackError.failed)
            }
        }
        let timeout = Task {
            try await Task.sleep(nanoseconds: 15_000_000_000)
            continuation.finish(throwing: PlaybackError.readinessTimedOut)
        }
        defer {
            readinessWaiters.removeValue(forKey: waiterID)
            observation.invalidate()
            timeout.cancel()
        }
        for try await _ in stream {
            try Task.checkCancellation()
            return
        }
        throw CancellationError()
    }

    func play(rate: Float) {
        player.playImmediately(atRate: rate)
    }

    func pause() {
        player.pause()
    }

    func stop(error: Error = CancellationError()) {
        isStopped = true
        player.pause()
        for continuation in readinessWaiters.values {
            continuation.finish(throwing: error)
        }
        readinessWaiters.removeAll()
    }

    func setRate(_ rate: Float) {
        player.rate = rate
    }

    func seek(to timeInSeconds: TimeInterval, rate: Float) {
        pause()
        player.seek(to: timeInSeconds)
        play(rate: rate)
    }

    // MARK: Private

    private let player: AVPlayer
    private var isStopped = false
    private var readinessWaiters: [UUID: AsyncThrowingStream<Void, Error>.Continuation] = [:]

    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }

    private var endObservation: NSObjectProtocol?
    private var failureObservation: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?

    private var durationTask: Task<Void, Never>?
}

private extension AVPlayer {
    func seek(to timeInSeconds: TimeInterval) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        seek(to: time)
    }
}
