//
//  SearchResults.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//

import QuranKit

public struct SearchResult: Equatable {
    // MARK: Lifecycle

    public init(text: String, ayah: AyahNumber) {
        self.text = text
        self.ayah = ayah
    }

    // MARK: Public

    public let text: String
    public let ayah: AyahNumber
}

public struct SearchResults: Equatable {
    // MARK: Lifecycle

    public init(source: Source, items: [SearchResult]) {
        self.source = source
        self.items = items
    }

    // MARK: Public

    public enum Source: Equatable {
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

    public let source: Source
    public let items: [SearchResult]
}
