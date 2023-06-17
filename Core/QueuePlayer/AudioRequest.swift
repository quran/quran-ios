//
//  AudioRequest.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

public struct AudioRequest: Equatable, Sendable {
    // MARK: Lifecycle

    public init(files: [AudioFile], endTime: TimeInterval?, frameRuns: Runs, requestRuns: Runs) {
        self.files = files
        self.endTime = endTime
        self.frameRuns = frameRuns
        self.requestRuns = requestRuns
    }

    // MARK: Public

    public let files: [AudioFile]
    public let endTime: TimeInterval?
    public let frameRuns: Runs
    public let requestRuns: Runs
}

public struct AudioFile: Equatable, Sendable {
    // MARK: Lifecycle

    public init(url: URL, frames: [AudioFrame]) {
        self.url = url
        self.frames = frames
    }

    // MARK: Public

    public let url: URL
    public let frames: [AudioFrame]
}

public struct AudioFrame: Equatable, Sendable {
    // MARK: Lifecycle

    public init(startTime: TimeInterval, endTime: TimeInterval?) {
        self.startTime = startTime
        self.endTime = endTime
    }

    // MARK: Public

    public let startTime: TimeInterval
    public let endTime: TimeInterval?
}
