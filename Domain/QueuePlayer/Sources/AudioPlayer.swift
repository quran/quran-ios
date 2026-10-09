//
//  AudioPlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import Timing

/// Waits out a between-verse delay of the given wall-clock seconds.
typealias VerseDelaySleep = @Sendable @MainActor (TimeInterval) async -> Void

@MainActor
class AudioPlayer {
    // MARK: Lifecycle

    init(request: AudioRequest, rate: Float, sleep: @escaping VerseDelaySleep) {
        self.request = request
        playbackRate = rate
        self.sleep = sleep
        audioPlaying = AudioPlaying(request: request, fileIndex: 0, frameIndex: 0)
        interruptionMonitor.onAudioInterruption = { [weak self] in
            self?.onAudioInterruption(type: $0)
        }
    }

    // MARK: Internal

    var actions: QueuePlayerActions?

    // MARK: - Interruption

    func onAudioInterruption(type: AudioInterruptionType) {
        switch type {
        case .began: pause()
        case .endedShouldResume: resume()
        case .endedShouldNotResume: break
        }
    }

    // MARK: - Player Controls

    func startPlaying() {
        play(fileIndex: 0, frameIndex: 0, forceSeek: true)
    }

    func resume() {
        isPaused = false
        // Keep the player paused through the rest of the delay; the next frame plays after it.
        if isDelaying {
            startVerseDelayCountdown()
            // The player stays paused, so it reports no rate change of its own.
            actions?.playbackRateChanged(playbackRate)
            return
        }
        startPlayback()
        // Re-measure the frame end: a paused timer is stale after a rate change, and a system
        // pause (a route change or a stall) can leave no timer at all.
        timer = nil
        waitUntilFrameEnds()
    }

    func pause() {
        isPaused = true
        if isDelaying {
            // `rateChanged` ignores the player during a delay, so report the pause here.
            actions?.playbackRateChanged(0)
        }
        pauseVerseDelayCountdown()
        timer?.pause()
        player.pause()
    }

    func stop() {
        cancelVerseDelay()
        isWaitingForDuration = false
        timer?.cancel()
        player.stop()
        actions?.playbackEnded()
    }

    func setRate(_ rate: Float) {
        playbackRate = rate

        // Apply the rate if currently playing
        if player.isPlaying {
            player.setRate(rate)
            timer?.cancel()
            waitUntilFrameEnds()
        }
    }

    func stepForward() {
        if let next = audioPlaying.nextFrame() {
            audioPlaying.resetFramePlays()
            play(fileIndex: next.fileIndex, frameIndex: next.frameIndex, forceSeek: true)
        } else {
            // stop playback if last frame
            stop()
        }
    }

    func stepBackgward() {
        if let previous = audioPlaying.previousFrame() {
            audioPlaying.resetFramePlays()
            play(fileIndex: previous.fileIndex, frameIndex: previous.frameIndex, forceSeek: true)
        } else {
            // stop playback if first frame
            stop()
        }
    }

    // MARK: Private

    private let interruptionMonitor = AudioInterruptionMonitor()
    private let request: AudioRequest
    private let sleep: VerseDelaySleep
    private var audioPlaying: AudioPlaying
    private var playbackRate: Float

    // Set while waiting out a between-verse delay (player paused, no frame playing).
    private var verseDelayWait: VerseDelayWait?

    private var isDelaying: Bool {
        verseDelayWait != nil
    }

    // True while paused by `pause()`, so a frame-end timer scheduled meanwhile starts paused.
    private var isPaused = false

    // True while the frame ends with its file and the file's duration is still loading.
    private var isWaitingForDuration = false

    // Durations loaded so far, by file index, reused when a seek reloads the file.
    // Failed loads (zero) aren't kept, so they're retried.
    private var loadedDurations: [Int: TimeInterval] = [:]

    // `startPlaying()` replaces it before anything reads it, so the initial value is never built.
    private lazy var player = makePlayer(fileIndex: 0)

    private var timer: Timing.Timer? {
        didSet { oldValue?.cancel() }
    }

