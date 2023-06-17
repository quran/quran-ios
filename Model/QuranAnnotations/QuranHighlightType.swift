//
//  QuranHighlightType.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//

import QuranKit

public typealias HighlightedVerse = (type: QuranHighlightType, verse: AyahNumber)
public typealias VerseHighlights = [QuranHighlightType.Name: [HighlightedVerse]]

extension VerseHighlights {
    public func versesByHighlights() -> [AyahNumber: QuranHighlightType] {
        var versesByHighlights: [AyahNumber: QuranHighlightType] = [:]
        for type in QuranHighlightType.sortedTypes.reversed() {
            let verses = self[type]
            for highlightedVerse in verses ?? [] {
                versesByHighlights[highlightedVerse.verse] = highlightedVerse.type
            }
        }
        return versesByHighlights
    }

    public func firstScrollingToVerse() -> AyahNumber? {
        for highlightType in QuranHighlightType.scrollingTypes {
            if let firstAyah = self[highlightType]?.first {
                return firstAyah.verse
            }
        }
        return nil
    }
}

public enum QuranHighlightType {
    case reading
    case share
    case note(Note.Color)
    case search
    case word

    // MARK: Public

    public enum Name: Hashable {
        case reading
        case share
        case note
        case search
        case word
    }

    // MARK: Internal

    var raw: Name {
        switch self {
        case .reading: return .reading
        case .share: return .share
        case .note: return .note
        case .search: return .search
        case .word: return .word
        }
    }
}

private extension QuranHighlightType {
    static let sortedTypes: [QuranHighlightType.Name] = [.word, .share, .reading, .search, .note]
}

extension QuranHighlightType {
    public static let scrollingTypes: [QuranHighlightType.Name] = [.reading, .search]
}
