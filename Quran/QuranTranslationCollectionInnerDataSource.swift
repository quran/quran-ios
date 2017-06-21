//
//  QuranTranslationCollectionInnerDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
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

class QuranTranslationCollectionInnerDataSource: CompositeDataSource {

    private var ayahsDataSources: [AyahNumber: QuranTranslationAyahSectionDataSource] = [:]

    var page: TranslationPageLayout? {
        didSet {
            removeAllDataSources()
            if let page = page {
                populate(page: page)
                updateHighlights()
            }
        }
    }

    var highlights: [QuranHighlightType: Set<AyahNumber>] = [:] {
        didSet { updateHighlights() }
    }

    init() {
        super.init(sectionType: .single)
    }

    override func removeAllDataSources() {
        super.removeAllDataSources()
        ayahsDataSources.removeAll()
    }

    func indexPath(forAyah ayah: AyahNumber) -> IndexPath? {

        // not found
        guard let ds = ayahsDataSources[ayah] else {
            return nil
        }

        // get the index path of the first item in the child data source
        let indexPath = globalIndexPathForLocalIndexPath(IndexPath(item: 0, section: 0), dataSource: ds)
        return indexPath
    }

    private func addAyahDataSource(_ dataSource: QuranTranslationAyahSectionDataSource) {
        add(dataSource)
        ayahsDataSources[dataSource.ayah] = dataSource
    }

    private func populate(page: TranslationPageLayout) {
        for (offset, verse) in page.verseLayouts.enumerated() {

            let nextOffset = offset + 1
            let isNextVerseStartOfSura = nextOffset < page.verseLayouts.count && page.verseLayouts[nextOffset].ayah.ayah == 1

            // add an ayah data source
            let ayahDataSource = QuranTranslationAyahSectionDataSource(ayah: verse.ayah)
            ayahDataSource.add(verse: verse, index: offset, hasSeparator: !isNextVerseStartOfSura)

            // add a section
            addAyahDataSource(ayahDataSource)
        }
    }

    override func ds_responds(to selector: DataSourceSelector) -> Bool {
        if selector == .size {
            return true
        }
        return super.ds_responds(to: selector)
    }

    private func updateHighlights() {

        // reverse the grouping
        var versesByHighlights: [AyahNumber: QuranHighlightType] = [:]
        for type in QuranHighlightType.sortedTypes.reversed() {
            let verses = highlights[type]
            for verse in verses ?? Set() {
                versesByHighlights[verse] = type
            }
        }

        // update the data sources highlights
        for ds in ayahsDataSources.values {
            ds.highlightType = versesByHighlights[ds.ayah]
        }

        // update the colors of visible cells
        for cell in ds_reusableViewDelegate?.ds_visibleCells() ?? [] {
            if let cell = cell as? QuranTranslationBaseCollectionViewCell {
                let type = cell.ayah.flatMap { versesByHighlights[$0] }
                cell.backgroundColor = type?.color
            }
        }
    }
}
