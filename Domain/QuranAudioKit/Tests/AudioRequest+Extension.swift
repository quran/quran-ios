//
//  AudioRequest+Extension.swift
//
//
//  Created by Mohamed Afifi on 2022-02-10.
//

import Foundation
@testable import QueuePlayer

extension AudioRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case files
        case endTime
        case frameRuns
        case requestRuns
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(files, forKey: .files)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(frameRuns, forKey: .frameRuns)
        try container.encode(requestRuns, forKey: .requestRuns)
    }
}

extension AudioFile: Encodable {
    enum CodingKeys: String, CodingKey {
        case frames
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frames, forKey: .frames)
        try container.encode(url.path.replacingOccurrences(of: FileManager.documentsPath, with: ""), forKey: .url)
    }
}

extension AudioFrame: Encodable {
    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}

extension Runs: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(maxRuns)
    }
}
