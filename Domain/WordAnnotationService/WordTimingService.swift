//
//  WordTimingService.swift
//  Quran
//
//  Created for Quran.com iOS app.
//

import Foundation
import QuranAudio
import QuranKit

/// Fetches word-level audio timing segments from the QuranCDN API.
public struct WordTimingService {
    // MARK: Public

    /// Returns segments `[word_number, start_ms, end_ms]` keyed by verse.
    /// Example: verse "2:5" → [[1, 0, 500], [2, 500, 1200]]
    public func segments(for reciter: Reciter, chapter: Int) async throws -> [String: [[Int]]] {
        guard case .gapless(let databaseName) = reciter.audioType else { return [:] }
        // Map the local reciter database name to a QuranCDN reciter ID.
        let reciterID = reciterIDMap[databaseName] ?? 7 // default: Mishari Al-Afasy
        let url = URL(string: "https://api.qurancdn.com/api/qdc/audio/reciters/\(reciterID)/audio_files?chapter=\(chapter)&segments=true")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(SegmentsResponse.self, from: data)
        var result: [String: [[Int]]] = [:]
        for file in decoded.audioFiles {
            for timing in file.verseTimings {
                result[timing.verseKey] = timing.segments
            }
        }
        return result
    }

    // MARK: Private

    // Maps local reciter database folder names to QuranCDN reciter IDs.
    private let reciterIDMap: [String: Int] = [
        "Husary": 3,
        "Minshawi_Murattal_Ibrahim": 6,
        "Alafasy": 7,
        "AbdulBaset_Murattal": 1,
        "Hudhaify": 4,
        "Menshawi": 6,
    ]
}

// MARK: - Response models

private struct SegmentsResponse: Decodable {
    let audioFiles: [AudioFileSegment]

    enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
    }
}

private struct AudioFileSegment: Decodable {
    let verseTimings: [VerseTiming]

    enum CodingKeys: String, CodingKey {
        case verseTimings = "verse_timings"
    }
}

private struct VerseTiming: Decodable {
    let verseKey: String
    /// Each element is [word_number, start_ms, end_ms]
    let segments: [[Int]]

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case segments
    }
}
