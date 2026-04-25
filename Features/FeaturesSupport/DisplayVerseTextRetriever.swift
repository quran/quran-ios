#if QURAN_SYNC
    import Foundation
    import Localization
    import QuranKit
    import QuranTextKit

    public struct DisplayVerseTextRetriever {
        public init(databasesURL: URL, quranFileURL: URL) {
            textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        }

        public func textForVerses(_ verses: [AyahNumber]) async throws -> String {
            let verseTexts = try await textService.textForVerses(verses, translations: [])
            let sortedVerses = verses.sorted()
            return sortedVerses
                .compactMap { verse in
                    verseTexts[verse].map { $0.arabicText + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))" }
                }
                .joined(separator: " ")
        }

        private let textService: QuranTextDataService
    }
#endif
