//
//  ImagePreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
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

class ImagePreloadingOperation: AbstractPreloadingOperation<UIImage> {

    let page: Int

    init(page: Int) {
        self.page = page
    }

    override func main() {
        guard let filePath = fullPathForPage(page), let image = UIImage(contentsOfFile: filePath) else {
            fatalError("No image found for page '\(page)'")
        }

        // preload the image
        let preloadedImage = image.preloadedImage()
        fulfill(preloadedImage)
    }
}

private func fullPathForPage(_ page: Int) -> String? {
    let relativePath = fileNameForPage(page)
    return Bundle.main.path(forResource: relativePath, ofType: nil)
}

private func fileNameForPage(_ page: Int) -> String {
    let file = "images_\(quranImagesSize)/width_\(quranImagesSize)/page" + page.as3DigitString() + ".png"
    return file
}
