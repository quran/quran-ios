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

    private static let numberFormatter = NumberFormatter()

    var page: TranslationPageLayout? {
        didSet {
            removeAllDataSources()
            if let page = page {
                populate(page: page)
            }
        }
    }

    init() {
        super.init(sectionType: .single)
    }

    private func populate(page: TranslationPageLayout) {
        removeAllDataSources()

        for (offset, verse) in page.verseLayouts.enumerated() {

            // if start of page or a new sura
            if offset == 0 || verse.ayah.ayah == 1 {
                let sura = QuranTranslationSuraDataSource()
                sura.items = [Quran.nameForSura(verse.ayah.sura, withPrefix: true)]
                add(sura)
            }

            // add prefixes and suffixes
            if offset == 0 {
                let prefix = QuranTranslationArabicTextDataSource()
                prefix.items = page.arabicPrefixLayouts
                add(prefix)
            } else if offset == page.verseLayouts.count - 1 {
                let suffix = QuranTranslationArabicTextDataSource()
                suffix.items = page.arabicSuffixLayouts
                add(suffix)
            }

            // add the verse number
            let formatter = QuranTranslationCollectionInnerDataSource.numberFormatter
            let number = QuranTranslationVerseNumberDataSource()
            number.items = ["\(formatter.format(verse.ayah.sura)):\(formatter.format(verse.ayah.ayah))"]
            add(number)

            let arabic = QuranTranslationArabicTextDataSource()
            arabic.items = [verse.arabicTextLayout]
            add(arabic)

            for translationText in verse.translationLayouts {
                if verse.translationLayouts.count > 1 {
                    let name  = QuranTranslationTranslatorNameTextDataSource()
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

            // add separator only if next verse is not a start of a new sura
            let nextOffset = offset + 1
            let isNextVerseStartOfSura = nextOffset < page.verseLayouts.count && page.verseLayouts[nextOffset].ayah.ayah == 1
            if !isNextVerseStartOfSura {
                let separator = QuranTranslationVerseSeparatorDataSource()
                separator.items = [()]
                add(separator)
            }
        }
    }

    override func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return true
    }
}
