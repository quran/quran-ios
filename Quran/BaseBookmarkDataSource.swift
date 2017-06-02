//
//  BaseBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/7/17.
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

import GenericDataSources

protocol BookmarkDataSourceDelegate: class {
    func bookmarkDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error)
}

class BaseBookmarkDataSource<ItemType: Bookmark, CellType: ReusableCell>: EditableBasicDataSource<ItemType, CellType> {

    let persistence: BookmarksPersistence

    weak var delegate: BookmarkDataSourceDelegate?

    init(persistence: BookmarksPersistence) {
        self.persistence = persistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    commit editingStyle: UITableViewCellEditingStyle,
                                    forItemAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let item = self.item(at: indexPath)

        if let page = item as? PageBookmark {
            Analytics.shared.unbookmark(quranPage: page.page)
        } else if let ayah = item as? AyahBookmark {
            Analytics.shared.unbookmark(ayah: ayah.ayah)
        }

        DispatchQueue.default.promise2 {
            try self.persistence.remove(item)
        }.then(on: .main) { () -> Void in
            guard indexPath.item < self.items.count else {
                return
            }
            self.items.remove(at: indexPath.item)
            self.ds_reusableViewDelegate?.ds_deleteItems(at: [indexPath], with: .left)
        }.catch(on: .main) { error in
            self.delegate?.bookmarkDataSource(self, errorOccurred: error)
        }
    }
}
