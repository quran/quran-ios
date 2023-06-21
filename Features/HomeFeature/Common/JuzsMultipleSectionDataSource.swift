//
//  JuzsMultipleSectionDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
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
import NoorUI
import UIKit

class JuzsMultipleSectionDataSource: CompositeDataSource {
    // MARK: Lifecycle

    override init(sectionType: SectionType) {
        headerCreator.size = CGSize(width: 0, height: UITableView.automaticDimension)
        super.init(sectionType: sectionType)
        set(headerCreator: headerCreator)
    }

    // MARK: Internal

    let headerCreator = TableHeaderSupplementaryViewCreator()

    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        sizeForSupplementaryViewOfKind kind: String,
        at indexPath: IndexPath
    ) -> CGSize {
        if dataSource(at: indexPath.section).ds_numberOfItems(inSection: 0) == 0 {
            return .zero
        } else {
            return super.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
        }
    }
}
