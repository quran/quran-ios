//
//  ImageDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-15.
//

import QuranKit
import UIKit

public protocol ImageDataService {
    func imageForPage(_ page: Page) throws -> ImagePage
}

public struct DefaultImageDataService: ImageDataService {
    private let processor: WordFrameProcessor
    private let persistence: WordFramePersistence
    private let madaniCropInsets = UIEdgeInsets(top: 10, left: 34, bottom: 40, right: 24)
    private let imageSize: String

    init(imageSize: String, processor: WordFrameProcessor, persistence: WordFramePersistence) {
        self.imageSize = imageSize
        self.persistence = persistence
        self.processor = processor
    }

    public init(imageSize: String) {
        self.imageSize = imageSize
        processor = DefaultWordFrameProcessor()
        persistence = SQLiteWordFramePersistence(imageSize: imageSize)
    }

    public func imageForPage(_ page: Page) throws -> ImagePage {
        guard let filePath = fullPathForPage(page), let image = UIImage(contentsOfFile: filePath) else {
            fatalError("No image found for page '\(page)'")
        }

        // preload the image
        let unloadedImage: UIImage = image
        let preloadedImage = preloadImage(unloadedImage, cropInsets: madaniCropInsets)

        let plainWordFrames = try persistence.wordFrameCollectionForPage(page)
        let wordFrames = processor.processWordFrames(plainWordFrames, cropInsets: madaniCropInsets)
        return ImagePage(image: preloadedImage, wordFrames: wordFrames, startAyah: page.firstVerse)
    }

    private func fullPathForPage(_ page: Page) -> String? {
        let relativePath = fileNameForPage(page)
        return Bundle.main.path(forResource: relativePath, ofType: nil)
    }

    private func fileNameForPage(_ page: Page) -> String {
        let file = "images_\(imageSize)/width_\(imageSize)/page" + page.pageNumber.as3DigitString() + ".png"
        return file
    }

    private func preloadImage(_ imageToPreload: UIImage, cropInsets: UIEdgeInsets = .zero) -> UIImage {
        let targetImage: CGImage?
        if let cgImage = imageToPreload.cgImage {
            targetImage = cgImage
        } else if let ciImage = imageToPreload.ciImage {
            let context = CIContext(options: nil)
            targetImage = context.createCGImage(ciImage, from: ciImage.extent)
        } else {
            targetImage = nil
        }
        guard var cgimg = targetImage else {
            return imageToPreload
        }

        let rect = CGRect(x: 0, y: 0, width: cgimg.width, height: cgimg.height)
        let croppedRect = rect.inset(by: cropInsets)
        let cropped = cgimg.cropping(to: croppedRect)
        cgimg = cropped ?? cgimg

        // make a bitmap context of a suitable size to draw to, forcing decode
        let width = cgimg.width
        let height = cgimg.height

        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: width * 4,
                                     space: colourSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        // draw the image to the context, release it
        imageContext?.draw(cgimg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // now get an image ref from the context
        if let outputImage = imageContext?.makeImage() {
            let cachedImage = UIImage(cgImage: outputImage)
            return cachedImage
        }
        return imageToPreload
    }
}
