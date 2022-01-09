//
//  AudioPlaying.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

struct FramePlaying {
    var frameIndex: Int
    var framePlays: Int
}

struct FilePlaying {
    let fileIndex: Int

    init(fileIndex: Int) {
        self.fileIndex = fileIndex
    }
}

struct AudioPlaying {
    let request: AudioRequest
    private(set) var filePlaying: FilePlaying
    private(set) var framePlaying: FramePlaying
    var requestPlays: Int

    init(request: AudioRequest, fileIndex: Int, frameIndex: Int) {
        self.request = request
        filePlaying = FilePlaying(fileIndex: fileIndex)
        framePlaying = FramePlaying(frameIndex: frameIndex, framePlays: 0)
        requestPlays = 0
    }

    mutating func setPlaying(fileIndex: Int, frameIndex: Int) {
        filePlaying = FilePlaying(fileIndex: fileIndex)
        framePlaying.frameIndex = frameIndex
    }

    var file: AudioFile {
        request.files[filePlaying.fileIndex]
    }

    var frame: AudioFrame {
        file.frames[framePlaying.frameIndex]
    }

    func isLastPlayForCurrentFrame() -> Bool {
        framePlaying.framePlays + 1 >= request.frameRuns.maxRuns
    }

    func isLastRun() -> Bool {
        requestPlays + 1 >= request.requestRuns.maxRuns
    }

    mutating func incrementRequestPlays() {
        guard request.requestRuns != .indefinite else {
            return
        }
        requestPlays += 1
    }

    mutating func incrementFramePlays() {
        guard request.frameRuns != .indefinite else {
            return
        }
        framePlaying.framePlays += 1
    }

    mutating func resetFramePlays() {
        framePlaying.framePlays = 0
    }

    func previousFrame() -> (fileIndex: Int, frameIndex: Int)? {
        // same file
        if framePlaying.frameIndex > 0 {
            return (filePlaying.fileIndex, framePlaying.frameIndex - 1)
        }
        // previous file
        if filePlaying.fileIndex > 0 {
            let previousFileIndex = filePlaying.fileIndex - 1
            return (previousFileIndex, request.files[previousFileIndex].frames.count - 1)
        }
        // first frame
        return nil
    }

    func nextFrame() -> (fileIndex: Int, frameIndex: Int)? {
        // same file
        if framePlaying.frameIndex < file.frames.count - 1 {
            return (filePlaying.fileIndex, framePlaying.frameIndex + 1)
        }
        // next file
        if filePlaying.fileIndex < request.files.count - 1 {
            return (filePlaying.fileIndex + 1, 0)
        }
        // last frame
        return nil
    }

    var frameEndTime: TimeInterval? {
        if let frameEndTime = request.files[filePlaying.fileIndex].frames[framePlaying.frameIndex].endTime {
            return frameEndTime
        }

        guard let nextFrame = nextFrame() else {
            // last frame
            return request.endTime
        }
        if nextFrame.fileIndex == filePlaying.fileIndex {
            // same file
            return request.files[nextFrame.fileIndex].frames[nextFrame.frameIndex].startTime
        }
        // different file
        return nil
    }
}
