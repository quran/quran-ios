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

    #if QURAN_SYNC
    init(
        lastPageService: any LastPageService,
        textRetriever: QuranTextDataService,
        readingBookmarkService: MobileSyncReadingBookmarkService,
        navigateToQuran: @escaping (AyahNumber, LastPage?) -> Void
    ) {
        self.lastPageService = lastPageService
        self.textRetriever = textRetriever
        self.readingBookmarkService = readingBookmarkService
        self.navigateToQuran = navigateToQuran

        HomePreferences.shared.$surahSortOrder
            .assign(to: &$surahSortOrder)
    }
    #else
    init(
        lastPageService: any LastPageService,
        textRetriever: QuranTextDataService,
        navigateToQuran: @escaping (AyahNumber, LastPage?) -> Void
    ) {
        self.lastPageService = lastPageService
        self.textRetriever = textRetriever
        self.navigateToQuran = navigateToQuran

        HomePreferences.shared.$surahSortOrder
            .assign(to: &$surahSortOrder)
    }
    #endif

    // MARK: Internal

    @Published var suras: [Sura] = []
    @Published var quarters: [QuarterItem] = []
    @Published var lastPages: [LastPage] = []
    #if QURAN_SYNC
    @Published var readingBookmark: ReadingPositionBookmark?
    #endif

    @Published var surahSortOrder: SurahSortOrder = HomePreferences.shared.surahSortOrder

    @Published var collapsedJuzs: Set<Juz> = []

    @Published var type = HomeViewType.suras {
        didSet {
            logger.info("Home: \(type) selected")
        }
    }

    func isJuzExpanded(_ juz: Juz) -> Bool {
        !collapsedJuzs.contains(juz)
    }

    func setJuz(_ juz: Juz, expanded: Bool) {
        if expanded {
            collapsedJuzs.remove(juz)
        } else {
            collapsedJuzs.insert(juz)
        }
    }

    func start() async {
        async let lastPages: () = loadLastPages()
        async let suras: () = loadSuras()
        async let quarters: () = loadQuarters()
        #if QURAN_SYNC
        async let readingBookmark: () = loadReadingBookmark()
        _ = await [lastPages, suras, quarters, readingBookmark]
        #else
        _ = await [lastPages, suras, quarters]
        #endif
    }

    func navigateTo(_ lastPage: LastPage) {
        navigateToQuran(lastPage.page.firstVerse, lastPage)
    }

    #if QURAN_SYNC
    func navigateTo(_ readingBookmark: ReadingPositionBookmark) {
        switch readingBookmark.location {
        case .ayah(let ayahNumber):
            navigateToQuran(ayahNumber, nil)
        case .page(let page):
            navigateToQuran(page.firstVerse, nil)
        }
    }
    #endif

    func navigateTo(_ sura: Sura) {
        navigateToQuran(sura.firstVerse, nil)
    }

    func navigateTo(_ item: QuarterItem) {
        navigateToQuran(item.quarter.firstVerse, nil)
    }

    func toggleSurahSortOrder() {
        HomePreferences.shared.surahSortOrder = surahSortOrder == .ascending ? .descending : .ascending
    }

    // MARK: Private

    private let lastPageService: any LastPageService
    private let textRetriever: QuranTextDataService
    #if QURAN_SYNC
    private let readingBookmarkService: MobileSyncReadingBookmarkService
    #endif
    private let navigateToQuran: (AyahNumber, LastPage?) -> Void
    private let readingPreferences = ReadingPreferences.shared

    private func loadLastPages() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()
        var observationTask: Task<Void, Never>?
        defer { observationTask?.cancel() }

        for await reading in readings {
            observationTask?.cancel()
            let sequence = lastPageService.lastPages(quran: reading.quran)
            observationTask = Task { [weak self] in
                do {
                    for try await lastPages in sequence {
                        guard !Task.isCancelled else { return }
                        self?.lastPages = lastPages
                    }
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    crasher.recordError(error, reason: "Failed to load last pages")
                }
            }
        }
    }

    #if QURAN_SYNC
    private func loadReadingBookmark() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()
        var observationTask: Task<Void, Never>?
        defer { observationTask?.cancel() }

        for await reading in readings {
            observationTask?.cancel()
            let sequence = readingBookmarkService.readingBookmarkSequence(quran: reading.quran)
            observationTask = Task { [weak self] in
                do {
                    for try await bookmark in sequence {
                        guard !Task.isCancelled else { return }
                        self?.readingBookmark = bookmark
                    }
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    crasher.recordError(error, reason: "Failed to load reading bookmark")
                }
            }
        }
    }
    #endif

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
    ) async -> [Quarter: QuranText] {
        do {
            let verses = Array(quarters.map(\.firstVerse))
            let verseTexts = try await textRetriever.textForVerses(verses, translations: [])
            return cleanUpText(quarters: quarters, verseTexts: verseTexts)
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve quarters text")
            return [:]
        }
    }

    private func cleanUpText(quarters: [Quarter], verseTexts: [AyahNumber: VerseText]) -> [Quarter: QuranText] {
        let quarterStart = "۞" // Hizb marker
        let cleanedVersesText = verseTexts.mapValues {
            QuranText($0.arabicText.text.replacingOccurrences(of: quarterStart, with: ""))
        }
        return quarters.reduce(into: [Quarter: QuranText]()) { partialResult, quarter in
            partialResult[quarter] = cleanedVersesText[quarter.firstVerse]
        }
    }
}
