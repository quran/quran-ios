//
//  SettingsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/17.
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

struct Setting {
    let name: String
    let image: UIImage?
    let zeroInset: Bool
}

class SettingsDataSource: BasicDataSource<Setting, SettingTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SettingTableViewCell,
                                    with item: Setting,
                                    at indexPath: IndexPath) {
        cell.separatorInset = item.zeroInset ? .zero : UIEdgeInsets(top: 0, left: 55, bottom: 0, right: 0)
        cell.textLabel?.text = item.name
        cell.imageView?.image = item.image?.withRenderingMode(.alwaysTemplate)
        cell.accessoryType = .disclosureIndicator
    }
}
