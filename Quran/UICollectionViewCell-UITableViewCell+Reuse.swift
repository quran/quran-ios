//
//  UICollectionViewCell-UITableViewCell+Reuse.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

extension ReusableCell {
    static var reuseId: String {
        return String(describing: self)
    }
}

extension GeneralCollectionView {

    func register(cell: ReusableCell.Type) {
        ds_register(UINib(nibName: String(describing: cell), bundle: nil), forCellWithReuseIdentifier: cell.reuseId)
    }
}
