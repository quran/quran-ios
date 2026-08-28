//
//  WordSegmentTimeline.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

/// One sura's word spans, ordered by start time, queried by playback position.
public struct WordSegmentTimeline: Sendable, Equatable {
    // MARK: Lifecycle

    public init(segments: [WordSegment]) {
        // Swift's sort is not stable and the primary key permits two rows to share a
        // start time, so the tie-breakers keep the order reproducible.
        self.segments = segments.sorted {
            ($0.startMs, $0.endMs, $0.ayah, $0.position) < ($1.startMs, $1.endMs, $1.ayah, $1.position)
        }
    }

    // MARK: Public

    public static let empty = WordSegmentTimeline(segments: [])

    public let segments: [WordSegment]

    public var isEmpty: Bool {
        segments.isEmpty
    }

    /// The span covering `millis`, or nil between two words.
    ///
    /// Assumes spans do not overlap, so the last one starting at or before `millis` is the
    /// only candidate. Overlapping data returns nil rather than a wrong word.
    public func segment(atMillis millis: Int) -> WordSegment? {
        var low = 0
        var high = segments.count - 1
        var candidate: WordSegment?
        while low <= high {
            let mid = low + (high - low) / 2
            let segment = segments[mid]
            if segment.startMs <= millis {
                candidate = segment
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return candidate.flatMap { $0.contains(millis: millis) ? $0 : nil }
    }
}
