//
//  JuzsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import Crashing
import FeaturesSupport
import Foundation
import PromiseKit
import QuranAnnotations
import QuranKit
import QuranText
import QuranTextKit
import ReadingService

@MainActor
protocol JuzsPresentable: AnyObject {
    func setQuarters(_ quartersDictionary: [Juz: [Quarter]], juzs: [Juz], quartersText: [Quarter: String])
}

@MainActor
final class JuzsInteractor: QuranNavigator {
    // MARK: Lifecycle

    init(textRetriever: QuranTextDataService) {
        self.textRetriever = textRetriever
    }

    // MARK: Internal

    weak var quranNavigator: QuranNavigator?

    weak var presenter: JuzsPresentable?

    func navigateTo(page: Page, lastPage: LastPage?, highlightingSearchAyah: AyahNumber?) {
        quranNavigator?.navigateTo(page: page, lastPage: lastPage, highlightingSearchAyah: highlightingSearchAyah)
    }

    func start() {
        cancellable = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                Task { @MainActor in
                    await self?.update(with: reading.quran)
                }
            }
    }

    // MARK: Private

    private let readingPreferences = ReadingPreferences.shared
    private var cancellable: AnyCancellable?

    // TODO: should have its own version not reusing notes one
    private let textRetriever: QuranTextDataService

    private func update(with quran: Quran) async {
        let quarters = quran.quarters
        let quartersDictionary = Dictionary(grouping: quarters, by: \.juz)
        let juzs = quartersDictionary.keys.sorted()
        do {
            let quartersText = try await textForQuarters(quarters, textRetriever: textRetriever)
            presenter?.setQuarters(quartersDictionary, juzs: juzs, quartersText: quartersText)
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quarters text")
        }
    }

    private func textForQuarters(_ quarters: [Quarter], textRetriever: QuranTextDataService) async throws -> [Quarter: String] {
        let verses = Array(quarters.map(\.firstVerse))
        let translatedVerses = try await textRetriever.textForVerses(verses, translations: [])
        return quartersTextDictionary(quarters: quarters, verses: verses, versesText: translatedVerses.verses)
    }

    private func quartersTextDictionary(quarters: [Quarter], verses: [AyahNumber], versesText: [VerseText]) -> [Quarter: String] {
        let quarterStart = "۞" // Hizb marker
        let cleanedVersesText = zip(verses, versesText).map { ($0, $1.arabicText.replacingOccurrences(of: quarterStart, with: "")) }
        let versesTextDict = Dictionary(cleanedVersesText, uniquingKeysWith: { x, _ in x })
        return quarters.reduce(into: [Quarter: String]()) { partialResult, quarter in
            partialResult[quarter] = versesTextDict[quarter.firstVerse]
        }
    }
}
