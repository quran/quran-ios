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

    init(request: AudioRequest) {
        self.request = request
        audioPlaying = AudioPlaying(request: request, fileIndex: 0, frameIndex: 0)
        player = Player(url: request.files[0].url)
        player.onRateChanged = { [weak self] in
            self?.rateChanged(to: $0)
        }
        player.setRate(playbackRate)
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
        // apply any pending rate before resuming playback
        if let r = pendingRate {
            playbackRate = r
            pendingRate = nil
            player.setRate(r)
            actions?.playbackRateChanged(r)
        }
        timer?.resume()
        player.play()
    }

    func pause() {
        isPaused = true
        timer?.pause()
        player.pause()
    }

    func stop() {
        isPaused = true
        timer?.cancel()
        player.stop()
        actions?.playbackEnded()
    }
    
    func setRate(_ rate: Float) {
        playbackRate = rate
        player.setRate(rate)
        actions?.playbackRateChanged(rate)

        // if currently playing, re-schedule the end of the current frame using the new rate
        if player.isPlaying, rate > 0 {
            timer?.cancel()
            waitUntilFrameEnds()
        } else {
            pendingRate = nil
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
    private var playbackRate: Float = 1.0
    private var isPaused = false
    private var pendingRate: Float?

    private var player: Player {
        didSet {
            player.onRateChanged = { [weak self] in
                self?.rateChanged(to: $0)
            }
            // keep rate consistent across newly created AVPlayer instances
            player.setRate(playbackRate)
        }
    }


    private var timer: Timing.Timer? {
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
        if audioPlaying.isLastPlayForCurrentFrame() {
            if let next = audioPlaying.nextFrame() {
                // move to next frame
                audioPlaying.resetFramePlays()
                play(fileIndex: next.fileIndex, frameIndex: next.frameIndex, forceSeek: false)
            } else { // last frame
                if audioPlaying.isLastRun() {
                    // stop
                    stop()
                } else {
                    // start a new run
                    audioPlaying.incrementRequestPlays()
                    audioPlaying.resetFramePlays()
                    play(fileIndex: 0, frameIndex: 0, forceSeek: true)
                }
            }
        } else {
            // repeat frame
            audioPlaying.incrementFramePlays()
            play(
                fileIndex: audioPlaying.filePlaying.fileIndex,
                frameIndex: audioPlaying.framePlaying.frameIndex,
                forceSeek: true
            )
        }
    }

    private func waitUntilFrameEnds(currentTime: TimeInterval? = nil) {
        // Remaining media time to the end of the frame (in seconds on the media timeline)
        let mediaDelta = max(0, getDurationToFrameEnd(currentTime: currentTime))
        // Convert media time to wall-clock time by dividing by the effective playback rate
        let rate = max(0.1, Double(player.effectiveRate))
        let interval = max(0.05, mediaDelta / rate) // small floor for stability
        timer = Timer(interval: interval, queue: .main) { [weak self] in
            self?.timer = nil
            self?.onFrameEnded()
        }
    }

    // MARK: - PlayerDelegate

    private func rateChanged(to rate: Float) {
        // keep our in-memory rate in sync with the actual player rate
        playbackRate = rate
        // if the player is actively playing and the rate changed mid-frame, re-schedule
        if player.isPlaying, rate > 0 {
            timer?.cancel()
            waitUntilFrameEnds()
        }
        actions?.playbackRateChanged(rate)
    }

    private func seek(to frame: AudioFrame) {
        player.seek(to: frame.startTime)
    }

    // MARK: - Utilities

    private func getDurationToFrameEnd(currentTime: TimeInterval? = nil) -> TimeInterval {
        let currentTimeInSeconds = currentTime ?? player.currentTime
        let frameEndTime = audioPlaying.frameEndTime ?? player.duration
        return frameEndTime - currentTimeInSeconds
    }
}
