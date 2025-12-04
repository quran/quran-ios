//
//  Encoding.swift
//
//
//  Created by Mohamed Afifi on 2022-01-16.
//

import QuranText

struct EncodableSearchResults: Encodable {
    // MARK: Internal

    let results: [SearchResults]

    // MARK: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for result in results {
            try container.encode(EncodableSearchResult(result: result))
        }
    }
}

private struct EncodableSearchResult: Encodable {
    // MARK: Internal

    let result: SearchResults

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case source
        case items
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(EncodableSearchSource(source: result.source), forKey: .source)
        try container.encode(result.items.map(EncodableSearchResultItem.init), forKey: .items)
    }
}

private struct EncodableSearchSource: Encodable {
    // MARK: Internal

    let source: SearchResults.Source

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case rawKey
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch source {
        case .quran:
            try container.encode(source.name.lowercased(), forKey: .rawKey)
        case .translation(let translation):
            try container.encode("\(source.name.lowercased()): \(translation.id)", forKey: .rawKey)
        }
    }
}

private struct EncodableSearchResultItem: Encodable {
    // MARK: Internal

    let result: SearchResult

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case text
        case ayah
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(result.text, forKey: .text)
        try container.encode(result.ayah, forKey: .ayah)
    }
}
