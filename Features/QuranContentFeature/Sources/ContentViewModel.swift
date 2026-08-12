//
//  ContentViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import Combine
import Crashing
import QuranAnnotations
import QuranImageFeature
import QuranKit
import QuranPagesFeature
import QuranText
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import UIKit
import Utilities
import VLogging

@MainActor
public protocol ContentListener: AnyObject {
    func userWillBeginDragScroll()
    func presentAyahMenu(in sourceView: UIView, at point: CGPoint, verses: [AyahNumber])
}

@MainActor
public final class ContentViewModel: ObservableObject {
    struct Deps {
        let analytics: AnalyticsLibrary
        let quranContentStatePreferences = QuranContentStatePreferences.shared
        let fontSizePreferences = FontSizePreferences.shared
        let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
        let noteService: NoteService
        let lastPageUpdater: LastPageUpdater
        let quran: Quran

        let highlightsService: QuranHighlightsService

        let imageDataSourceBuilder: ContentImageBuilder
        let translationDataSourceBuilder: ContentTranslationBuilder
    }

    private struct LongPressData {
        let sourceView: UIView
        let startPosition: CGPoint
        var endPosition: CGPoint
        var startVerse: AyahNumber
        var endVerse: AyahNumber
    }

    // MARK: Lifecycle

    init(deps: Deps, input: QuranInput) {
        self.deps = deps
        self.input = input

        visiblePages = [input.initialPage]

        let highlightsService = deps.highlightsService
        _highlights = PublishedBinding(
            wrappedValue: highlightsService.highlights,
            updates: highlightsService.$highlights,
            set: { highlightsService.highlights = $0 }
        )

        let contentStatePreferences = deps.quranContentStatePreferences
        _twoPagesEnabled = PublishedBinding(
            wrappedValue: contentStatePreferences.twoPagesEnabled,
            updates: contentStatePreferences.$twoPagesEnabled,
            set: { contentStatePreferences.twoPagesEnabled = $0 }
        )
        _quranMode = PublishedBinding(
            wrappedValue: contentStatePreferences.quranMode,
            updates: contentStatePreferences.$quranMode,
            set: { contentStatePreferences.quranMode = $0 }
        )

        $highlights
            .zip($highlights.dropFirst())
            .sink { [weak self] oldValue, newValue in
                if let ayah = newValue.verseToScrollTo(comparingTo: oldValue) {
                    self?.visiblePages = [ayah.page]
                }
            }
            .store(in: &cancellables)
        $quranMode
            .dropFirst()
            .sink { [weak self] _ in self?.updateQuranModeCrashContext() }
            .store(in: &cancellables)

        updateQuranModeCrashContext()

        #if !QURAN_SYNC
        loadNotes()
        #endif
        configureInitialPage()
    }

    // MARK: Public

    @Published public var visiblePages: [Page] {
        didSet {
            visiblePagesUpdated()
        }
    }

    public func removeAyahMenuHighlight() {
        longPressData = nil
    }

    public func highlightTranslationVerse(_ verse: AyahNumber) {
        longPressData?.startVerse = verse
        longPressData?.endVerse = verse
    }

    public func highlightWord(_ word: Word?) {
        highlights.pointedWord = word
    }

    public func highlightReadingAyah(_ ayah: AyahNumber?) {
        highlights.readingVerses = [ayah].compactMap { $0 }
    }

    // MARK: Internal

    let deps: Deps
    weak var listener: ContentListener?

    @PublishedBinding var quranMode: QuranMode

    @PublishedBinding var twoPagesEnabled: Bool
    @Published var geometryActions: [PageGeometryActions] = []

    @PublishedBinding var highlights: QuranHighlights

    var pagingStrategy: PagingStrategy {
        twoPagesEnabled ? .doublePage : .singlePage
    }

    func onViewLongPressStarted(at point: CGPoint, sourceView: UIView, verse: AyahNumber) {
        longPressData = LongPressData(
            sourceView: sourceView,
            startPosition: point,
            endPosition: point,
            startVerse: verse,
            endVerse: verse
        )
    }

