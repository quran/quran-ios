//
//  AudioRequest+Extension.swift
//
//
//  Created by Mohamed Afifi on 2022-02-10.
//

import Foundation
@testable import QueuePlayer

struct EncodableAudioRequest: Encodable {
    // MARK: Lifecycle

    init(request: AudioRequest) {
        self.request = request
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case files
        case endTime
        case frameRuns
        case requestRuns
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request.files.map(EncodableAudioFile.init), forKey: .files)
        try container.encode(request.endTime, forKey: .endTime)
        try container.encode(EncodableRuns(runs: request.frameRuns), forKey: .frameRuns)
        try container.encode(EncodableRuns(runs: request.requestRuns), forKey: .requestRuns)
    }

    // MARK: Private

    private let request: AudioRequest
}

private struct EncodableAudioFile: Encodable {
    // MARK: Lifecycle

    init(file: AudioFile) {
        self.file = file
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case frames
        case url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(file.frames.map(EncodableAudioFrame.init), forKey: .frames)
        try container.encode(file.url.path.replacingOccurrences(of: FileManager.documentsPath, with: ""), forKey: .url)
    }

    // MARK: Private

    private let file: AudioFile
}

private struct EncodableAudioFrame: Encodable {
    // MARK: Lifecycle

    init(frame: AudioFrame) {
        self.frame = frame
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frame.startTime, forKey: .startTime)
        try container.encode(frame.endTime, forKey: .endTime)
    }

    // MARK: Private

    private let frame: AudioFrame
}

private struct EncodableRuns: Encodable {
    // MARK: Lifecycle

    init(runs: Runs) {
        self.runs = runs
    }

    // MARK: Internal

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(runs.maxRuns)
    }

    // MARK: Private

    private let runs: Runs
}
