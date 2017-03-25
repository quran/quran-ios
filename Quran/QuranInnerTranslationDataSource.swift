//
//  QuranInnerTranslationDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/24/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranInnerTranslationDataSource: CompositeDataSource {

    let numberFormatter = NumberFormatter()

    var page: TranslationPage? {
        didSet {
            removeAllDataSources()
            if let page = page {
                populate(page: page)
            }
            ds_reusableViewDelegate?.ds_reloadData()
        }
    }

    init() {
        super.init(sectionType: .single)
    }

    private func populate(page: TranslationPage) {
        removeAllDataSources()

        for (offset, verse) in page.verses.enumerated() {

            // if start of page or a new sura
            if offset == 0 || verse.ayah.ayah == 1 {
                if dataSources.last is QuranTranslationVerseSeparatorDataSource {
                    remove(at: dataSources.count - 1)
                }

                let sura = QuranTranslationSuraDataSource()
                sura.items = [Quran.nameForSura(verse.ayah.sura, withPrefix: true)]
                add(sura)
            }

            // add prefixes and suffixes
            if offset == 0 {
                let prefix = QuranTranslationArabicTextDataSource()
                prefix.items = page.arabicPrefix
                add(prefix)
            } else if offset == page.verses.count - 1 {
                let suffix = QuranTranslationArabicTextDataSource()
                suffix.items = page.arabicSuffix
                add(suffix)
            }

            // add the verse number
            let number = QuranTranslationVerseNumberDataSource()
            let suraNumber = NSNumber(value: verse.ayah.sura)
            let ayahNumber = NSNumber(value: verse.ayah.ayah)
            number.items = ["\(suraNumber):\(ayahNumber)"]
            add(number)

            let arabic = QuranTranslationArabicTextDataSource()
            arabic.items = [verse.arabicText]
            add(arabic)

            for translationText in verse.translations {
                if verse.translations.count > 1 {
                    let name  = QuranTranslationNameTextDataSource()
                    name.items = [translationText.translation.translationName]
                    add(name)
                }

                let translation = QuranTranslationTextDataSource()
                translation.items = [translationText.text]
                add(translation)
            }

            let separator = QuranTranslationVerseSeparatorDataSource()
            separator.items = [()]
            add(separator)
        }
    }
}
