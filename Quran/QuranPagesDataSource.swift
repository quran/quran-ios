//
//  QuranPagesDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranPagesDataSource: BasicDataSource<QuranPage, UITableViewCell> {

    let sizeService: QuranSizeService

    init(reuseIdentifier: String, sizeService: QuranSizeService) {
        self.sizeService = sizeService
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return true
    }

    override func ds_collectionView(collectionView: GeneralCollectionView, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return sizeService.pageSizeForBounds(collectionView.ds_scrollView.bounds)
    }

}
