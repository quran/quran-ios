//
//  SilentAudioFiles.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import AVFoundation
import XCTest

/// Writes short silent audio files into a temporary directory.
struct SilentAudioFiles {
    // MARK: Lifecycle

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: Internal

    let directory: URL

    func make(duration: TimeInterval) throws -> URL {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        buffer.frameLength = frameCount
        buffer.floatChannelData?[0].update(repeating: 0, count: Int(frameCount))

        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }

    func removeAll() throws {
        try FileManager.default.removeItem(at: directory)
    }
}