    private var delayTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private func makePlayer(fileIndex: Int) -> Player {
        let player = Player(url: request.files[fileIndex].url, knownDuration: loadedDurations[fileIndex])
        player.onRateChanged = { [weak self] in
            self?.rateChanged(to: $0)
        }
        player.onDurationLoaded = { [weak self, weak player] duration in
            // A replaced player can stay alive briefly, e.g. while its pending rate callback runs.
            guard let self, let player, player === self.player else {
                return
            }
            if duration > 0 {
                loadedDurations[fileIndex] = duration
            }
            durationLoaded(duration)
        }
        return player
    }

    // MARK: - Repeat Logic

    private func play(fileIndex: Int, frameIndex: Int, forceSeek: Bool) {
        // Playing a frame, such as after stepping, supersedes a pending delay's advance.
        cancelVerseDelay()

        let oldFileIndex = audioPlaying.filePlaying.fileIndex
        let oldFrameIndex = audioPlaying.framePlaying.frameIndex

        let shouldSeek = forceSeek || oldFileIndex != fileIndex || frameIndex - 1 != oldFrameIndex

        // update the model
        audioPlaying.setPlaying(fileIndex: fileIndex, frameIndex: frameIndex)

        // reload player if the seek will change
        if shouldSeek {
            player = makePlayer(fileIndex: fileIndex)
        }

        // if not a continuous play, adjust the seek
        var currentTime: TimeInterval?
        if shouldSeek {
            seek(to: audioPlaying.frame)
            currentTime = audioPlaying.frame.startTime
        }

        // start playing
        startPlayback()

        // wait until frame ends; after a seek, measure from its target since it may not have landed yet
        waitUntilFrameEnds(currentTime: currentTime)

        // inform the delegate of a frame changed
        actions?.audioFrameChanged(fileIndex, frameIndex, player.playerItem, player.duration)
    }

    /// Plays the current frame without scheduling its end; callers wait for the frame end themselves.
    private func startPlayback() {
        isPaused = false
        player.play(rate: playbackRate)
    }

    private func onFrameEnded() {
        // make sure we reached the end of the frame
        // don't use `abs` since we could be notified a little bit after
        guard let frameEnd = audioPlaying.frameEndTime ?? player.duration,
              frameEnd - player.currentTime < 0.2
        else {
            // audio is 200 ms behind, reschedule the timer
            waitUntilFrameEnds()
            return
        }

        // 1. Done playing the frame?
        //  1.1. Last frame?
        //   1.1.1 Done playing the request?
        //      1.1.1.1 Stop
        //   1.1.2 else Repeat the request
        //  1.2 else Run next frame
        // 2. else Repeat the frame
        // Delay before the next playback, scaled by the verse that just finished.
        let delay = verseDelayDuration(frameEnd: frameEnd)

        if audioPlaying.isLastPlayForCurrentFrame() {
            if let next = audioPlaying.nextFrame() {
                // move to next frame
                audioPlaying.resetFramePlays()
                // With no delay, keep the original continuous (no-seek) advance so
                // gapless playback stays seamless. A delay pauses the player off the
                // frame boundary, so we must re-seek when resuming.
                let forceSeek = delay > 0
                playAfterVerseDelay(delay) { [weak self] in
                    self?.play(fileIndex: next.fileIndex, frameIndex: next.frameIndex, forceSeek: forceSeek)
                }
            } else { // last frame
                if audioPlaying.isLastRun() {
                    // stop
                    stop()
                } else {
                    // start a new run
                    audioPlaying.incrementRequestPlays()
                    audioPlaying.resetFramePlays()
                    // At the repeat boundary, wait the between-verse delay for the
                    // verse that just finished plus the fixed between-repetition pause.
                    let repeatDelay = delay + request.repetitionDelay.seconds
                    playAfterVerseDelay(repeatDelay) { [weak self] in
                        self?.play(fileIndex: 0, frameIndex: 0, forceSeek: true)
                    }
                }
            }
        } else {
            // repeat frame
            audioPlaying.incrementFramePlays()
            let fileIndex = audioPlaying.filePlaying.fileIndex
            let frameIndex = audioPlaying.framePlaying.frameIndex
            playAfterVerseDelay(delay) { [weak self] in
                self?.play(fileIndex: fileIndex, frameIndex: frameIndex, forceSeek: true)
            }
        }
    }

