//
//  TranslationPageLayoutOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import PromiseKit

class TranslationPageLayoutOperation: AbstractPreloadingOperation<TranslationPageLayout> {

    let page: TranslationPage
    let width: CGFloat

    init(request: TranslationPageLayoutRequest) {
        self.page = request.page
        self.width = request.width - Layout.Translation.horizontalInset * 2
    }

    override func main() {

        autoreleasepool {
            let verseLayouts = page.verses.map { verse -> TranslationVerseLayout in
                let arabicPrefixLayouts = verse.arabicPrefix.map { arabicLayoutFrom($0) }
                let arabicSuffixLayouts = verse.arabicSuffix.map { arabicLayoutFrom($0) }
                return TranslationVerseLayout(ayah: verse.ayah,
                                       arabicTextLayout: arabicLayoutFrom(verse.arabicText),
                                       translationLayouts: verse.translations.map { translationTextLayoutFrom($0) },
                                       arabicPrefixLayouts: arabicPrefixLayouts,
                                       arabicSuffixLayouts: arabicSuffixLayouts)
            }
            let pageLayout = TranslationPageLayout(pageNumber: page.pageNumber, verseLayouts: verseLayouts)
            fulfill(pageLayout)
        }
    }

    private func arabicLayoutFrom(_ text: String) -> TranslationArabicTextLayout {
        let size = text.size(withFont: .translationArabicQuranText, constrainedToWidth: width)
        return TranslationArabicTextLayout(arabicText: text, size: size)
    }

    private func translationTextLayoutFrom(_ text: TranslationText) -> TranslationTextLayout {
        let translatorSize = text.translation.translationName.size(withFont: text.translation.preferredTranslatorNameFont, constrainedToWidth: width)

        if text.isLongText {
            return longTranslationTextLayoutFrom(text, translatorSize: translatorSize)
        } else {
            return shortTranslationTextLayoutFrom(text, translatorSize: translatorSize)
        }
    }

    private func shortTranslationTextLayoutFrom(_ text: TranslationText, translatorSize: CGSize) -> TranslationTextLayout {
        let size = text.attributedText.stringSize(constrainedToWidth: width)
        return TranslationTextLayout(text: text, size: size, longTextLayout: nil, translatorSize: translatorSize)
    }

    private func longTranslationTextLayoutFrom(_ text: TranslationText, translatorSize: CGSize) -> TranslationTextLayout {
        // create the main objects
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .infinity))
        textContainer.lineFragmentPadding = 0
        let textStorage = NSTextStorage(attributedString: text.attributedText)

        // connect the objects together
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        // get number of glyphs
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        let range = NSRange(location: 0, length: numberOfGlyphs)

        // get the size in screen
        let bounds = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)

        let size = CGSize(width: width, height: ceil(bounds.height))
        let textLayout = LongTranslationTextLayout(textContainer: textContainer, numberOfGlyphs: numberOfGlyphs)
        return TranslationTextLayout(text: text, size: size, longTextLayout: textLayout, translatorSize: translatorSize)
    }
}