    func onViewLongPressChanged(to point: CGPoint, verse: AyahNumber) {
        guard var longPressData else {
            return
        }
        longPressData.endVerse = verse
        self.longPressData = longPressData
    }

    func onViewLongPressEnded() {
        guard let longPressData, let selectedVerses else {
            return
        }
        listener?.presentAyahMenu(
            in: longPressData.sourceView,
            at: longPressData.startPosition,
            verses: selectedVerses
        )
    }

    func onViewLongPressCancelled() {
        longPressData = nil
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private let input: QuranInput

    private var longPressData: LongPressData? {
        didSet {
            highlights.shareVerses = selectedVerses ?? []
        }
    }

    private var selectedVerses: [AyahNumber]? {
        guard let longPressData else {
            return nil
        }
        var start = longPressData.startVerse
        var end = longPressData.endVerse
        if end < start {
            swap(&start, &end)
        }
        return start.array(to: end)
    }

    private static func dictionaryFrom<K: Hashable, U>(_ array: [(K, U)]) -> [K: U] {
        var dict: [K: U] = [:]
        for element in array {
            dict[element.0] = element.1
        }
        return dict
    }

    private func configureInitialPage() {
        deps.lastPageUpdater.configure(initialPage: input.initialPage, lastPage: input.lastPage)
        highlights.navigationVerse = input.navigationAyah
    }

    private func visiblePagesUpdated() {
        // Remove the navigation highlight when the reader changes pages.
        highlights.navigationVerse = nil

        let pages = visiblePages
        let isTranslationView = deps.quranContentStatePreferences.quranMode == .translation
        updateQuranModeCrashContext()
        crashContext.setVisiblePages(pages.map(\.pageNumber))
        deps.analytics.showing(
            pages: pages,
            isTranslation: isTranslationView,
            numberOfSelectedTranslations: deps.selectedTranslationsPreferences.selectedTranslationIds.count,
            arabicFontSize: deps.fontSizePreferences.arabicFontSize,
            translationFontSize: deps.fontSizePreferences.translationFontSize
        )
        if isTranslationView {
            logger.info("Using translations \(deps.selectedTranslationsPreferences.selectedTranslationIds)")
        }

        updateLastPageTo(pages)
    }

    private func updateQuranModeCrashContext() {
        let mode = quranMode == .translation ? "translation" : "arabic"
        crashContext.setQuranMode(
            mode,
            selectedTranslationCount: deps.selectedTranslationsPreferences.selectedTranslationIds.count
        )
        if quranMode == .translation {
            crashContext.setActiveList(
                owner: "quran_translation",
                mode: "translations",
                generation: 0,
                sectionCount: visiblePages.count,
                rowCount: 0
            )
        } else {
            crashContext.clearActiveList(owner: "quran_translation")
        }
    }

    private func updateLastPageTo(_ pages: [Page]) {
        deps.lastPageUpdater.updateTo(pages: pages)
    }

    #if !QURAN_SYNC
    private func loadNotes() {
        deps.noteService.notes(quran: deps.quran)
            .map { notes in notes.flatMap { note in note.verses.map { ($0, note) } } }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.highlights.noteVerses = Self.dictionaryFrom($0) }
            .store(in: &cancellables)
    }
    #endif
}

private extension AnalyticsLibrary {
    func showing(
        pages: [Page],
        isTranslation: Bool,
        numberOfSelectedTranslations: Int,
        arabicFontSize: FontSize,
        translationFontSize: FontSize
    ) {
        logEvent("PageNumbers", value: pages.description)
        logEvent("PageIsTranslation", value: isTranslation.description)
        logEvent("PageViewingMode", value: isTranslation ? "Translation" : "Arabic")
        if isTranslation {
            logEvent("PageTranslationsNum", value: numberOfSelectedTranslations.description)
            logEvent("PageArabicFontSize", value: arabicFontSize.description)
            logEvent("PageTranslationFontSize", value: translationFontSize.description)
        }
    }
}
