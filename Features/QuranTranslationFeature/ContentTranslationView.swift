//
//  ContentTranslationView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/30/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import Combine
import Crashing
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import TranslationService
import UIKit
import Utilities
import VLogging

class ContentTranslationView: UIView {
    // MARK: Lifecycle

    init(highlightsService: QuranHighlightsService) {
        self.highlightsService = highlightsService
        collectionView = QuranTranslationDiffableDataSource.translationCollectionView()
        dataSource = QuranTranslationDiffableDataSource(collectionView: collectionView, highlightsService: highlightsService)
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let collectionView: UICollectionView

    // MARK: - PageView

    var page: Page? {
        didSet {
            logger.info("Quran Translation: set page \(String(describing: page))")
        }
    }

    func word(at point: CGPoint) -> Word? {
        fatalError("Not implemented")
    }

    func verse(at point: CGPoint) -> AyahNumber? {
        let localPoint = collectionView.convert(point, from: self)
        let indexPath = collectionView.indexPathForItem(at: localPoint)
        let cell = indexPath.flatMap { collectionView.cellForItem(at: $0) }
        let translationCell = cell as? QuranTranslationBaseCollectionViewCell
        return translationCell?.ayah
    }

    func configure(for page: TranslatedPage) {
        setPageText(page)
        scrollToVerseIfNeeded()
    }

    // MARK: Private

    private let highlightsService: QuranHighlightsService
    private let dataSource: QuranTranslationDiffableDataSource
    private var lastPage: TranslatedPage?
    private var cancellable: AnyCancellable?

    private func setUp() {
        addAutoLayoutSubview(collectionView)
        collectionView.vc.edges()

        cancellable = highlightsService.$highlights
            .zip(highlightsService.$highlights.dropFirst())
            .sink { [weak self] oldValue, newValue in
                if newValue.needsScrolling(comparingTo: oldValue) {
                    self?.scrollToVerseIfNeeded()
                }
            }
    }

    private func setPageText(_ page: TranslatedPage) {
        logger.info("Quran Translation: set TranslatedPage")
        if page != lastPage {
            dataSource.translatedPage = page
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    // MARK: - share specifics

    private func scrollToVerseIfNeededSynchronously() {
        logger.info("Quran Translation: scrollToVerseIfNeeded")
        // layout views if needed
        layoutIfNeeded()

        guard let ayah = highlightsService.highlights.firstScrollingVerse() else {
            return
        }
        guard let indexPath = dataSource.firstIndexPath(forAyah: ayah) else {
            return
        }
        logger.info("Quran Translation: scrollToVerseIfNeeded \(ayah), \(indexPath)")
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the collection view to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
