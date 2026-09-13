#if QURAN_SYNC
//
//  AyahAnnotation.swift
//

public enum AyahAnnotation: Hashable, Sendable, Identifiable {
    case readingBookmark(ReadingBookmarkSlot)
    case collection
    case note

    public var id: AyahAnnotation {
        return self
    }
}

#endif
