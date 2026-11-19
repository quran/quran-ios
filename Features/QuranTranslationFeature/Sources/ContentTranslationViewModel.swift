//
//  ContentTranslationViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import AnnotationsService
import Combine
import Crashing
import Foundation
import NoorUI
import QuranAnnotations
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import SwiftUI
import TranslationService
import UIx
import VLogging

struct LoadedTranslationContent {
    var verses: [AyahNumber] = []
    var translations: [Translation] = []
    var verseTexts: [AyahNumber: VerseText] = [:]
}

@MainActor
public final class ContentTranslationViewModel: ObservableObject {
    // MARK: Lifecycle

    public init(
        localTranslationsRetriever: LocalTranslationsRetriever,
        dataService: QuranTextDataService,
        overlayService: VerseOverlayService
    ) {
        self.dataService = dataService
        self.overlayService = overlayService
        self.localTranslationsRetriever = localTranslationsRetriever
        reading = ReadingPreferences.shared.reading
        arabicFontSize = fontSizePreferences.arabicFontSize
        translationFontSize = fontSizePreferences.translationFontSize
        showArabicText = contentStatePreferences.showArabicInTranslation
        showFootnotes = contentStatePreferences.showFootnotesInTranslation
        selectedTranslations = selectedTranslationsPreferences.selectedTranslationIds
        highlights = [:]

        overlayService.$overlays
            .combineLatest($verses)
            .map { overlays, verses in overlays.undimmedVerses?.intersection(verses) }
            .removeDuplicates()
            .sink { [weak self] in self?.undimmedVerses = $0 }
            .store(in: &cancellables)

        overlayService.$overlays
            .combineLatest($verses)
            .map { overlays, verses in
                let colors = overlays.versesByHighlights()
                return Dictionary(uniqueKeysWithValues: Set(verses).compactMap { verse in
                    colors[verse].map { (verse, Color($0)) }
                })
            }
            .removeDuplicates()
            .sink { [weak self] in self?.highlights = $0 }
            .store(in: &cancellables)

        #if QURAN_SYNC
        overlayService.$overlays
            .combineLatest($verses)
            .map { overlays, verses in
                Dictionary(uniqueKeysWithValues: Set(verses).compactMap { verse in
                    let indicators = overlays.indicators(for: verse)
                    return indicators.isEmpty ? nil : (verse, indicators)
                })
            }
            .removeDuplicates()
            .sink { [weak self] in self?.indicatorsByVerse = $0 }
            .store(in: &cancellables)
        #endif

        overlayService.scrollRequests
            .sink { [weak self] in
                self?.scrollToVerseIfNeeded()
            }
            .store(in: &cancellables)

        fontSizePreferences.$translationFontSize
            .sink { [weak self] in self?.translationFontSize = $0 }
            .store(in: &cancellables)

        fontSizePreferences.$arabicFontSize
            .sink { [weak self] in self?.arabicFontSize = $0 }
            .store(in: &cancellables)

        contentStatePreferences.$showArabicInTranslation
            .sink { [weak self] in self?.showArabicText = $0 }
            .store(in: &cancellables)

        contentStatePreferences.$showFootnotesInTranslation
            .sink { [weak self] in self?.showFootnotes = $0 }
            .store(in: &cancellables)

        // Translation services update the selection from background tasks.
        selectedTranslationsPreferences.$selectedTranslationIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.selectedTranslations = $0 }
            .store(in: &cancellables)

