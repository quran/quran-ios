//
//  WordSegment.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

/// A single word's span within a sura's audio file.
///
/// A word may have more than one span when the reciter repeats or elongates a passage,
/// so spans are looked up by time range rather than by position.
public struct WordSegment: Sendable, Hashable {
    // MARK: Lifecycle

    public init(sura: Int, ayah: Int, position: Int, startMs: Int, endMs: Int) {
        self.sura = sura
        self.ayah = ayah
        self.position = position
        self.startMs = startMs
        self.endMs = endMs
    }

    // MARK: Public

    public let sura: Int
    public let ayah: Int
    /// The glyph position used by `Word.wordNumber`, not the plain word index.
    public let position: Int
    public let startMs: Int
    public let endMs: Int

    /// Half-open, so a word ends exactly where the next one starts.
    public func contains(millis: Int) -> Bool {
        millis >= startMs && millis < endMs
    }
}
