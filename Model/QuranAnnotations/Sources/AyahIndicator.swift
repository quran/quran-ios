#if QURAN_SYNC
//
//  AyahIndicator.swift
//

public enum AyahIndicator: Hashable, Sendable, Identifiable {
    case readingBookmark(ReadingBookmarkSlot)
    case collection
    case note

    public var id: AyahIndicator {
        return self
    }
}

#endif
