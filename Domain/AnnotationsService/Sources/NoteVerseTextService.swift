import Foundation
import Localization
import QuranKit
import QuranTextKit

public struct NoteVerseTextService {
    public init(textService: QuranTextDataService) {
        arabicTextForVerses = { verses in
            try await textService.textForVerses(verses, translations: [])
                .mapValues(\.arabicText)
        }
    }

    init(arabicTextForVerses: @escaping ([AyahNumber]) async throws -> [AyahNumber: String]) {
        self.arabicTextForVerses = arabicTextForVerses
    }

    public func textForVerses(_ verses: [AyahNumber]) async throws -> String {
        let verseTexts = try await arabicTextForVerses(verses)
        return verses.sorted()
            .compactMap { verse in
                verseTexts[verse].map {
                    $0 + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))"
                }
            }
            .joined(separator: " ")
    }

    private let arabicTextForVerses: ([AyahNumber]) async throws -> [AyahNumber: String]
}
