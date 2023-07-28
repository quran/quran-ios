//
//  QuranTranslationDiffableDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-04-23.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources
import Localization
import NoorUI
import QuranKit
import QuranText
import TranslationService
import UIKit
import UIx
import VLogging

@MainActor
public class QuranTranslationDiffableDataSource {
    public struct TranslationId: Hashable, CustomStringConvertible, Sendable {
        // MARK: Public

        public var description: String {
            "<TranslationId verse=\(verse) translation=\(translation.id)>"
        }

        // MARK: Internal

        let verse: AyahNumber
        let translation: Translation
    }

    public enum ItemId: Hashable, Sendable {
        case header(AyahNumber)
        case footer(AyahNumber)
        case separator(AyahNumber)
        case suraName(AyahNumber)
        case arabic(AyahNumber, text: String, alignment: NSTextAlignment)
        case translation(TranslationId)
    }

    private enum Section: Hashable {
        case header
        case footer
        case verse(AyahNumber)
    }

    // MARK: Lifecycle

    // MARK: - Configuration

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            self?.cellProvider.provideCell(collectionView: collectionView, indexPath: indexPath, itemId: itemId)
        }
        cellProvider.expansionHandler = TranslationExpansionHandler(dataSource: dataSource)
    }

    // MARK: Public

    // MARK: - Collection View

    public static func translationCollectionView() -> UICollectionView {
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(99)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = 0

        let collectionViewLayout: UICollectionViewCompositionalLayout
        let collectionView: UICollectionView
        section.contentInsetsReference = .none
        collectionViewLayout = UICollectionViewCompositionalLayout(section: section)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.ds_register(cellClass: QuranTranslationSuraNameCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationVerseSeparatorCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationArabicTextCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationTextCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationHeaderCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationFooterCollectionViewCell.self)

        return collectionView
    }

    // MARK: Internal

    var quranUITraits: QuranUITraits {
        get { cellProvider.quranUITraits }
        set {
            cellProvider.quranUITraits = newValue
            cellProvider.updateQuranUITraits(dataSource: dataSource, collectionView: collectionView)
        }
    }

    var translatedPage: TranslatedPage? {
        didSet {
            guard let translatedPage else {
                fatalError("Can't set translatedPage to be nil")
            }
            cellProvider.translatedVerses = translatedPage.translatedVerses
            updateItems(with: translatedPage)
        }
    }

    func firstIndexPath(forAyah ayah: AyahNumber) -> IndexPath? {
        if let section = dataSource.snapshot().indexOfSection(.verse(ayah)) {
            // first item in the section
            return IndexPath(item: 0, section: section)
        }
        return nil
    }

    // MARK: Private

    private class NoSafeAreaCollectionView: UICollectionView {
        override var safeAreaInsets: UIEdgeInsets {
            .zero
        }
    }

    private weak var collectionView: UICollectionView?
    private var dataSource: UICollectionViewDiffableDataSource<Section, ItemId>! // swiftlint:disable:this implicitly_unwrapped_optional
    private let cellProvider = TranslationCellProvider<Section>(collapsedNumberOfLines: 10)

    // MARK: - Data

    private func updateItems(with page: TranslatedPage) {
        logger.info("Quran Translation: setting TranslatedPage")
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemId>()
        snapshot.appendSections(.header)
        snapshot.appendItems(.header(page.translatedVerses[0].verse))

        for translatedVerse in page.translatedVerses {
            let verse = translatedVerse.verse
            snapshot.appendSections(.verse(verse))
            cellProvider.add(translatedVerse, to: &snapshot)

            // separator
            let isLastVerse = verse.page.verses.last == verse
            if !isLastVerse {
                snapshot.appendItems(.separator(verse))
            }
        }

        snapshot.appendSections(.footer)
        snapshot.appendItems(.footer(page.translatedVerses[0].verse))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
