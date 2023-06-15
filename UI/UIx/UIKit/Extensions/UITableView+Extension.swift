//
//  UITableView+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/22/17.
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

extension UITableView {
    public func scrollToTop(animated: Bool) {
        scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }
}

public extension UITableViewCell {
    static var reuseId: String {
        String(describing: self)
    }
}

public extension UICollectionViewCell {
    static var reuseId: String {
        String(describing: self)
    }
}

public extension UICollectionView {
    func dequeueReusableCell<CellType: UICollectionViewCell>(_ cellType: CellType.Type, for indexPath: IndexPath) -> CellType {
        let cell = dequeueReusableCell(withReuseIdentifier: CellType.reuseId, for: indexPath)
        guard let typedCell = cell as? CellType else {
            fatalError("Cannot cast cell \(cell) to type \(CellType.self)")
        }
        return typedCell
    }
}
