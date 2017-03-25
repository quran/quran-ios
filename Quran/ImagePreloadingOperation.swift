//
//  ImagePreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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
    let file = String(format: "images_\(quranImagesSize)/width_\(quranImagesSize)/page%03d.png", page)
    return file
}
