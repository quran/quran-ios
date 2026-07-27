//
//  SearchResults.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//

import QuranKit

public enum SearchText: Hashable, Sendable {
    case plain(String)
    case quran(QuranText)

    // MARK: Public

    public var text: String {
        switch self {
        case .plain(let text):
            text
        case .quran(let text):
            text.text
        }
    }
}

public struct SearchResult: Hashable, Identifiable {
    // MARK: Lifecycle

    public init(text: String, ranges: [Range<String.Index>], ayah: AyahNumber) {
        self.init(text: .plain(text), ranges: ranges, ayah: ayah)
    }

    public init(text: QuranText, ranges: [Range<String.Index>], ayah: AyahNumber) {
        self.init(text: .quran(text), ranges: ranges, ayah: ayah)
    }

    public init(text: SearchText, ranges: [Range<String.Index>], ayah: AyahNumber) {
        self.text = text
        self.ranges = ranges
        self.ayah = ayah
    }

    // MARK: Public

    public let text: SearchText
    public let ranges: [Range<String.Index>]
    public let ayah: AyahNumber

    public var id: Self { self }
}

public struct SearchResults: Equatable, Identifiable {
    public enum Source: Hashable, Comparable {
        case quran
        case translation(Translation)

        // MARK: Public

        public var name: String {
            switch self {
            case .quran: return "Quran"
            case .translation: return "Translation"
            }
        }
    }

    // MARK: Lifecycle

    public init(source: Source, items: [SearchResult]) {
        self.source = source
        self.items = items
    }

    // MARK: Public

    public let source: Source
    public let items: [SearchResult]

    public var id: Source { source }
}
