//
//  TranslationCellProvider.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-10.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AnnotationsService
import Combine
import Foundation
import Localization
import QuranAnnotations
import QuranText
import QuranTextKit
import UIKit

@MainActor
public class TranslationCellProvider<Section: Hashable & Sendable> {
    public typealias ItemId = QuranTranslationDiffableDataSource.ItemId
    typealias TranslationId = QuranTranslationDiffableDataSource.TranslationId

    // MARK: Lifecycle

    public init(collapsedNumberOfLines: UInt, highlightsService: QuranHighlightsService) {
        self.collapsedNumberOfLines = collapsedNumberOfLines
        self.highlightsService = highlightsService
        highlights = highlightsService.highlights
        translationFontSize = fontSizePreferences.translationFontSize
        arabicFontSize = fontSizePreferences.arabicFontSize

        highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0 }
            .store(in: &cancellables)

        fontSizePreferences.$translationFontSize
            .sink { [weak self] in self?.translationFontSize = $0 }
            .store(in: &cancellables)

        fontSizePreferences.$arabicFontSize
            .sink { [weak self] in self?.arabicFontSize = $0 }
            .store(in: &cancellables)
    }

    // MARK: Public

    public weak var dataSource: UICollectionViewDiffableDataSource<Section, ItemId>?
    public weak var collectionView: UICollectionView?

    public var translatedVerses: [TranslatedVerse] = []
    public var expansionHandler: TranslationExpansionHandler<Section>!

    public var highlights: QuranHighlights {
        didSet {
            reconfigureAllItems()
        }
    }

    public var translationFontSize: FontSize {
        didSet {
            reconfigureAllItems()
        }
    }

    public var arabicFontSize: FontSize {
        didSet {
            reconfigureAllItems()
        }
    }

    public func provideCell(collectionView: UICollectionView, indexPath: IndexPath, itemId: ItemId) -> UICollectionViewCell {
        let baseCell: QuranTranslationBaseCollectionViewCell
        switch itemId {
        case .header(let verse):
            let cell = collectionView.dequeueReusableCell(QuranTranslationHeaderCollectionViewCell.self, for: indexPath)
            cell.configure(with: TranslationPageHeader(verse: verse))
            baseCell = cell
        case .footer(let verse):
            let cell = collectionView.dequeueReusableCell(QuranTranslationFooterCollectionViewCell.self, for: indexPath)
            cell.configure(with: verse.page)
            baseCell = cell
        case .separator(let verse):
            let cell = collectionView.dequeueReusableCell(QuranTranslationVerseSeparatorCollectionViewCell.self, for: indexPath)
            cell.ayah = verse
            baseCell = cell
        case let .suraName(verse):
            let cell = collectionView.dequeueReusableCell(QuranTranslationSuraNameCollectionViewCell.self, for: indexPath)
            cell.ayah = verse
            cell.configure(with: verse.sura.localizedName(withPrefix: false))
            baseCell = cell
        case let .arabic(verse, text, alignment):
            let cell = collectionView.dequeueReusableCell(QuranTranslationArabicTextCollectionViewCell.self, for: indexPath)
            cell.ayah = verse
            cell.configure(with: (text: text, alignment: alignment))
            baseCell = cell
        case .translation(let translationId):
            let cell = collectionView.dequeueReusableCell(QuranTranslationTextCollectionViewCell.self, for: indexPath)
            cell.ayah = translationId.verse
            configure(cell: cell, translationId: translationId)
            baseCell = cell
        }
        baseCell.highlights = highlights
        baseCell.translationFontSize = translationFontSize
        baseCell.arabicFontSize = arabicFontSize
        return baseCell
    }

    public func add(
        _ translatedVerse: TranslatedVerse,
        to snapshot: inout NSDiffableDataSourceSnapshot<Section, ItemId>
    ) {
        let verse = translatedVerse.verse
        let verseText = translatedVerse.text

        // if a new sura
        if verse.ayah == 1 {
            snapshot.appendItems(.suraName(verse))
        }

        // add prefixes
        snapshot.appendItems(verseText.arabicPrefix.map { .arabic(verse, text: $0, alignment: .center) })

        // add arabic quran text
        let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        let arabicText = verseText.arabicText + " " + arabicVerseNumber
        snapshot.appendItems(.arabic(verse, text: arabicText, alignment: .right))

        // translations
        snapshot.appendItems(translatedVerse.translations.translations.map { .translation(TranslationId(verse: verse, translation: $0)) })

        // add suffixes
        snapshot.appendItems(verseText.arabicSuffix.map { .arabic(verse, text: $0, alignment: .center) })
    }

    // MARK: Private

    private let collapsedNumberOfLines: UInt
    private let highlightsService: QuranHighlightsService
    private let fontSizePreferences = FontSizePreferences.shared
    private var cancellables: Set<AnyCancellable> = []

    private func reconfigureAllItems() {
        guard let dataSource else {
            return
        }
        var snapshot = dataSource.snapshot()
        // reconfigure all items
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        // animate font size changes
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func configure(cell: QuranTranslationTextCollectionViewCell, translationId: TranslationId) {
        let verse = translatedVerses.first { $0.verse == translationId.verse }!
        let translationIndex = verse.translations.translations.firstIndex(of: translationId.translation)!
        let translationText = verse.text.translations[translationIndex]
        cell.configure(with: TranslationTextData(
            collapsedNumberOfLines: collapsedNumberOfLines,
            verse: translationId.verse,
            translation: translationId.translation,
            text: translationTextToString(translationText),
            isExpanded: expansionHandler.isExpanded(translationId),
            showTranslator: verse.translations.translations.count > 1,
            translationTapped: { [weak self] _ in
                self?.expansionHandler.translationTapped(translationId)
            }
        ))
    }

    private func translationTextToString(_ translationText: TranslationText) -> TranslationString {
        switch translationText {
        case .reference(let verse):
            return TranslationString(text: lFormat("translation.text.see-referenced-verse", verse.ayah), quranRanges: [], footnoteRanges: [], footnotes: [])
        case .string(let string):
            return string
        }
    }
}
