//
//  QuranTranslationCollectionPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationCollectionPageCollectionViewCell: UICollectionViewCell {

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

    var page: QuranPage?
    var translationPage: TranslationPage? {
        didSet {
            updateTranslationPageLayoutIfNeeded()
        }
    }

    private var request: TranslationPageLayoutRequest?

    private let dataSource = QuranTranslationCollectionInnerDataSource()

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .readingBackground()
        collectionView.backgroundColor = .readingBackground()

        collectionView.register(cellClass: QuranTranslationSuraNameCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationVerseNumberCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationVerseSeparatorCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationArabicTextCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationTranslatorNameCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationTextCollectionViewCell.self)
        collectionView.register(cellClass: QuranTranslationLongTextCollectionViewCell.self)

        collectionView.ds_useDataSource(dataSource)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTranslationPageLayoutIfNeeded()
    }

    private func updateTranslationPageLayoutIfNeeded() {
        let oldRequest = request
        request = translationPage.map { TranslationPageLayoutRequest(page: $0, width: bounds.width - 2 * Layout.QuranCell.horizontalInset) }

        // if the same request
        guard oldRequest != request else {
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        // if we are reloading
        guard let request = request else {
            setLayout(nil)
            return
        }

        let layoutManager = type(of: self).sharedLayoutManager
        layoutManager.getOnMainThread(request) { [weak self] layout in
            self?.setLayout(layout)
            self?.request = request
        }
    }

    private func setLayout(_ layout: TranslationPageLayout?) {
        dataSource.page = layout
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
}
