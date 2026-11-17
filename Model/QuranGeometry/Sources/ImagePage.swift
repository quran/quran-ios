//
//  ImagePage.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/15/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranKit
import UIKit

public struct ImagePage: Equatable {
    public let image: UIImage
    public let wordFrames: WordFrameCollection
    public let startAyah: AyahNumber
    /// The page's text extent in image coordinates; nil when there's nothing to line up with.
    public let textColumn: ClosedRange<CGFloat>?

    public init(
        image: UIImage,
        wordFrames: WordFrameCollection,
        startAyah: AyahNumber,
        textColumn: ClosedRange<CGFloat>?
    ) {
        self.image = image
        self.wordFrames = wordFrames
        self.startAyah = startAyah
        self.textColumn = textColumn
    }
}