        readingPreferences.$reading
            .assign(to: &$reading)
    }

    // MARK: Public

    @Published public var showHeaderAndFooter = true {
        didSet { recordListUpdate(reason: "header_footer_changed") }
    }

    @Published public var verses: [AyahNumber] = [] {
        didSet { recordListUpdate(reason: "verses_changed") }
    }

    /// Follows a verse reference in a footnote, from the verse with the footnote to the referenced verse.
    /// While it's `nil`, footnotes show their references as plain text.
    public var onVerseReferenceTapped: ((_ verse: AyahNumber, _ reference: AyahNumber) -> Void)?

    // MARK: Internal

    let tracker = CollectionTracker<TranslationItemId>()
    @Published private(set) var reading: Reading

    @Published var selectedTranslations: [Translation.ID] {
        didSet {
            crashContext.setQuranMode("translation", selectedTranslationCount: selectedTranslations.count)
            recordListUpdate(reason: "selection_changed")
        }
    }

    @Published private(set) var loadedContent = LoadedTranslationContent() {
        didSet { recordListUpdate(reason: "content_loaded") }
    }

    @Published var expandedTranslations: [AyahNumber: [Translation: [Range<String.Index>]]] = [:] {
        didSet { recordListUpdate(reason: "translation_expanded") }
    }

    @Published var translationFontSize: FontSize
    @Published var arabicFontSize: FontSize

    @Published var showArabicText: Bool {
        didSet { recordListUpdate(reason: "arabic_text_visibility_changed") }
    }

    @Published var showFootnotes: Bool {
        didSet { recordListUpdate(reason: "footnotes_visibility_changed") }
    }

    @Published var highlights: [AyahNumber: Color]

    @Published private(set) var undimmedVerses: Set<AyahNumber>?

    #if QURAN_SYNC
    @Published private(set) var indicatorsByVerse: [AyahNumber: Set<AyahIndicator>] = [:]
    #endif

    @Published var footnote: TranslationFootnote?

    @Published var scrollToItem: TranslationItemId?

    var translations: [Translation] {
        loadedContent.translations
    }

    var verseTexts: [AyahNumber: VerseText] {
        loadedContent.verseTexts
    }

    func items(quranFont: QuranFont) -> [TranslationItem] {
        guard let page = verseTexts.first?.key.page else {
            return []
        }
        guard verseTexts.first?.value.translations.count == translations.count else {
            return []
        }

        // Never leave a page with verse numbers only.
        let showsArabicText = showArabicText || translations.isEmpty

        var items: [TranslationItem] = []

        for (verse, verseText) in verseTexts.sorted(by: { $0.key < $1.key }) {
            let decoration = TranslationVerseDecoration(
                color: highlights[verse],
                isDimmed: undimmedVerses?.contains(verse) == false
            )

            // Add sura name, if a new sura
            if verse.sura.firstVerse == verse {
                items.append(
                    .suraName(
                        TranslationSuraName(
                            sura: verse.sura,
                            showsBesmAllah: showsArabicText,
                            quranFont: quranFont,
                            arabicFontSize: arabicFontSize
                        ),
                        decoration
                    )
                )
            }

            items.append(.verseNumber(verseNumber(verse: verse), decoration))
            if showsArabicText {
                items.append(.arabicText(arabicText(verse: verse, verseText: verseText, quranFont: quranFont), decoration))
            }

            for (index, translation) in translations.enumerated() {
                let text = verseText.translations[index]

                switch text {
                case .reference(let reference):
                    items.append(
                        .translationReferenceVerse(
                            TranslationReferenceVerse(
                                verse: verse,
                                translation: translation,
                                reference: reference,
                                translationFontSize: translationFontSize
                            ), decoration
                        )
                    )
                case .string(let string):
                    let chunks: [Range<String.Index>]
                    let readMore: Bool
                    if let cutoffChunk = cutoffChunkIfTruncationNeeded(string.text) {
                        if let expandedChunks = expandedChunks(verse: verse, translation: translation) {
                            chunks = expandedChunks
                            readMore = false
                        } else {
                            chunks = [cutoffChunk]
                            readMore = true
                        }
                    } else {
                        chunks = [string.text.startIndex ..< string.text.endIndex]
                        readMore = false
                    }

                    for chunkIndex in 0 ..< chunks.count {
                        items.append(
                            .translationTextChunk(
                                TranslationTextChunk(
                                    verse: verse,
                                    translation: translation,
                                    text: string,
                                    chunks: chunks,
                                    chunkIndex: chunkIndex,
                                    readMore: chunkIndex == chunks.count - 1 ? readMore : false, // Add read more to the last chunk.
                                    translationFontSize: translationFontSize
                                ), decoration
                            )
                        )
                    }

                    if showFootnotes, !readMore {
                        items += footnoteChunks(verse: verse, translation: translation, string: string)
                            .map { .translationFootnoteChunk($0, decoration) }
                    }
                }

                // Show translator if showing more than a single translation.
                if translations.count > 1 {
                    items.append(
                        .translatorText(
                            TranslatorText(
                                verse: verse,
                                translation: translation,
                                translationFontSize: translationFontSize
                            ), decoration
                        )
                    )
                }
            }

            let isLastVerseInTheView = loadedContent.verses.last == verse
            if !isLastVerseInTheView {
                items.append(.verseSeparator(TranslationVerseSeparator(verse: verse), decoration))
            }
        }

        if showHeaderAndFooter {
            items.insert(.pageHeader(TranslationPageHeader(page: page)), at: 0)
            items.append(.pageFooter(TranslationPageFooter(page: page)))
        }

        return items
    }

    func load() async {
        do {
            let requestedVerses = verses
            let requestedTranslationIds = selectedTranslations
            logger.info("Loading translations data; selectedTranslations='\(requestedTranslationIds)'; verses='\(requestedVerses.map(\.nonLocalizedDescription).joined(separator: ", "))'")

            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
            try Task.checkCancellation()

            let translationsById = Dictionary(uniqueKeysWithValues: localTranslations.map { ($0.id, $0) })
            let requestedTranslations = requestedTranslationIds.compactMap { translationsById[$0] }
            let requestedVerseTexts = try await dataService.textForVerses(
                requestedVerses,
                translations: requestedTranslations
            )
            try Task.checkCancellation()

            guard requestedVerses == verses, requestedTranslationIds == selectedTranslations else {
                logger.info("Discarding stale translations data")
                return
            }

            commitLoadedContent(
                verses: requestedVerses,
                translations: requestedTranslations,
                verseTexts: requestedVerseTexts
            )
        } catch is CancellationError {
            logger.info("Cancelled translations data load")
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran page details")
        }
    }

    /// Scrolls only while the view is on screen, so content being replaced can't use up the navigation target.
    func onAppear() {
        isVisible = true
        scrollToVerseIfNeeded()
    }

    func onDisappear() {
        isVisible = false
    }

    /// The reader scrolled the page themselves; forget the last scroll so it isn't applied again
    /// on appearance or size changes, and so the next request scrolls even to the same verse.
    func onReaderScroll() {
        // Every drag reports; publishing an unchanged nil would still redraw the page.
        if scrollToItem != nil {
            scrollToItem = nil
        }
    }

    func openURL(_ url: TranslationURL) {
        switch url {
        case .footnote(let translationId, let sura, let ayah, let footnoteIndex):
            setFootnoteIfNeeded(translationId: translationId, sura: sura, ayah: ayah, footnoteIndex: footnoteIndex)

        case .readMore(let translationId, let sura, let ayah):
            expandTranslationIfNeeded(translationId: translationId, sura: sura, ayah: ayah)

        case .verseReference(let sura, let ayah, let referencedSura, let referencedAyah):
            followVerseReference(sura: sura, ayah: ayah, referencedSura: referencedSura, referencedAyah: referencedAyah)
        }
    }

    func ayahAtPoint(_ point: CGPoint) -> AyahNumber? {
        tracker.itemAtPoint(point)?.ayah
    }

    func commitLoadedContent(
        verses: [AyahNumber],
        translations: [Translation],
        verseTexts: [AyahNumber: VerseText]
    ) {
        loadedContent = LoadedTranslationContent(
            verses: verses,
            translations: translations,
            verseTexts: verseTexts
        )
        scrollToVerseIfNeeded()
    }

    // MARK: Private

    private static let maxChunkSize = 800

    private var cancellables: Set<AnyCancellable> = []
    private var listGeneration = 0
    private var isVisible = false
    private var recordedRowCount = 0
    private let overlayService: VerseOverlayService
    private let dataService: QuranTextDataService
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let readingPreferences = ReadingPreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared

    private func arabicText(verse: AyahNumber, verseText: VerseText, quranFont: QuranFont) -> TranslationArabicText {
        let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        return TranslationArabicText(
            verse: verse,
            text: QuranText(verseText.arabicText.text + " " + arabicVerseNumber),
            quranFont: quranFont,
            arabicFontSize: arabicFontSize
        )
    }

    private func footnoteChunks(verse: AyahNumber, translation: Translation, string: TranslationString) -> [TranslationFootnoteChunk] {
        zip(string.footnoteRanges, string.footnotes.indices).flatMap { markerRange, footnoteIndex in
            let text = string.footnoteText(at: footnoteIndex)
            let verseReferences = followableVerseReferences(in: text, of: verse)
            let chunks = text.count <= Self.maxChunkSize
                ? [text.startIndex ..< text.endIndex]
                : text.chunkRanges(maxChunkSize: Self.maxChunkSize)
            return chunks.indices.map { chunkIndex in
                TranslationFootnoteChunk(
                    verse: verse,
                    translation: translation,
                    footnoteIndex: footnoteIndex,
                    marker: chunkIndex == 0 ? String(string.text[markerRange]) : nil,
                    text: text,
                    verseReferences: verseReferences,
                    chunks: chunks,
                    chunkIndex: chunkIndex,
                    translationFontSize: translationFontSize
                )
            }
        }
    }

    /// The verse references in a footnote of `verse` that the reader can follow: verses of the Quran other than `verse`.
    private func followableVerseReferences(in text: String, of verse: AyahNumber) -> [FootnoteVerseReference] {
        guard onVerseReferenceTapped != nil else {
            return []
        }
        return text.footnoteVerseReferences().filter { reference in
            // Footnotes can start by naming their own verse, like Khan & Hilali's "(V.{40:74})".
            AyahNumber(quran: verse.quran, sura: reference.sura, ayah: reference.ayah).map { $0 != verse } ?? false
        }
    }

    private func verseNumber(verse: AyahNumber) -> TranslationVerseNumber {
        #if QURAN_SYNC
        TranslationVerseNumber(verse: verse, indicators: indicatorsByVerse[verse, default: []])
        #else
        TranslationVerseNumber(verse: verse)
        #endif
    }

    private func recordListUpdate(reason: String) {
        let rowsBefore = recordedRowCount
        let rowsAfter = items(quranFont: reading.quranFont).count
        listGeneration += 1
        recordedRowCount = rowsAfter
        crashContext.recordListUpdate(
            owner: "quran_translation",
            reason: reason,
            rowsBefore: rowsBefore,
            rowsAfter: rowsAfter,
            generation: listGeneration
        )
        logger.info(
            "Quran Translation list update: \(reason), rows: \(rowsBefore)->\(rowsAfter), generation: \(listGeneration)"
        )
    }

    private func cutoffChunkIfTruncationNeeded(_ string: String) -> Range<String.Index>? {
        guard let maxUntruncatedIndex = string.index(string.startIndex, offsetBy: Self.maxChunkSize, limitedBy: string.endIndex) else {
            return nil
        }
        let chunkEndIndex = string[..<maxUntruncatedIndex].lastIndex(of: " ") ?? maxUntruncatedIndex
        return string.startIndex ..< chunkEndIndex
    }

    private func expandedChunks(verse: AyahNumber, translation: Translation) -> [Range<String.Index>]? {
        expandedTranslations[verse]?[translation]
    }

    private func expandTranslationIfNeeded(translationId: Translation.ID, sura: Int, ayah: Int) {
        performOnTranslationText(translationId: translationId, sura: sura, ayah: ayah) { ayah, translation, string in
            if let cutoffChunk = cutoffChunkIfTruncationNeeded(string.text) {
                let truncatedChunks = string.text.chunkRanges(range: cutoffChunk.upperBound ..< string.text.endIndex, maxChunkSize: Self.maxChunkSize)
                expandedTranslations[ayah, default: [:]][translation] = [cutoffChunk] + truncatedChunks
            }
        }
    }

    private func setFootnoteIfNeeded(translationId: Translation.ID, sura: Int, ayah: Int, footnoteIndex: Int) {
        performOnTranslationText(translationId: translationId, sura: sura, ayah: ayah) { ayah, translation, string in
            footnote = TranslationFootnote(
                string: string,
                footnoteIndex: footnoteIndex,
                verse: ayah,
                verseReferences: followableVerseReferences(in: string.footnoteText(at: footnoteIndex), of: ayah),
                translation: translation,
                translationFontSize: translationFontSize
            )
        }
    }

    private func followVerseReference(sura: Int, ayah: Int, referencedSura: Int, referencedAyah: Int) {
        guard let quran = loadedContent.verses.first?.quran,
              let verse = AyahNumber(quran: quran, sura: sura, ayah: ayah),
              let reference = AyahNumber(quran: quran, sura: referencedSura, ayah: referencedAyah)
        else {
            return
        }
        logger.info("Quran Translation: following \(reference.nonLocalizedDescription) from a footnote of \(verse.nonLocalizedDescription)")
        footnote = nil
        onVerseReferenceTapped?(verse, reference)
    }

    private func performOnTranslationText(translationId: Translation.ID, sura: Int, ayah: Int, _ body: (AyahNumber, Translation, TranslationString) -> Void) {
        guard let quran = loadedContent.verses.first?.quran else {
            return
        }
        let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah)
        let translation = translations.first { $0.id == translationId }
        let translationIndex = translation.flatMap { translations.firstIndex(of: $0) }
        let verseText = ayah.flatMap { ayah in verseTexts[ayah] }
        if let ayah, let translation, let translationIndex, let verseText {
            if case .string(let string) = verseText.translations[translationIndex] {
                body(ayah, translation, string)
            }
        }
    }

    private func scrollToVerseIfNeededSynchronously() {
        guard isVisible,
              let ayah = overlayService.overlays.firstScrollingVerse(),
              let item = items(quranFont: reading.quranFont).first(where: { $0.id.ayah == ayah })
        else {
            return
        }
        logger.info("Quran Translation: scrollToVerseIfNeeded \(ayah.nonLocalizedDescription)")
        scrollToItem = item.id
        // Scroll to the navigation target once; later reloads keep the reader's position.
        overlayService.consumeNavigationTarget(ayah)
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the overlayService value to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
