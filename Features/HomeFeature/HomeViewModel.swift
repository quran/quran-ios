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
import MobileSync
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
            lastPageService: LastPageService,
            textRetriever: QuranTextDataService,
            navigateToPage: @escaping (Page) -> Void,
            navigateToSura: @escaping (Sura) -> Void,
            navigateToQuarter: @escaping (Quarter) -> Void,
            syncService: SyncService? = nil
        ) {
            self.lastPageService = lastPageService
            self.textRetriever = textRetriever
            self.navigateToPage = navigateToPage
            self.navigateToSura = navigateToSura
            self.navigateToQuarter = navigateToQuarter
            self.syncService = syncService

            HomePreferences.shared.$surahSortOrder
                .assign(to: &$surahSortOrder)
        }
    #else
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
    #endif

    // MARK: Internal

    @Published var suras: [Sura] = []
    @Published var quarters: [QuarterItem] = []
    @Published var lastPages: [LastPage] = []

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
    #if QURAN_SYNC
        private let syncService: SyncService?
    #endif

    private func loadLastPages() async {
        #if QURAN_SYNC
            if let syncService {
                await loadReadingSessions(syncService: syncService)
                return
            }
        #endif

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

    #if QURAN_SYNC
        private func loadReadingSessions(syncService: SyncService) async {
            do {
                let sequence = syncService.readingSessionsSequence()
                for try await sessions in sequence {
                    let mapped = sessions.compactMap { session -> LastPage? in
                        let targetQuran = readingPreferences.reading.quran

                        // Try to build an AyahNumber from the stored session values
                        guard let sourceAyah = AyahNumber(quran: targetQuran, sura: Int(session.sura), ayah: Int(session.ayah)) else {
                            // If we can't create an AyahNumber for the target quran,
                            // you could try resolving a different source quran here (if session includes it).
                            return nil
                        }

                        // If the source ayah already belongs to the target quran, use its page directly.
                        // Otherwise map it to the target quran.
                        let page: Page
                        if sourceAyah.quran === targetQuran {
                            page = sourceAyah.page
                        } else {
                            let mapper = QuranPageMapper(destination: targetQuran)
                            guard let mappedAyah = mapper.mapAyah(sourceAyah) else { return nil }
                            page = mappedAyah.page
                        }

                        let createdOn = session.lastUpdated
                        return LastPage(page: page, createdOn: createdOn, modifiedOn: createdOn)
                    }

                    let sorted = mapped.sorted { $0.createdOn > $1.createdOn }
                    lastPages = Array(sorted.prefix(3))
                }
            } catch {
                crasher.recordError(error, reason: "Failed to load reading sessions")
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
