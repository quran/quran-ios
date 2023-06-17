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
    var actions: QueuePlayerActions?

    private let interruptionMonitor = AudioInterruptionMonitor()
    private let request: AudioRequest
    private var audioPlaying: AudioPlaying
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

    init(request: AudioRequest) {
        self.request = request
        audioPlaying = AudioPlaying(request: request, fileIndex: 0, frameIndex: 0)
        player = Player(url: request.files[0].url)
        interruptionMonitor.onAudioInterruption = { [weak self] in
            self?.onAudioInterruption(type: $0)
        }
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
        // max with 100ms since sometimes the returned value could be negative
        let interval = max(0.1, getDurationToFrameEnd(currentTime: currentTime))
        timer = Timer(interval: interval, queue: .main) { [weak self] in
            self?.timer = nil
            self?.onFrameEnded()
        }
    }

    // MARK: - PlayerDelegate

    private func rateChanged(to rate: Float) {
        actions?.playbackRateChanged(rate)
    }

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
        player.play()
    }

    func pause() {
        timer?.pause()
        player.pause()
    }

    private func isPaused(rate: Float) -> Bool {
        rate < 0.1
    }

    func stop() {
        timer?.cancel()
        player.stop()
        actions?.playbackEnded()
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
