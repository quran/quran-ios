//
//  NumberSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation
import QuranKit

struct NumberSearcher: Searcher {
    private static let numberParser: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    let quranVerseTextPersistence: VerseTextPersistence
    private let resultsProcessor = SearchResultsProcessor()

    func autocomplete(term: String, quran: Quran) throws -> [SearchAutocompletion] {
        if Int(term) != nil {
            return resultsProcessor.buildAutocompletions(searchResults: [term], term: term)
        }
        return []
    }

    func search(for term: String, quran: Quran) async throws -> [SearchResults] {
        let items: [SearchResult] = try await search(for: term, quran: quran)
        return [SearchResults(source: .quran, items: items)]
    }

    private func search(for term: String, quran: Quran) async throws -> [SearchResult] {
        let components = parseIntArray(term)
        guard !components.isEmpty else {
            return []
        }
        if components.count == 2 {
            return [try await parseVerseResult(sura: components[0],
                                               verse: components[1],
                                               quran: quran)].compactMap { $0 }
        } else {
            return [
                parseSuraResult(sura: components[0], quran: quran),
                parseJuzResult(juz: components[0], quran: quran),
                parseHizbResult(hizb: components[0], quran: quran),
                parsePageResult(page: components[0], quran: quran),
            ].compactMap { $0 }
        }
    }

    private func parseVerseResult(sura: Int, verse: Int, quran: Quran) async throws -> SearchResult? {
        guard let verse = quran.verses.first(where: { $0.sura.suraNumber == sura && $0.ayah == verse }) else {
            return nil
        }
        let ayahText = try await quranVerseTextPersistence.textForVerse(verse)
        return SearchResult(text: ayahText, ayah: verse)
    }

    private func parseSuraResult(sura: Int, quran: Quran) -> SearchResult? {
        guard let sura = quran.suras.first(where: { $0.suraNumber == sura }) else {
            return nil
        }
        return SearchResult(text: sura.localizedName(withPrefix: true), ayah: sura.firstVerse)
    }

    private func parsePageResult(page: Int, quran: Quran) -> SearchResult? {
        guard let page = quran.pages.first(where: { $0.pageNumber == page }) else {
            return nil
        }
        return SearchResult(text: page.localizedName, ayah: page.firstVerse)
    }

    private func parseJuzResult(juz: Int, quran: Quran) -> SearchResult? {
        guard let juz = quran.juzs.first(where: { $0.juzNumber == juz }) else {
            return nil
        }
        return SearchResult(text: juz.localizedName, ayah: juz.firstVerse)
    }

    private func parseHizbResult(hizb: Int, quran: Quran) -> SearchResult? {
        guard let hizb = quran.hizbs.first(where: { $0.hizbNumber == hizb }) else {
            return nil
        }
        return SearchResult(text: hizb.localizedName, ayah: hizb.firstVerse)
    }

    private func parseIntArray(_ term: String) -> [Int] {
        let components = term.components(separatedBy: ":")
        guard !components.isEmpty, components.count <= 2 else {
            return []
        }
        guard let first = parseInt(components[0]) else {
            return []
        }
        if components.count == 1 {
            return [first]
        } else {
            guard let second = parseInt(components[1]) else {
                return []
            }
            return [first, second]
        }
    }

    private func parseInt(_ value: String) -> Int? {
        guard let number = Self.numberParser.number(from: value) else {
            return nil
        }
        switch CFNumberGetType(number) {
        case .charType, .intType, .nsIntegerType, .shortType, .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type:
            return number.intValue
        default: return nil
        }
    }
}
