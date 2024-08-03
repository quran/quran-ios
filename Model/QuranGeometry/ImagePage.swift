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

    public init(image: UIImage, wordFrames: WordFrameCollection, startAyah: AyahNumber) {
        self.image = image
        self.wordFrames = wordFrames
        self.startAyah = startAyah
    }
}
