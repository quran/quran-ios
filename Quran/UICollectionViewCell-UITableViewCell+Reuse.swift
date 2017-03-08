//
//  UICollectionViewCell-UITableViewCell+Reuse.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
    static var reuseId: String {
        return String(describing: self)
    }
}

extension UITableViewCell {
    static var reuseId: String {
        return String(describing: self)
    }
}


extension UICollectionView {

    func register(cell: UICollectionViewCell.Type) {
        register(UINib(nibName: String(describing: cell), bundle: nil), forCellWithReuseIdentifier: cell.reuseId)
    }
}


extension UITableView {

    func register(cell: UITableViewCell.Type) {
        register(UINib(nibName: String(describing: cell), bundle: nil), forCellReuseIdentifier: cell.reuseId)
    }
}
