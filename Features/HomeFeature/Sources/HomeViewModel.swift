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
import NoorUI
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
        navigateToPage: @escaping (Page, LastPage?) -> Void,
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.lastPageService = lastPageService
        self.textRetriever = textRetriever
        self.readingBookmarkService = readingBookmarkService
        reading = ReadingPreferences.shared.reading
        self.navigateToPage = navigateToPage
        self.navigateToAyah = navigateToAyah

        HomePreferences.shared.$surahSortOrder
            .assign(to: &$surahSortOrder)
        readingPreferences.$reading
            .assign(to: &$reading)
    }
    #else
    init(
        lastPageService: any LastPageService,
        textRetriever: QuranTextDataService,
        navigateToPage: @escaping (Page, LastPage?) -> Void,
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.lastPageService = lastPageService
        self.textRetriever = textRetriever
        reading = ReadingPreferences.shared.reading
        self.navigateToPage = navigateToPage
        self.navigateToAyah = navigateToAyah

        HomePreferences.shared.$surahSortOrder
            .assign(to: &$surahSortOrder)
        readingPreferences.$reading
            .assign(to: &$reading)
    }
    #endif

    // MARK: Internal

    @Published var suras: [Sura] = [] {
        didSet { recordListUpdate(reason: "suras_loaded") }
    }

    @Published var quarters: [QuarterItem] = [] {
        didSet { recordListUpdate(reason: "quarters_loaded") }
    }

    @Published var lastPages: [LastPage] = [] {
        didSet { recordListUpdate(reason: "last_pages_changed") }
    }

    #if QURAN_SYNC
    @Published var readingBookmark: ReadingPositionBookmark? {
        didSet { recordListUpdate(reason: "reading_bookmark_changed") }
    }
    #endif

    @Published var surahSortOrder: SurahSortOrder = HomePreferences.shared.surahSortOrder {
        didSet { recordListUpdate(reason: "sort_order_changed") }
    }

    @Published var collapsedJuzs: Set<Juz> = []

    @Published var type = HomeViewType.suras {
        didSet {
            logger.info("Home: \(type) selected")
            recordListUpdate(reason: "mode_changed")
        }
    }

    @Published var reading: Reading

    func setListVisible(_ visible: Bool) {
        isListVisible = visible
        if visible {
            crashContext.setScreen("home")
            updateActiveListContext()
        } else {
            crashContext.clearActiveList(owner: "home")
        }
        logger.info("Crash context: home list visible=\(visible)")
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
        recordListUpdate(reason: "section_expansion_changed")
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
        navigateToPage(lastPage.page, lastPage)
    }

    #if QURAN_SYNC
    func navigateTo(_ readingBookmark: ReadingPositionBookmark) {
        switch readingBookmark.location {
        case .ayah(let ayahNumber):
            navigateToAyah(ayahNumber)
        case .page(let page):
            navigateToPage(page, nil)
        }
    }
    #endif

    func navigateTo(_ sura: Sura) {
        navigateToAyah(sura.firstVerse)
    }

    func navigateTo(_ item: QuarterItem) {
        navigateToAyah(item.quarter.firstVerse)
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
    private let navigateToPage: (Page, LastPage?) -> Void
    private let navigateToAyah: (AyahNumber) -> Void
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
            crashContext.setReading(id: String(describing: reading))
            suras = reading.quran.suras
        }
    }

    private func loadQuarters() async {
        let readings = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .values()

        for await reading in readings {
            crashContext.setReading(id: String(describing: reading))
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

    private var isListVisible = false
    private var listGeneration = 0
    private var recordedRowCount = 0

    private var listMode: String {
        switch type {
        case .suras: "suras"
        case .juzs: "juzs"
        }
    }

    private var listRowCount: Int {
        var count = lastPages.count
        #if QURAN_SYNC
        if readingBookmark != nil {
            count += 1
        }
        #endif
        switch type {
        case .suras:
            count += suras.count
        case .juzs:
            count += quarters.count
        }
        return count
    }

    private var listSectionCount: Int {
        var count = lastPages.isEmpty ? 0 : 1
        #if QURAN_SYNC
        if readingBookmark != nil {
            count += 1
        }
        #endif
        switch type {
        case .suras:
            count += Set(suras.map(\.page.startJuz)).count
        case .juzs:
            count += Set(quarters.map(\.quarter.juz)).count
        }
        return count
    }

    private func recordListUpdate(reason: String) {
        let rowsBefore = recordedRowCount
        let rowsAfter = listRowCount
        listGeneration += 1
        recordedRowCount = rowsAfter
        crashContext.recordListUpdate(
            owner: "home",
            reason: reason,
            rowsBefore: rowsBefore,
            rowsAfter: rowsAfter,
            generation: listGeneration
        )
        if isListVisible {
            updateActiveListContext()
        }
        logger.info(
            "Crash context: list update owner=home reason=\(reason) mode=\(listMode) generation=\(listGeneration) rows=\(rowsBefore)->\(rowsAfter) sections=\(listSectionCount)"
        )
    }

    private func updateActiveListContext() {
        crashContext.setActiveList(
            owner: "home",
            mode: listMode,
            generation: listGeneration,
            sectionCount: listSectionCount,
            rowCount: listRowCount
        )
    }
}
