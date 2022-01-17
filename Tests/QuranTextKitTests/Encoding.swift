//
//  Encoding.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import QuranKit
@testable import QuranTextKit

extension AyahNumber: Encodable {
    enum CodingKeys: String, CodingKey {
        case sura
        case ayah
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sura.suraNumber, forKey: .sura)
        try container.encode(ayah, forKey: .ayah)
    }
}

extension Word: Encodable {
    enum CodingKeys: String, CodingKey {
        case verse
        case word
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verse, forKey: .verse)
        try container.encode(wordNumber, forKey: .word)
    }
}

extension WordFrame: Encodable {
    enum CodingKeys: String, CodingKey {
        case word
        case frame
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(rect, forKey: .frame)
    }
}

extension SearchResults: Encodable {
    enum CodingKeys: String, CodingKey {
        case source
        case items
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(items, forKey: .items)
    }
}

extension SearchResult.Source: Encodable {
    enum CodingKeys: String, CodingKey {
        case rawKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .quran:
            try container.encode("quran", forKey: .rawKey)
        case .translation(let translation):
            try container.encode("translation: \(translation.id)", forKey: .rawKey)
        }
    }
}

extension SearchResult: Encodable {
    enum CodingKeys: String, CodingKey {
        case text
        case ayah
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(ayah, forKey: .ayah)
    }
}
