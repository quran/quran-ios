//
//  TextRenderPreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/28/17.
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

import UIKit
import PromiseKit

class TextRenderPreloadingOperation: AbstractPreloadingOperation<UIImage> {

    let layout: TranslationTextLayout

    init(layout: TranslationTextLayout) {
        self.layout = layout
    }

    override func main() {

        autoreleasepool {

            guard let textLayout = layout.longTextLayout else {
                fatalError("Cannot use \(type(of: self)) with nil longTextLayout")
            }

            let layoutManager = NSLayoutManager()
            let textStorage = NSTextStorage(attributedString: layout.text.attributedText)
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(textLayout.textContainer)

            // make sure the layout and glyph generations occurred.
            layoutManager.ensureLayout(for: textLayout.textContainer)
            layoutManager.ensureGlyphs(forGlyphRange: NSRange(location: 0, length: textLayout.numberOfGlyphs))

            let image = imageFromText(layoutManager: layoutManager,
                                      numberOfGlyphs: textLayout.numberOfGlyphs,
                                      size: layout.size)
            fulfill(image)
        }
    }

    private func imageFromText(layoutManager: NSLayoutManager, numberOfGlyphs: Int, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let range = NSRange(location: 0, length: numberOfGlyphs)
        layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return cast(image)
    }
}
