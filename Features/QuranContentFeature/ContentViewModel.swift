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
import FeaturesSupport
import QuranAnnotations
#if QURAN_SYNC
    import MobileSync
#endif
import QuranImageFeature
import QuranKit
import QuranPagesFeature
import QuranText
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import UIKit
import VLogging

@MainActor
public protocol ContentListener: AnyObject {
    func userWillBeginDragScroll()
    func presentAyahMenu(
        in sourceView: UIView,
        at point: CGPoint,
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note],
        syncHighlightColor: HighlightColor?,
        hasSyncHighlight: Bool
    )
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
        #if QURAN_SYNC
            let syncService: SyncService?
        #endif

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

        highlights = deps.highlightsService.highlights
        twoPagesEnabled = deps.quranContentStatePreferences.twoPagesEnabled
        quranMode = deps.quranContentStatePreferences.quranMode

        deps.highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0 }
            .store(in: &cancellables)
        deps.quranContentStatePreferences.$twoPagesEnabled
            .sink { [weak self] in self?.twoPagesEnabled = $0 }
            .store(in: &cancellables)
        deps.quranContentStatePreferences.$quranMode
            .sink { [weak self] in self?.quranMode = $0 }
            .store(in: &cancellables)

        loadNotes()
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

    @Published var quranMode: QuranMode
    @Published var twoPagesEnabled: Bool
    @Published var geometryActions: [PageGeometryActions] = []

    @Published var highlights: QuranHighlights {
        didSet {
            if oldValue != highlights {
                deps.highlightsService.highlights = highlights

                if let ayah = highlights.verseToScrollTo(comparingTo: oldValue) {
                    visiblePages = [ayah.page]
                }
            }
        }
    }

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
        let syncHighlight = selectedSyncHighlight(in: selectedVerses)
        listener?.presentAyahMenu(
            in: longPressData.sourceView,
            at: longPressData.startPosition,
            verses: selectedVerses,
            notes: selectedNotes(in: selectedVerses),
            syncHighlightColor: syncHighlight.color,
            hasSyncHighlight: syncHighlight.hasHighlight
        )
    }

    func onViewLongPressCancelled() {
        longPressData = nil
    }

    #if QURAN_SYNC
        func observeSyncHighlightsIfNeeded() async {
            guard let syncService = deps.syncService else {
                return
            }

            do {
                for try await collections in HighlightCollection.updates(from: syncService) {
                    highlights.highlightColorsByVerse = HighlightCollection.highlightColorsByVerse(in: collections, quran: deps.quran)
                }
            } catch is CancellationError {
            } catch {
                crasher.recordError(error, reason: "Failed to observe synced highlights")
            }
        }
    #endif

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

    private func selectedNotes(in verses: [AyahNumber]) -> [QuranAnnotations.Note] {
        var notes: [QuranAnnotations.Note] = []
        for verse in verses {
            guard let note = highlights.noteVerses[verse], !notes.contains(note) else {
                continue
            }
            notes.append(note)
        }
        return notes
    }

    private func selectedSyncHighlight(in verses: [AyahNumber]) -> (hasHighlight: Bool, color: HighlightColor?) {
        let colors = verses.compactMap { highlights.highlightColorsByVerse[$0] }
        let uniqueColors = Array(Set(colors))
        if uniqueColors.isEmpty {
            return (false, nil)
        }
        if uniqueColors.count == 1 {
            return (true, uniqueColors[0])
        }
        return (true, nil)
    }

    private func configureInitialPage() {
        deps.lastPageUpdater.configure(initialPage: input.initialPage, lastPage: input.lastPage)
        highlights.searchVerses = [input.highlightingSearchAyah].compactMap { $0 }
    }

    private func visiblePagesUpdated() {
        // remove search highlight when page changes
        highlights.searchVerses = []

        let pages = visiblePages
        let isTranslationView = deps.quranContentStatePreferences.quranMode == .translation
        crasher.setValue(pages.map(\.pageNumber), forKey: .pages)
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

    private func updateLastPageTo(_ pages: [Page]) {
        deps.lastPageUpdater.updateTo(pages: pages)
    }

    private func loadNotes() {
        deps.noteService.notes(quran: deps.quran)
            .map { [deps] notes in
                let visibleNotes: [QuranAnnotations.Note]
                #if QURAN_SYNC
                    if deps.syncService != nil {
                        visibleNotes = notes.filter { !(($0.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                    } else {
                        visibleNotes = notes
                    }
                #else
                    visibleNotes = notes
                #endif
                return visibleNotes.flatMap { note in note.verses.map { ($0, note) } }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.highlights.noteVerses = Self.dictionaryFrom($0) }
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
