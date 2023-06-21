//
//  TranslationExpansionHandler.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-10.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Foundation
import UIKit
import VLogging

public class TranslationExpansionHandler<Section: Hashable & Sendable> {
    public typealias ItemId = QuranTranslationDiffableDataSource.ItemId
    typealias TranslationId = QuranTranslationDiffableDataSource.TranslationId

    // MARK: Lifecycle

    public init(dataSource: UICollectionViewDiffableDataSource<Section, ItemId>) {
        self.dataSource = dataSource
    }

    // MARK: Internal

    func isExpanded(_ translationId: TranslationId) -> Bool {
        expandedTranslations.contains(translationId)
    }

    func translationTapped(_ translationId: TranslationId) {
        if expandedTranslations.contains(translationId) {
            logger.info("Quran Translation: Collapsing translation \(translationId)")
            expandedTranslations.remove(translationId)
        } else {
            logger.info("Quran Translation: Expanding translation \(translationId)")
            expandedTranslations.insert(translationId)
        }

        let itemId: ItemId = .translation(translationId)

        var snapshot = dataSource.snapshot()
        snapshot.backwardCompatibleReconfigureItems([itemId])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: Private

    private let dataSource: UICollectionViewDiffableDataSource<Section, ItemId>
    private var expandedTranslations: Set<TranslationId> = []
}
