//
//  QuranTranslationCollectionInnerDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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

    var highlights: [VerseHighlightType: Set<AyahNumber>] = [:] {
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
            ayahDataSource.add(verse: verse,
                               index: offset,
                               arabicPrefix: offset == 0 ? page.arabicPrefixLayouts : [],
                               arabicSuffix: offset == page.verseLayouts.count - 1 ? page.arabicSuffixLayouts : [],
                               hasSeparator: !isNextVerseStartOfSura)

            // add a section
            addAyahDataSource(ayahDataSource)
        }
    }

    override func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return true
    }

    private func updateHighlights() {

        // reverse the grouping
        var versesByHighlights: [AyahNumber: VerseHighlightType] = [:]
        for type in VerseHighlightType.sortedTypes.reversed() {
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
