//
//  QuranTranslationVerseSeparatorDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class QuranTranslationVerseSeparatorDataSource: BasicDataSource<(), QuranTranslationVerseSeparatorTableViewCell> {
    init() {
        super.init(reuseIdentifier: QuranTranslationVerseSeparatorTableViewCell.reuseId)
    }
}
