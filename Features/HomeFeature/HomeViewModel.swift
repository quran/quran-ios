//
//  HomeViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import AnnotationsService
import Combine
import Crashing
import Foundation
import Preferences
import QuranAnnotations
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import VLogging

enum SurahSortOrder: Int, Codable {
    case ascending = 1
    case descending = -1
}

enum HomeViewType: Int {
    case suras
    case juzs
}

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        lastPageService: LastPageService,
        textRetriever: QuranTextDataService,
        navigateToPage: @escaping (Page) -> Void,
        navigateToSura: @escaping (Sura) -> Void,
        navigateToQuarter: @escaping (Quarter) -> Void
    ) {
        self.lastPageService = lastPageService
        self.textRetriever = textRetriever
        self.navigateToPage = navigateToPage
        self.navigateToSura = navigateToSura
        self.navigateToQuarter = navigateToQuarter

        HomePreferences.shared.$surahSortOrder
            .assign(to: &$surahSortOrder)
    }

    // MARK: Internal

    @Published var suras: [Sura] = []
    @Published var quarters: [QuarterItem] = []
    @Published var lastPages: [LastPage] = []

    @Published var surahSortOrder: SurahSortOrder = HomePreferences.shared.surahSortOrder

    @Published var type = HomeViewType.suras {
        didSet {
            logger.info("Home: \(type) selected")
        }
    }

    func start() async {
        async let lastPages: () = loadLastPages()
        async let suras: () = loadSuras()
        async let quarters: () = loadQuarters()
        _ = await [lastPages, suras, quarters]
    }

    func navigateTo(_ lastPage: Page) {
        navigateToPage(lastPage)
    }

    func navigateTo(_ sura: Sura) {
        navigateToSura(sura)
    }

    func navigateTo(_ item: QuarterItem) {
        navigateToQuarter(item.quarter)
    }

    func toggleSurahSortOrder() {
        HomePreferences.shared.surahSortOrder = surahSortOrder == .ascending ? .descending : .ascending
    }

    // MARK: Private

    private let lastPageService: LastPageService
    private let textRetriever: QuranTextDataService
    private let navigateToPage: (Page) -> Void
    private let navigateToSura: (Sura) -> Void
    private let navigateToQuarter: (Quarter) -> Void
    private let readingPreferences = ReadingPreferences.shared

    private func loadLastPages() async {
        let lastPagesSequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [lastPageService] reading in
                lastPageService.lastPages(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await lastPages in lastPagesSequence {
            self.lastPages = lastPages
        }
    }

    private func loadSuras() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()

        for await reading in readings {
            suras = reading.quran.suras
        }
    }

    private func loadQuarters() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()

        for await reading in readings {
            let quarters = reading.quran.quarters
            let quartersText = await textForQuarters(quarters)
            let quarterItems = quarters.map { QuarterItem(quarter: $0, ayahText: quartersText[$0] ?? "") }
            self.quarters = quarterItems
        }
    }

    private func textForQuarters(
        _ quarters: [Quarter]
    ) async -> [Quarter: String] {
        do {
            let verses = Array(quarters.map(\.firstVerse))
            let verseTexts = try await textRetriever.textForVerses(verses, translations: [])
            return cleanUpText(quarters: quarters, verseTexts: verseTexts)
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve quarters text")
            return [:]
        }
    }

    private func cleanUpText(quarters: [Quarter], verseTexts: [AyahNumber: VerseText]) -> [Quarter: String] {
        let quarterStart = "۞" // Hizb marker
        let cleanedVersesText = verseTexts.mapValues { $0.arabicText.replacingOccurrences(of: quarterStart, with: "") }
        return quarters.reduce(into: [Quarter: String]()) { partialResult, quarter in
            partialResult[quarter] = cleanedVersesText[quarter.firstVerse]
        }
    }
}
