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
    func setVisiblePages(_ pages: [Page])
    func userWillBeginDragScroll()
    func presentAyahMenu(in sourceView: UIView, at point: CGPoint, verses: [AyahNumber])
}

@MainActor
public final class ContentViewModel {
    struct Deps {
        let analytics: AnalyticsLibrary
        let quranContentStatePreferences = QuranContentStatePreferences.shared
        let fontSizePreferences = FontSizePreferences.shared
        let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
        let noteService: NoteService
        let lastPageUpdater: LastPageUpdater
        let quran: Quran

        let highlightsService: QuranHighlightsService

        let imageDataSourceBuilder: PageDataSourceBuilder
        let translationDataSourceBuilder: PageDataSourceBuilder
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
            .sink { [weak self] _ in self?.loadNewElementModule() }
            .store(in: &cancellables)
        deps.selectedTranslationsPreferences.$selectedTranslations
            .sink { [weak self] _ in self?.loadNewElementModule() }
            .store(in: &cancellables)

        loadNotes()
        configureAsInitialPage()
    }

    // MARK: Public

    public var visiblePages: [Page] { dataSource?.visiblePages ?? [] }

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

    public func word(at point: CGPoint, in view: UIView) -> Word? {
        dataSource?.word(at: point, in: view)
    }

    public func highlightReadingAyah(_ ayah: AyahNumber?) {
        deps.highlightsService.highlights.readingVerses = [ayah].compactMap { $0 }
    }

    // MARK: Internal

    weak var listener: ContentListener?

    @Published var twoPagesEnabled: Bool
    @Published var dataSource: PageDataSource?

    let deps: Deps

    var verticalScrollingEnabled: Bool {
        didSet { loadNewElementModule() }
    }

    var lastViewedPage: Page {
        deps.lastPageUpdater.lastPage ?? input.initialPage
    }

    func userWillBeginDragScroll() {
        listener?.userWillBeginDragScroll()
    }

    func visiblePagesLoaded() {
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

        listener?.setVisiblePages(pages)
        updateLastPageTo(pages)
    }

    func visiblePagesUpdated() {
        // remove search highlight when page changes
        deps.highlightsService.highlights.searchVerses = []
        visiblePagesLoaded()
    }

    func updateLastPageTo(_ pages: [Page]) {
        deps.lastPageUpdater.updateTo(pages: pages)
    }

    func onViewLongPressStarted(at point: CGPoint, sourceView: UIView) {
        guard let verse = dataSource?.verse(at: point, in: sourceView) else {
            return
        }
        longPressData = LongPressData(
            sourceView: sourceView,
            startPosition: point,
            endPosition: point,
            startVerse: verse,
            endVerse: verse
        )
    }

    func onViewLongPressChanged(to point: CGPoint) {
        guard var longPressData else {
            return
        }
        guard let verse = dataSource?.verse(at: point, in: longPressData.sourceView) else {
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
    private var pages: [Page]

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

    // MARK: - Element

    private var dataSourceBuilder: PageDataSourceBuilder {
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
        loadNewElementModule()
        deps.highlightsService.highlights.searchVerses = [input.highlightingSearchAyah].compactMap { $0 }
    }

    private func loadNewElementModule() {
        let dataSource = dataSourceBuilder.build(
            actions: .init(
                visiblePagesUpdated: { [weak self] in await self?.visiblePagesUpdated() }
            ),
            pages: pages
        )
        dataSource.items = pages
        self.dataSource = dataSource
    }

    @objc
    private func loadNotes() {
        // set highlighted notes verses
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
