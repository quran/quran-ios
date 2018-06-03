//
//  EmptyTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/26/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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
import UIKit

class EmptyTableViewCell: ThemedTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    private func setUp() {
        kind = Theme.Kind.background
        separatorInset = .zero
    }
}

class EmptyDataSource: BasicDataSource<Void, EmptyTableViewCell> {
    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

class ThemedEmptyDataSource: BasicDataSource<Theme.Kind, EmptyTableViewCell> {
    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: EmptyTableViewCell,
                                    with item: Theme.Kind,
                                    at indexPath: IndexPath) {
        cell.kind = item
    }
}
