//
//  AudioRequest.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

public struct AudioRequest: Equatable, Sendable {
    public let files: [AudioFile]
    public let endTime: TimeInterval?
    public let frameRuns: Runs
    public let requestRuns: Runs
    public init(files: [AudioFile], endTime: TimeInterval?, frameRuns: Runs, requestRuns: Runs) {
        self.files = files
        self.endTime = endTime
        self.frameRuns = frameRuns
        self.requestRuns = requestRuns
    }
}

public struct AudioFile: Equatable, Sendable {
    public let url: URL
    public let frames: [AudioFrame]
    public init(url: URL, frames: [AudioFrame]) {
        self.url = url
        self.frames = frames
    }
}

public struct AudioFrame: Equatable, Sendable {
    public let startTime: TimeInterval
    public let endTime: TimeInterval?
    public init(startTime: TimeInterval, endTime: TimeInterval?) {
        self.startTime = startTime
        self.endTime = endTime
    }
}
