//
//  Encoding.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import QuranText

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

extension SearchResults.Source: Encodable {
    enum CodingKeys: String, CodingKey {
        case rawKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .quran:
            try container.encode(name.lowercased(), forKey: .rawKey)
        case .translation(let translation):
            try container.encode("\(name.lowercased()): \(translation.id)", forKey: .rawKey)
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