    /// Duration to wait before the next playback, computed from the verse that
    /// just finished: its recited (wall-clock) length times the selected
    /// multiplier. Returns 0 when no delay is configured.
    private func verseDelayDuration(frameEnd: TimeInterval) -> TimeInterval {
        let multiplier = request.verseDelay.multiplier
        guard multiplier > 0 else {
            return 0
        }
        let frameStart = audioPlaying.frame.startTime
        let recitedMediaDuration = max(0, frameEnd - frameStart)
        // Convert media duration to wall-clock recited time before scaling.
        return recitedMediaDuration / Double(playbackRate) * multiplier
    }

    /// Runs `action` after pausing for `delay` wall-clock seconds. With no delay
    /// the action runs immediately, preserving the original gapless playback.
    private func playAfterVerseDelay(_ delay: TimeInterval, _ action: @escaping @MainActor () -> Void) {
        guard delay > 0 else {
            action()
            return
        }
        player.pause()
        verseDelayWait = VerseDelayWait(advance: action, remaining: delay)
        if !isPaused {
            startVerseDelayCountdown()
        }
    }

    private func startVerseDelayCountdown() {
        guard let wait = verseDelayWait, wait.countdownStart == nil else {
            return
        }
        verseDelayWait?.countdownStart = Date()
        delayTask = Task { [weak self, sleep] in
            await sleep(wait.remaining)
            guard !Task.isCancelled, let self else {
                return
            }
            verseDelayWait = nil
            wait.advance()
        }
    }

    private func pauseVerseDelayCountdown() {
        guard var wait = verseDelayWait, let countdownStart = wait.countdownStart else {
            return
        }
        delayTask = nil
        wait.remaining = max(0, wait.remaining - Date().timeIntervalSince(countdownStart))
        wait.countdownStart = nil
        verseDelayWait = wait
    }

    private func cancelVerseDelay() {
        verseDelayWait = nil
        delayTask = nil
    }

    private func waitUntilFrameEnds(currentTime: TimeInterval? = nil) {
        if !player.isPlaying {
            return
        }

        guard let mediaDelta = getDurationToFrameEnd(currentTime: currentTime) else {
            // The file's duration is still loading; `durationLoaded()` schedules the timer.
            timer = nil
            isWaitingForDuration = true
            return
        }
        isWaitingForDuration = false
        scheduleFrameEndTimer(after: mediaDelta)
    }

    private func scheduleFrameEndTimer(after mediaDelta: TimeInterval) {
        // Convert media time to wall-clock time; the 50 ms floor also covers negative deltas.
        let interval = max(0.05, mediaDelta / Double(playbackRate))
        timer = Timer(interval: interval, queue: .main) { [weak self] in
            self?.timer = nil
            self?.onFrameEnded()
        }
    }

    // MARK: - PlayerDelegate

    private func durationLoaded(_ duration: TimeInterval) {
        actions?.durationLoaded(duration)
        guard isWaitingForDuration, let mediaDelta = getDurationToFrameEnd() else {
            return
        }
        isWaitingForDuration = false
        scheduleFrameEndTimer(after: mediaDelta)
        if isPaused {
            timer?.pause()
        }
    }

    private func rateChanged(to rate: Float) {
        // Ignore the pause/resume we trigger ourselves while waiting out a delay.
        guard !isDelaying else {
            return
        }
        actions?.playbackRateChanged(rate)
    }

    private func seek(to frame: AudioFrame) {
        player.seek(to: frame.startTime, rate: playbackRate)
    }

    // MARK: - Utilities

    /// `nil` while the frame ends with its file and the file's duration is still loading.
    private func getDurationToFrameEnd(currentTime: TimeInterval? = nil) -> TimeInterval? {
        guard let frameEndTime = audioPlaying.frameEndTime ?? player.duration else {
            return nil
        }
        let currentTimeInSeconds = currentTime ?? player.currentTime
        return frameEndTime - currentTimeInSeconds
    }
}

/// A between-verse delay being waited out, and the advance to run once it elapses.
private struct VerseDelayWait {
    let advance: @MainActor () -> Void
    /// Wall-clock seconds left as of `countdownStart`.
    var remaining: TimeInterval
    /// When the countdown last started, or `nil` while paused.
    var countdownStart: Date?
}
