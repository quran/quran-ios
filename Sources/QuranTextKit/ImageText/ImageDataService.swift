//
//  ImageDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-15.
//

import QuranKit
import UIKit

public struct ImageDataService {
    private let processor: WordFrameProcessor
    private let persistence: WordFramePersistence
    private let cropInsets: UIEdgeInsets
    private let imagesURL: URL

    public init(ayahInfoDatabase: URL, imagesURL: URL, cropInsets: UIEdgeInsets) {
        self.imagesURL = imagesURL
        self.cropInsets = cropInsets
        processor = DefaultWordFrameProcessor()
        persistence = GRDBWordFramePersistence(fileURL: ayahInfoDatabase)
    }

    public func pageMarkers(_ page: Page) async throws -> PageMarkers {
        await PageMarkers(
            suraHeaders: try persistence.suraHeaders(page),
            ayahNumbers: try persistence.ayahNumbers(page)
        )
    }

    public func imageForPage(_ page: Page) async throws -> ImagePage {
        let imageURL = imageURLForPage(page)
        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            fatalError("No image found for page '\(page)'")
        }

        // preload the image
        let unloadedImage: UIImage = image
        let preloadedImage = preloadImage(unloadedImage, cropInsets: cropInsets)

        let plainWordFrames = try await persistence.wordFrameCollectionForPage(page)
        let wordFrames = processor.processWordFrames(plainWordFrames, cropInsets: cropInsets)
        return ImagePage(image: preloadedImage, wordFrames: wordFrames, startAyah: page.firstVerse)
    }

    private func imageURLForPage(_ page: Page) -> URL {
        imagesURL.appendingPathComponent("page\(page.pageNumber.as3DigitString()).png")
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
