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

    /// A constant-bitrate MP3 of silent frames, then `trailingBytes` zero bytes that hold no audio.
    /// Without precise timing, AVFoundation estimates the duration from the file's size and
    /// bitrate, so the trailing bytes make the estimate run past the audio.
    func makeMP3(duration: TimeInterval, trailingBytes: Int = 0) throws -> URL {
        // MPEG-1 Layer III, 128 kbps, 48 kHz, mono, no CRC: 384-byte frames of 24 ms each.
        // A zeroed side info and main data decode as silence.
        var frame = [UInt8](repeating: 0, count: 384)
        frame[0 ..< 4] = [0xFF, 0xFB, 0x94, 0xC0]
        let frameCount = Int((duration / 0.024).rounded())
        var data = Data(capacity: frameCount * frame.count + trailingBytes)
        for _ in 0 ..< frameCount {
            data.append(contentsOf: frame)
        }
        data.append(Data(count: trailingBytes))

        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
        try data.write(to: url)
        return url
    }

    func removeAll() throws {
        try FileManager.default.removeItem(at: directory)
    }
}
