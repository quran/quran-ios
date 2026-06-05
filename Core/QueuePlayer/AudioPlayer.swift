//
//  AudioPlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import Timing

@MainActor
class AudioPlayer {
    // MARK: Lifecycle

    init(request: AudioRequest, rate: Float) {
        self.request = request
        playbackRate = rate
        audioPlaying = AudioPlaying(request: request, fileIndex: 0, frameIndex: 0)
        player = Player(url: request.files[0].url)
        player.onRateChanged = { [weak self] in
            self?.rateChanged(to: $0)
        }
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
        timer?.resume()
        player.play(rate: playbackRate)
    }

    func pause() {
        cancelVerseDelay()
        timer?.pause()
        player.pause()
    }

    func stop() {
        cancelVerseDelay()
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
    private var audioPlaying: AudioPlaying
    private var playbackRate: Float

    // True while waiting out a between-verse delay (player paused, no frame playing).
    private var isDelaying = false

    private var player: Player {
        didSet {
            player.onRateChanged = { [weak self] in
                self?.rateChanged(to: $0)
            }
        }
    }

    private var timer: Timing.Timer? {
        didSet { oldValue?.cancel() }
    }

    private var delayTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    // MARK: - Repeat Logic

    private func play(fileIndex: Int, frameIndex: Int, forceSeek: Bool) {
        let oldFileIndex = audioPlaying.filePlaying.fileIndex
        let oldFrameIndex = audioPlaying.framePlaying.frameIndex

        let shouldSeek = forceSeek || oldFileIndex != fileIndex || frameIndex - 1 != oldFrameIndex

        // update the model
        audioPlaying.setPlaying(fileIndex: fileIndex, frameIndex: frameIndex)

        // reload player if the seek will change
        if shouldSeek {
            player = Player(url: request.files[fileIndex].url)
        }

        // if not a continuous play, adjust the seek
        var currentTime: TimeInterval?
        if shouldSeek {
            seek(to: audioPlaying.frame)
            currentTime = audioPlaying.frame.startTime
        }

        // start playing
        resume()

        // wait until frame ends
        waitUntilFrameEnds(currentTime: currentTime)

        // inform the delegate of a frame changed
        actions?.audioFrameChanged(fileIndex, frameIndex, player.playerItem)
    }

    private func onFrameEnded() {
        let time = getDurationToFrameEnd()
        // make sure we reached the end of the frame
        // don't use `abs` since we could be notified a little bit after
        guard time < 0.2 else {
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
        let delay = verseDelayDuration()

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
                    playAfterVerseDelay(delay) { [weak self] in
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
    private func verseDelayDuration() -> TimeInterval {
        let multiplier = request.verseDelay.multiplier
        guard multiplier > 0 else {
            return 0
        }
        let frameStart = audioPlaying.frame.startTime
        let frameEnd = audioPlaying.frameEndTime ?? player.duration
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
        isDelaying = true
        player.pause()
        delayTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self else {
                return
            }
            isDelaying = false
            action()
        }
    }

    private func cancelVerseDelay() {
        isDelaying = false
        delayTask = nil
    }

    private func waitUntilFrameEnds(currentTime: TimeInterval? = nil) {
        if !player.isPlaying {
            return
        }

        // max with 100ms since sometimes the returned value could be negative
        let mediaDelta = max(0, getDurationToFrameEnd(currentTime: currentTime))
        // Convert media time to wall-clock time
        let interval = max(0.05, mediaDelta / Double(playbackRate)) // small floor for stability
        timer = Timer(interval: interval, queue: .main) { [weak self] in
            self?.timer = nil
            self?.onFrameEnded()
        }
    }

    // MARK: - PlayerDelegate

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

    private func getDurationToFrameEnd(currentTime: TimeInterval? = nil) -> TimeInterval {
        let currentTimeInSeconds = currentTime ?? player.currentTime
        let frameEndTime = audioPlaying.frameEndTime ?? player.duration
        return frameEndTime - currentTimeInSeconds
    }
}
