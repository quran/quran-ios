//
//  SearchResults.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//

import QuranKit

public struct SearchResult: Equatable {
    public let text: String
    public let ayah: AyahNumber

    public init(text: String, ayah: AyahNumber) {
        self.text = text
        self.ayah = ayah
    }
}

public struct SearchResults: Equatable {
    public enum Source: Equatable {
        case quran
        case translation(Translation)

        public var name: String {
            switch self {
            case .quran: return "Quran"
            case .translation: return "Translation"
            }
        }
    }

    public let source: Source
    public let items: [SearchResult]

    public init(source: Source, items: [SearchResult]) {
        self.source = source
        self.items = items
    }
}
