//
//  SearchResults.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//

import QuranKit

public struct SearchResult: Hashable, Identifiable {
    // MARK: Lifecycle

    public init(text: String, ranges: [Range<String.Index>], ayah: AyahNumber) {
        self.text = text
        self.ranges = ranges
        self.ayah = ayah
    }

    // MARK: Public

    public let text: String
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
