//
//  ReciterWordSegmentRetriever.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import AudioTimingPersistence
import Foundation
import QuranAudio
import QuranKit

public struct ReciterWordSegmentRetriever {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    /// A sura's word spans, from the same database as the reciter's ayah timings.
    ///
    /// Gapped reciters have no database, and a database predating word-by-word data has no
    /// such table; both are an empty timeline rather than an error.
    public func wordSegments(for reciter: Reciter, sura: Sura) async throws -> WordSegmentTimeline {
        guard let filePath = reciter.localDatabasePath else {
            return .empty
        }
        return try await persistenceFactory(filePath.url).timeline(forSura: sura.suraNumber)
    }

    // MARK: Internal

    let persistenceFactory: (URL) -> WordSegmentPersistence = WordSegmentPersistence.init
}
