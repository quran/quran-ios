//
//  TranslationVerseDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AnnotationsService
import Foundation
import Localization
import QuranAnnotations
import QuranKit
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import UIKit
import UIx
import VLogging

@MainActor
class TranslationVerseDataSource {
    private typealias ItemId = QuranTranslationDiffableDataSource.ItemId
    private typealias Section = DefaultSection

    // MARK: Lifecycle

    // MARK: - Configuration

    init(collectionView: UICollectionView, highlightsService: QuranHighlightsService) {
        self.collectionView = collectionView
        cellProvider = TranslationCellProvider<Section>(collapsedNumberOfLines: 10, highlightsService: highlightsService)
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            self?.cellProvider.provideCell(collectionView: collectionView, indexPath: indexPath, itemId: itemId)
        }
        cellProvider.dataSource = dataSource
        cellProvider.collectionView = collectionView
        cellProvider.expansionHandler = TranslationExpansionHandler(dataSource: dataSource)
    }

    // MARK: Internal

    var translatedVerse: TranslatedVerse? {
        didSet {
            guard let translatedVerse else {
                fatalError("Can't set translatedVerse to be nil")
            }
            cellProvider.translatedVerses = [translatedVerse]
            updateItems(with: translatedVerse)
        }
    }

    // MARK: Private

    private weak var collectionView: UICollectionView?
    private var dataSource: UICollectionViewDiffableDataSource<Section, ItemId>! // swiftlint:disable:this implicitly_unwrapped_optional
    private let cellProvider: TranslationCellProvider<Section>

    // MARK: - Data

    private func updateItems(with translatedVerse: TranslatedVerse) {
        logger.info("Quran Translation: setting translatedVerse")
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemId>()
        snapshot.appendSections(.default)
        cellProvider.add(translatedVerse, to: &snapshot)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
