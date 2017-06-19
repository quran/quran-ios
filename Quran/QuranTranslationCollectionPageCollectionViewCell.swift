//
//  QuranTranslationCollectionPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
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

    private var highlights: [QuranHighlightType: Set<AyahNumber>] = [:] {
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

        let flowLayout: UICollectionViewFlowLayout = cast(collectionView.collectionViewLayout)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0

        collectionView.ds_useDataSource(dataSource)
        dataSource.scrollViewDelegate = scrollNotifier
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

    override func ayahWordPosition(at point: CGPoint) -> AyahWordPosition? {

        let localPoint = collectionView.convert(point, from: self)
        let indexPath = collectionView.indexPathForItem(at: localPoint)
        let cell = indexPath.flatMap { collectionView.cellForItem(at: $0) }
        let translationCell = cell as? QuranTranslationBaseCollectionViewCell
        return translationCell?.ayah.map { AyahWordPosition(ayah: $0, position: -1, frame: .zero) }
    }

    override func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: QuranHighlightType) {
        highlights[type] = verses
        if QuranHighlightType.scrollingTypes.contains(type) {
            scrollToReadingHighlightedAyat()
        }
    }

    override func highlightedVerse(forType type: QuranHighlightType) -> Set<AyahNumber>? {
        return highlights[type]
    }

    private func scrollToReadingHighlightedAyat() {
        // layout views if needed
        layoutIfNeeded()

        var optionalAyah: AyahNumber? = nil
        for highlightType in QuranHighlightType.scrollingTypes {
            if let firstAyah = highlights[highlightType]?.first {
                optionalAyah = firstAyah
                break
            }
        }

        guard let ayah = optionalAyah else {
            return
        }
        guard let indexPath = dataSource.indexPath(forAyah: ayah) else {
            return
        }
        // scroll to the reading/search ayah
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
    }

    override func highlight(position: AyahWordPosition?) {
        // not supported yet
    }
}
