//
//  WordSegmentPersistenceTests.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import Foundation
import QuranAudio
import XCTest
@testable import AudioTimingPersistence

final class WordSegmentPersistenceTests: XCTestCase {
    // MARK: Internal

    func testLoadsASurasSegmentsInStartOrder() async throws {
        let timeline = try await persistence.timeline(forSura: 1)

        XCTAssertEqual(timeline.segments, [
            WordSegment(sura: 1, ayah: 1, position: 1, startMs: 1000, endMs: 1500),
            WordSegment(sura: 1, ayah: 1, position: 2, startMs: 1500, endMs: 2000),
            WordSegment(sura: 1, ayah: 1, position: 3, startMs: 2500, endMs: 3000),
            WordSegment(sura: 1, ayah: 2, position: 1, startMs: 3000, endMs: 3600),
        ])
    }

    func testLoadsOnlyTheRequestedSura() async throws {
        let timeline = try await persistence.timeline(forSura: 2)

        XCTAssertEqual(timeline.segments, [
            WordSegment(sura: 2, ayah: 1, position: 1, startMs: 500, endMs: 900),
            WordSegment(sura: 2, ayah: 1, position: 2, startMs: 900, endMs: 1400),
        ])
    }

    /// Most suras have no word timings, so this is the common path, not an edge case.
    func testUncoveredSuraLoadsAnEmptyTimeline() async throws {
        let timeline = try await persistence.timeline(forSura: 3)

        XCTAssertTrue(timeline.isEmpty)
        XCTAssertNil(timeline.segment(atMillis: 1200))
    }

    func testLoadedTimelineResolvesWordsByPlaybackPosition() async throws {
        let timeline = try await persistence.timeline(forSura: 1)

        XCTAssertEqual(timeline.segment(atMillis: 1200)?.position, 1)
        XCTAssertEqual(timeline.segment(atMillis: 1500)?.position, 2)
        // The silence between the second and third words.
        XCTAssertNil(timeline.segment(atMillis: 2100))
        XCTAssertEqual(timeline.segment(atMillis: 3100)?.ayah, 2)
    }

    /// Every reciter timing database in the wild predates word-by-word data, so a missing
    /// table has to read as "nothing to follow" rather than as an error.
    func testReciterDatabaseWithoutASegmentsTableLoadsAnEmptyTimeline() async throws {
        let persistence = WordSegmentPersistence(fileURL: fixtureURL(named: "reciter_without_segments"))

        let timeline = try await persistence.timeline(forSura: 1)

        XCTAssertTrue(timeline.isEmpty)
    }

    // MARK: Private

    private var persistence: WordSegmentPersistence {
        WordSegmentPersistence(fileURL: fixtureURL(named: "word_segments"))
    }

    private func fixtureURL(named name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "db")!
    }
}
