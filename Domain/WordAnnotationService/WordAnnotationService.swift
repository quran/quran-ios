//
//  WordAnnotationService.swift
//  Quran
//
//  Created for Quran.com iOS app.
//

import Foundation
import QuranAnnotations
import QuranKit
import WordTextPersistence

/// Fetches per-word tajweed colours and transliteration for a page.
public struct WordAnnotationService {
    // MARK: Lifecycle

    public init(wordsDatabase: URL) {
        persistence = GRDBWordTextPersistence(fileURL: wordsDatabase)
    }

    // MARK: Public

    /// Returns word annotations for every word on a given page.
    /// Tajweed colours come from the Quran.com API; transliteration from the local DB.
    public func annotations(for page: Page) async throws -> [AyahNumber: [WordAnnotation]] {
        // Collect all verses on this page.
        let verses = page.verses

        // Fetch tajweed data from API for each verse in parallel.
        let tajweedByVerse = try await fetchTajweedByVerse(verses: verses)

        // Build annotations using local transliteration + API tajweed.
        var result: [AyahNumber: [WordAnnotation]] = [:]
        for verse in verses {
            let tajweedWords = tajweedByVerse[verse] ?? []
            var annotations: [WordAnnotation] = []

            for (index, tajweedColor) in tajweedWords.enumerated() {
                let wordNumber = index + 1
                let word = Word(verse: verse, wordNumber: wordNumber)
                let transliteration = try? await persistence.transliterationForWord(word)
                annotations.append(WordAnnotation(
                    wordIndex: wordNumber,
                    verse: verse,
                    tajweedColor: tajweedColor,
                    transliteration: transliteration
                ))
            }

            // If API returned nothing, still fetch transliterations from local DB.
            if tajweedWords.isEmpty {
                // Estimate word count by fetching transliterations until nil.
                var wordNumber = 1
                while wordNumber <= 50 { // max words per verse
                    let word = Word(verse: verse, wordNumber: wordNumber)
                    guard let transliteration = try? await persistence.transliterationForWord(word),
                          !transliteration.isEmpty
                    else { break }
                    annotations.append(WordAnnotation(
                        wordIndex: wordNumber,
                        verse: verse,
                        tajweedColor: nil,
                        transliteration: transliteration
                    ))
                    wordNumber += 1
                }
            }

            if !annotations.isEmpty {
                result[verse] = annotations
            }
        }

        return result
    }

    // MARK: Private

    private let persistence: WordTextPersistence

    /// Fetch tajweed-annotated word colours for the given verses from Quran.com API.
    private func fetchTajweedByVerse(verses: [AyahNumber]) async throws -> [AyahNumber: [TajweedColor?]] {
        guard let firstVerse = verses.first else { return [:] }
        let chapter = firstVerse.sura.suraNumber

        // One API call per chapter should cover a full page.
        let url = URL(string: "https://api.quran.com/api/v4/verses/by_chapter/\(chapter)?words=true&word_fields=text_tajweed&per_page=286")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let decoded = try JSONDecoder().decode(QuranAPIResponse.self, from: data)

        var result: [AyahNumber: [TajweedColor?]] = [:]
        for apiVerse in decoded.verses {
            guard let ayahNumber = ayahNumber(from: apiVerse.verseKey, quran: firstVerse.sura.quran) else { continue }
            guard verses.contains(ayahNumber) else { continue }

            let colors: [TajweedColor?] = apiVerse.words
                .filter { $0.charTypeName == "word" }
                .map { word -> TajweedColor? in
                    guard let tajweedHTML = word.textTajweed else { return nil }
                    return primaryTajweedColor(from: tajweedHTML)
                }
            result[ayahNumber] = colors
        }
        return result
    }

    /// Parse the dominant tajweed CSS class out of the `text_tajweed` HTML snippet.
    /// Example: `<tajweed class="ham_wasl">ٱ</tajweed>لْحَمْدُ`
    private func primaryTajweedColor(from html: String) -> TajweedColor? {
        // Find the first class="..." inside a <tajweed …> tag.
        let pattern = #"<tajweed[^>]*class="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html)
        else { return nil }
        let cssClass = String(html[range])
        return TajweedColor(cssClass: cssClass)
    }

    private func ayahNumber(from key: String, quran: Quran) -> AyahNumber? {
        let parts = key.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2,
              let sura = Sura(quran: quran, suraNumber: parts[0])
        else { return nil }
        return AyahNumber(sura: sura, ayah: parts[1])
    }
}

// MARK: - Quran.com API response models

private struct QuranAPIResponse: Decodable {
    let verses: [APIVerse]
}

private struct APIVerse: Decodable {
    let verseKey: String
    let words: [APIWord]

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case words
    }
}

private struct APIWord: Decodable {
    let charTypeName: String
    let textTajweed: String?

    enum CodingKeys: String, CodingKey {
        case charTypeName = "char_type_name"
        case textTajweed = "text_tajweed"
    }
}
