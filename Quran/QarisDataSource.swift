//
//  QarisDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QarisDataSource: BasicDataSource<Qari, QariTableViewCell> {

    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QariTableViewCell,
                                    with item: Qari,
                                    at indexPath: IndexPath) {
        cell.titleLabel.text = item.name
        cell.photoImageView.image = item.imageName.flatMap { UIImage(named: $0) }
    }
}
