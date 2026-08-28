//
//  WordSegmentTimelineTests.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import XCTest
@testable import QuranAudio

final class WordSegmentTimelineTests: XCTestCase {
    // MARK: Internal

    func testEmptyTimelineFindsNothing() {
        let timeline = WordSegmentTimeline.empty

        XCTAssertTrue(timeline.isEmpty)
        XCTAssertNil(timeline.segment(atMillis: 0))
        XCTAssertNil(timeline.segment(atMillis: 1500))
    }

    func testOrdersSegmentsByStartTime() {
        let timeline = WordSegmentTimeline(segments: [second, third, first])

        XCTAssertEqual(timeline.segments, [first, second, third])
    }

    /// Out-of-order input must still be searchable, because the binary search assumes order.
    func testFindsSegmentsWhenBuiltFromUnorderedInput() {
        let timeline = WordSegmentTimeline(segments: [third, first, second])

        XCTAssertEqual(timeline.segment(atMillis: 1200), first)
        XCTAssertEqual(timeline.segment(atMillis: 1700), second)
        XCTAssertEqual(timeline.segment(atMillis: 2700), third)
    }

    func testFindsSegmentAtItsStart() {
        XCTAssertEqual(timeline.segment(atMillis: 1000), first)
    }

    func testFindsSegmentInsideItsSpan() {
        XCTAssertEqual(timeline.segment(atMillis: 1499), first)
    }

    /// Spans are half-open, so the boundary belongs to the word that is starting.
    func testSpanEndBelongsToTheNextWord() {
        XCTAssertEqual(timeline.segment(atMillis: 1500), second)
    }

    func testFindsNothingBeforeTheFirstWord() {
        XCTAssertNil(timeline.segment(atMillis: 0))
        XCTAssertNil(timeline.segment(atMillis: 999))
    }

    func testFindsNothingAfterTheLastWord() {
        XCTAssertNil(timeline.segment(atMillis: 3000))
        XCTAssertNil(timeline.segment(atMillis: 10000))
    }

    /// The silence between two words must report nothing rather than holding the
    /// previous word, which is what lets the follower decide to keep the highlight.
    func testFindsNothingInTheGapBetweenWords() {
        XCTAssertNil(timeline.segment(atMillis: 2000))
        XCTAssertNil(timeline.segment(atMillis: 2250))
        XCTAssertNil(timeline.segment(atMillis: 2499))
    }

    func testFindsEveryWordOfALongTimeline() {
        let segments = (0 ..< 500).map {
            WordSegment(sura: 2, ayah: 1, position: $0 + 1, startMs: $0 * 100, endMs: $0 * 100 + 60)
        }
        let timeline = WordSegmentTimeline(segments: segments)

        for segment in segments {
            XCTAssertEqual(timeline.segment(atMillis: segment.startMs), segment)
            XCTAssertEqual(timeline.segment(atMillis: segment.endMs - 1), segment)
            // The 40ms of silence that follows each word.
            XCTAssertNil(timeline.segment(atMillis: segment.endMs))
        }
    }

    /// A reciter who repeats a passage produces two spans for the same word.
    func testResolvesRepeatedWordsByTime() {
        let firstPass = WordSegment(sura: 1, ayah: 1, position: 1, startMs: 0, endMs: 500)
        let secondPass = WordSegment(sura: 1, ayah: 1, position: 1, startMs: 4000, endMs: 4500)
        let timeline = WordSegmentTimeline(segments: [firstPass, secondPass])

        XCTAssertEqual(timeline.segment(atMillis: 100), firstPass)
        XCTAssertNil(timeline.segment(atMillis: 2000))
        XCTAssertEqual(timeline.segment(atMillis: 4100), secondPass)
    }

    // MARK: Private

    private let first = WordSegment(sura: 1, ayah: 1, position: 1, startMs: 1000, endMs: 1500)
    private let second = WordSegment(sura: 1, ayah: 1, position: 2, startMs: 1500, endMs: 2000)
    private let third = WordSegment(sura: 1, ayah: 1, position: 3, startMs: 2500, endMs: 3000)

    private var timeline: WordSegmentTimeline {
        WordSegmentTimeline(segments: [first, second, third])
    }
}
