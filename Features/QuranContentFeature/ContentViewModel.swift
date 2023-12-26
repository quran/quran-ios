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
import QuranKit
import QuranPagesFeature
import QuranText
import QuranTextKit
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

        let imageDataSourceBuilder: PageViewBuilder
        let translationDataSourceBuilder: PageViewBuilder
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
        pages = deps.quran.pages

        twoPagesEnabled = deps.quranContentStatePreferences.twoPagesEnabled
        verticalScrollingEnabled = deps.quranContentStatePreferences.verticalScrollingEnabled

        deps.quranContentStatePreferences.$twoPagesEnabled
            .sink { [weak self] in self?.twoPagesEnabled = $0 }
            .store(in: &cancellables)
        deps.quranContentStatePreferences.$verticalScrollingEnabled
            .sink { [weak self] in self?.verticalScrollingEnabled = $0 }
            .store(in: &cancellables)
        deps.quranContentStatePreferences.$quranMode
            .sink { [weak self] _ in self?.reloadAllPages() }
            .store(in: &cancellables)
        deps.selectedTranslationsPreferences.$selectedTranslations
            .sink { [weak self] _ in self?.reloadAllPages() }
            .store(in: &cancellables)

        loadNotes()
        configureAsInitialPage()
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
        deps.highlightsService.highlights.pointedWord = word
    }

    public func highlightReadingAyah(_ ayah: AyahNumber?) {
        deps.highlightsService.highlights.readingVerses = [ayah].compactMap { $0 }
    }

    // MARK: Internal

    let deps: Deps
    weak var listener: ContentListener?

    @Published var twoPagesEnabled: Bool
    @Published var pageViewBuilder: PageViewBuilder?

    let pages: [Page]

    var pagingStrategy: PagingStrategy {
        let shouldDisplayTwoPages = !verticalScrollingEnabled && twoPagesEnabled
        return shouldDisplayTwoPages ? .doublePage : .singlePage
    }

    var verticalScrollingEnabled: Bool {
        didSet { reloadAllPages() }
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
            deps.highlightsService.highlights.shareVerses = selectedVerses ?? []
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

    private var newPageCollectionBuilder: PageViewBuilder {
        switch deps.quranContentStatePreferences.quranMode {
        case .arabic: return deps.imageDataSourceBuilder
        case .translation: return deps.translationDataSourceBuilder
        }
    }

    private static func dictionaryFrom<K: Hashable, U>(_ array: [(K, U)]) -> [K: U] {
        var dict: [K: U] = [:]
        for element in array {
            dict[element.0] = element.1
        }
        return dict
    }

    private func configureAsInitialPage() {
        deps.lastPageUpdater.configure(initialPage: input.initialPage, lastPage: input.lastPage)
        reloadAllPages()
        deps.highlightsService.highlights.searchVerses = [input.highlightingSearchAyah].compactMap { $0 }
    }

    private func visiblePagesUpdated() {
        // remove search highlight when page changes
        deps.highlightsService.highlights.searchVerses = []

        let pages = visiblePages
        let isTranslationView = deps.quranContentStatePreferences.quranMode == .translation
        crasher.setValue(pages.map(\.pageNumber), forKey: .pages)
        deps.analytics.showing(
            pages: pages,
            isTranslation: isTranslationView,
            numberOfSelectedTranslations: deps.selectedTranslationsPreferences.selectedTranslations.count,
            arabicFontSize: deps.fontSizePreferences.arabicFontSize,
            translationFontSize: deps.fontSizePreferences.translationFontSize
        )
        if isTranslationView {
            logger.info("Using translations \(deps.selectedTranslationsPreferences.selectedTranslations)")
        }

        updateLastPageTo(pages)
    }

    private func updateLastPageTo(_ pages: [Page]) {
        deps.lastPageUpdater.updateTo(pages: pages)
    }

    private func reloadAllPages() {
        switch deps.quranContentStatePreferences.quranMode {
        case .arabic:
            pageViewBuilder = deps.imageDataSourceBuilder
        case .translation:
            pageViewBuilder = deps.translationDataSourceBuilder
        }
    }

    private func loadNotes() {
        deps.noteService.notes(quran: deps.quran)
            .map { notes in notes.flatMap { note in note.verses.map { ($0, note) } } }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.deps.highlightsService.highlights.noteVerses = Self.dictionaryFrom($0) }
            .store(in: &cancellables)
    }
}

private extension CrasherKeyBase {
    static let pages = CrasherKey<[Int]>(key: "VisiblePages")
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
