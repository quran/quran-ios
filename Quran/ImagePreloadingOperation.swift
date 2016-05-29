//
//  ImagePreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ImagePreloadingOperation: NSOperation {

    let page: Int

    private var completionBlocks: [(Int, UIImage) -> Void] = []

    private (set) var image: UIImage?

    init(page: Int) {
        self.page = page
        super.init()

        completionBlock = { [weak self] in
            guard let image = self?.image else {
                return
            }
            self?.completionBlocks.forEach { $0(page, image) }
        }
    }

    override func main() {
        guard let filePath = fullPathForPage(page),
            let image = UIImage(contentsOfFile: filePath) else {
                fatalError("No image found for page '\(page)'")
        }

        // preload the image
        self.image = image.preloadedImage()
    }

    func addCompletionBlock(block: (Int, UIImage) -> Void) {
        completionBlocks.append(block)
    }
}

private func fullPathForPage(page: Int) -> String? {
    let relativePath = fileNameForPage(page)
    return NSBundle.mainBundle().pathForResource(relativePath, ofType: nil)
}

private func fileNameForPage(page: Int) -> String {
    let file = String(format: "images_\(quranImagesSize)/width_\(quranImagesSize)/page%03d.png", page)
    return file
}
