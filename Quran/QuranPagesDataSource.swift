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

    let numberFormatter = NSNumberFormatter()

    init(reuseIdentifier: String, imageService: QuranImageService) {
        self.imageService = imageService
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: QuranPageCollectionViewCell,
                                    withItem item: QuranPage,
                                    atIndexPath indexPath: NSIndexPath) {

        let size = ds_collectionView(collectionView, sizeForItemAtIndexPath: indexPath)

        cell.page = item
        cell.pageLabel.text = numberFormatter.format(item.pageNumber)
        cell.mainImageView.image = nil

        imageService.getImageOfPage(item.pageNumber, forSize: size) { (image) in
            guard cell.page == item else {
                return
            }
            cell.mainImageView.image = image
        }
    }
}
