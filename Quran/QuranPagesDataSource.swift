//
//  QuranPagesDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranPagesDataSource: BasicDataSource<QuranPage, QuranPageCollectionViewCell> {

    let imageService: QuranImageService
    let ayahInfoRetriever: AyahInfoRetriever

    let numberFormatter = NSNumberFormatter()

    init(reuseIdentifier: String, imageService: QuranImageService, ayahInfoRetriever: AyahInfoRetriever) {
        self.imageService = imageService
        self.ayahInfoRetriever = ayahInfoRetriever
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: QuranPageCollectionViewCell,
                                    withItem item: QuranPage,
                                    atIndexPath indexPath: NSIndexPath) {

        let size = ds_collectionView(collectionView, sizeForItemAtIndexPath: indexPath)

        cell.page = item
        cell.pageLabel.text = numberFormatter.format(item.pageNumber)
        cell.suraLabel.text = NSLocalizedString("sura_names[\(item.startAyah.sura - 1)]", comment: "")
        cell.juzLabel.text = String(format: NSLocalizedString("juz2_description", comment: ""), item.juzNumber)

        cell.mainImageView.image = nil

        imageService.getImageOfPage(item.pageNumber, forSize: size) { (image) in
            guard cell.page == item else {
                return
            }
            cell.mainImageView.image = image
        }

        ayahInfoRetriever.retrieveAyahsAtPage(item.pageNumber) { (data) in
            guard cell.page == item else {
                return
            }
            cell.setAyahInfo(data.value)
        }
    }
}
