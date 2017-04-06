//
//  QuranTranslationCollectionPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationCollectionPageCollectionViewCell: QuranBasePageCollectionViewCell {

    static var sharedLayoutManager: AnyCacheableService<TranslationPageLayoutRequest, TranslationPageLayout>  = {
        let cache = Cache<TranslationPageLayoutRequest, TranslationPageLayout>()
        cache.countLimit = 20
        let creator = AnyCreator { TranslationPageLayoutOperation(request: $0).asPreloadingOperationRepresentable() }
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let renderer = OperationCacheableService(queue: queue, cache: cache, operationCreator: creator).asCacheableService()
        return renderer
    }()

    @IBOutlet weak var collectionView: UICollectionView!

    private var highlights: [VerseHighlightType: Set<AyahNumber>] = [:] {
        didSet { dataSource.highlights = highlights }
    }

    var translationPage: TranslationPage? {
        didSet {
            updateTranslationPageLayoutIfNeeded {
                self.scrollToReadingHighlightedAyat()
            }
        }
    }

    private var request: TranslationPageLayoutRequest?

    private let dataSource = QuranTranslationCollectionInnerDataSource()

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionView.contentOffset = .zero
        highlights.removeAll()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .readingBackground()
        collectionView.backgroundColor = .readingBackground()

        collectionView.ds_register(cellClass: QuranTranslationSuraNameCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationVerseNumberCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationVerseSeparatorCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationArabicTextCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationTranslatorNameCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationTextCollectionViewCell.self)
        collectionView.ds_register(cellClass: QuranTranslationLongTextCollectionViewCell.self)

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0

        collectionView.ds_useDataSource(dataSource)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTranslationPageLayoutIfNeeded {
            self.scrollToReadingHighlightedAyat()
        }
    }

    private func updateTranslationPageLayoutIfNeeded(withCompletion completion: @escaping () -> Void = { }) {
        let oldRequest = request
        request = translationPage.map { TranslationPageLayoutRequest(page: $0, width: bounds.width - 2 * Layout.QuranCell.horizontalInset) }

        // if the same request
        guard oldRequest != request else {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            completion()
            return
        }

        // if we are reloading
        guard let request = request else {
            setLayout(nil)
            return
        }

        let layoutManager = type(of: self).sharedLayoutManager
        layoutManager.getOnMainThread(request) { [weak self] layout in
            self?.request = request
            self?.setLayout(layout)
            completion()
        }
    }

    private func setLayout(_ layout: TranslationPageLayout?) {
        dataSource.page = layout
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

    // MARK: - share specifics

    override func ayahNumber(at point: CGPoint) -> AyahNumber? {

        let localPoint = collectionView.convert(point, from: self)
        let indexPath = collectionView.indexPathForItem(at: localPoint)
        let cell = indexPath.flatMap { collectionView.cellForItem(at: $0) }
        let translationCell = cell as? QuranTranslationBaseCollectionViewCell
        return translationCell?.ayah
    }

    override func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: VerseHighlightType) {
        highlights[type] = verses
        if type == .reading {
            scrollToReadingHighlightedAyat()
        }
    }

    override func highlightedVerse(forType type: VerseHighlightType) -> Set<AyahNumber>? {
        return highlights[type]
    }

    private func scrollToReadingHighlightedAyat() {
        // layout data if needed
        layoutIfNeeded()
        guard let ayah = highlights[.reading]?.first else {
            return
        }
        guard let indexPath = dataSource.indexPath(forAyah: ayah) else {
            return
        }
        // scroll to the reading ayah
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
    }
}
