//
//  QuranTranslationAyahSectionDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
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

class QuranTranslationAyahSectionDataSource: CompositeDataSource {

    private static let numberFormatter = NumberFormatter()

    let ayah: AyahNumber

    var highlightType: QuranHighlightType?

    init(ayah: AyahNumber) {
        self.ayah = ayah
        super.init(sectionType: .single)
    }

    func add(verse: TranslationVerseLayout, index: Int, hasSeparator: Bool) {

        // if start of page or a new sura
        if index == 0 || verse.ayah.ayah == 1 {
            let sura = QuranTranslationSuraDataSource()
            sura.items = [Quran.nameForSura(verse.ayah.sura, withPrefix: true)]
            add(sura)
        }

        // add prefixes
        if !verse.arabicPrefixLayouts.isEmpty {
            let prefix = QuranTranslationArabicTextDataSource()
            prefix.items = verse.arabicPrefixLayouts
            add(prefix)
        }

        // add the verse number
        let formatter = QuranTranslationAyahSectionDataSource.numberFormatter
        let number = QuranTranslationVerseNumberDataSource()
        number.items = ["\(formatter.format(verse.ayah.sura)):\(formatter.format(verse.ayah.ayah))"]
        add(number)

        let arabic = QuranTranslationArabicTextDataSource()
        arabic.items = [verse.arabicTextLayout]
        add(arabic)

        for translationText in verse.translationLayouts {
            if verse.translationLayouts.count > 1 {
                let name = QuranTranslationTranslatorNameTextDataSource()
                name.items = [translationText]
                add(name)
            }

            if translationText.longTextLayout != nil {
                let translation = QuranTranslationLongTextDataSource()
                translation.items = [translationText]
                add(translation)
            } else {
                let translation = QuranTranslationTextDataSource()
                translation.items = [translationText]
                add(translation)
            }
        }

        // add prefixes suffixes
        if !verse.arabicSuffixLayouts.isEmpty {
            let suffix = QuranTranslationArabicTextDataSource()
            suffix.items = verse.arabicSuffixLayouts
            add(suffix)
        }

        // add separator only if next verse is not a start of a new sura
        if hasSeparator {
            let separator = QuranTranslationVerseSeparatorDataSource()
            separator.items = [()]
            add(separator)
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell {
        let cell = super.ds_collectionView(collectionView, cellForItemAt: indexPath)
        if let cell = cell as? QuranTranslationBaseCollectionViewCell {
            cell.ayah = ayah
            cell.backgroundColor = highlightType?.color
        }
        return cell
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? QuranTranslationBaseCollectionViewCell {
            cell.ayah = ayah
            cell.backgroundColor = highlightType?.color
        }
    }
}
