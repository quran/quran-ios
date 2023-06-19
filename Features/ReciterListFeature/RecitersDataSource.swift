//
//  RecitersDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
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

import Foundation
import GenericDataSources
import Localization
import NoorUI
import QuranAudio
import UIKit

class RecitersDataSource: BasicDataSource<Reciter, ReciterTableViewCell> {
    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: ReciterTableViewCell,
        with item: Reciter,
        at indexPath: IndexPath
    ) {
        cell.titleLabel.text = item.localizedName
        cell.photoImageView.isHidden = true
    }
}

class ReciterGroupedDataSource: CompositeDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { // Recent
            return l("reciters.recent")
        }
        if section == 1 { // Downloaded
            return l("reciters.downloaded")
        }
        let languageCode = section == 2 ? "en" : "ar"
        if let language = Locale.fixedCurrentLocaleNumbers.localizedString(forLanguageCode: languageCode) {
            return l("reciters.all") + " (" + language.capitalized + ")"
        }
        return l("reciters.all")
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }
}
