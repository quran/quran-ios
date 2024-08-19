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
import QuranKit
import QuranText
import QuranTextKit
import SwiftUI
import TranslationService
import UIx
import VLogging

@MainActor
public final class ContentTranslationViewModel: ObservableObject {
    // MARK: Lifecycle

    public init(
        localTranslationsRetriever: LocalTranslationsRetriever,
        dataService: QuranTextDataService,
        highlightsService: QuranHighlightsService
    ) {
        self.dataService = dataService
        self.highlightsService = highlightsService
        self.localTranslationsRetriever = localTranslationsRetriever
        arabicFontSize = fontSizePreferences.arabicFontSize
        translationFontSize = fontSizePreferences.translationFontSize
        selectedTranslations = selectedTranslationsPreferences.selectedTranslationIds
        highlights = highlightsService.highlights.versesByHighlights().mapValues { Color($0) }

        highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0.versesByHighlights().mapValues { Color($0) } }
            .store(in: &cancellables)

        highlightsService.scrolling
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

        selectedTranslationsPreferences.$selectedTranslationIds
            .sink { [weak self] in self?.selectedTranslations = $0 }
            .store(in: &cancellables)
    }

    // MARK: Public

    @Published public var showHeaderAndFooter = true
    @Published public var verses: [AyahNumber] = []

    // MARK: Internal

    let tracker = CollectionTracker<TranslationItemId>()

    @Published var selectedTranslations: [Translation.ID]
    @Published var translations: [Translation] = []
    @Published var verseTexts: [AyahNumber: VerseText] = [:]
    @Published var expandedTranslations: [AyahNumber: [Translation: [Range<String.Index>]]] = [:]

    @Published var translationFontSize: FontSize
    @Published var arabicFontSize: FontSize

    @Published var highlights: [AyahNumber: Color]

    @Published var footnote: TranslationFootnote?

    @Published var scrollToItem: TranslationItemId?

    var items: [TranslationItem] {
        guard let page = verseTexts.first?.key.page else {
            return []
        }
        guard verseTexts.first?.value.translations.count == translations.count else {
            return []
        }

        var items: [TranslationItem] = []

        for (verse, verseText) in verseTexts.sorted(by: { $0.key < $1.key }) {
            let color = highlights[verse]

            // Add sura name, if a new sura
            if verse.sura.firstVerse == verse {
                items.append(.suraName(TranslationSuraName(sura: verse.sura, arabicFontSize: arabicFontSize), color))
            }

            // Add arabic quran text
            let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
            let arabicText = verseText.arabicText + " " + arabicVerseNumber
            items.append(.arabicText(TranslationArabicText(verse: verse, text: arabicText, arabicFontSize: arabicFontSize), color))

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
                            ), color
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
                                ), color
                            )
                        )
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
                            ), color
                        )
                    )
                }
            }

            let isLastVerseInTheView = verses.last == verse
            if !isLastVerseInTheView {
                items.append(.verseSeparator(TranslationVerseSeparator(verse: verse), color))
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
            logger.info("Loading translations data; selectedTranslations='\(selectedTranslations)'; verses='\(verses)'")
            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
            translations = selectedTranslationsPreferences.selectedTranslations(from: localTranslations)

            let verses = verses
            verseTexts = try await dataService.textForVerses(verses, translations: translations)

            scrollToVerseIfNeeded()
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran page details")
        }
    }

    func openURL(_ url: TranslationURL) {
        switch url {
        case .footnote(let translationId, let sura, let ayah, let footnoteIndex):
            setFootnoteIfNeeded(translationId: translationId, sura: sura, ayah: ayah, footnoteIndex: footnoteIndex)

        case .readMore(let translationId, let sura, let ayah):
            expandTranslationIfNeeded(translationId: translationId, sura: sura, ayah: ayah)
        }
    }

    func ayahAtPoint(_ point: CGPoint, from: UICoordinateSpace) -> AyahNumber? {
        tracker.itemAtPoint(point, from: from)?.ayah
    }

    // MARK: Private

    private static let maxChunkSize = 800

    private var cancellables: Set<AnyCancellable> = []
    private let highlightsService: QuranHighlightsService
    private let dataService: QuranTextDataService
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared

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
                translation: translation,
                translationFontSize: translationFontSize
            )
        }
    }

    private func performOnTranslationText(translationId: Translation.ID, sura: Int, ayah: Int, _ body: (AyahNumber, Translation, TranslationString) -> Void) {
        guard let quran = verses.first?.quran else {
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
        guard let ayah = highlightsService.highlights.firstScrollingVerse() else {
            return
        }
        for item in items {
            if item.id.ayah == ayah {
                logger.info("Quran Translation: scrollToVerseIfNeeded \(ayah)")
                scrollToItem = item.id
                break
            }
        }
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the highlightsService value to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
