//
//  QuranImagesDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranImagesDataSource: QuranBaseBasicDataSource<QuranImagePageCollectionViewCell>, QuranDataSourceHandler {

    private let imageService: AnyCacheableService<Int, UIImage>
    private let ayahInfoRetriever: AyahInfoRetriever

    private let numberFormatter = NumberFormatter()

    private var highlightedAyat: Set<AyahNumber> = Set()

    init(imageService: AnyCacheableService<Int, UIImage>,
         ayahInfoRetriever: AyahInfoRetriever,
         bookmarkPersistence: BookmarksPersistence) {
        self.imageService = imageService
        self.ayahInfoRetriever = ayahInfoRetriever
        super.init(bookmarkPersistence: bookmarkPersistence)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranImagePageCollectionViewCell,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {
        // configure the super
        super.ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)

        // configure the cell
        cell.pageLabel.text = numberFormatter.format(NSNumber(value: item.pageNumber))
        cell.suraLabel.text = Quran.nameForSura(item.startAyah.sura)
        cell.juzLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), item.juzNumber)

        // set the page image
        imageService.getOnMainThread(item.pageNumber) { [weak cell] image in
            guard cell?.page == item else { return }
            cell?.mainImageView.image = image
        }

        // set the ayah dimensions
        ayahInfoRetriever
            .retrieveAyahs(in: item.pageNumber)
            .then(on: .main) { [weak cell] data -> Void in
                guard cell?.page == item else { return }
                cell?.setAyahInfo(data)
        }.cauterize(tag: "retrieveAyahs(in:)")
    }

    func invalidate() {
        // does nothing
    }
}
