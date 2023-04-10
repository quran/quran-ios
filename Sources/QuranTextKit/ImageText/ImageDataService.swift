//
//  ImageDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-15.
//

import QuranKit
import UIKit
import VLogging

public struct ImageDataService {
    // Page 585 (surah abasa) has the widest image for 1405 that I've come across
    public static let madani1405CropInsets = UIEdgeInsets(top: 0, left: 42, bottom: 0, right: 26)
    public static let madani1440CropInsets = UIEdgeInsets(top: 0, left: 22, bottom: 15, right: 22)

    private let reading = ReadingPreferences.shared.reading
    private let processor: WordFrameProcessor
    private let persistence: WordFramePersistence
    private let cropInsets: UIEdgeInsets
    private let imagesURL: URL

    public init(ayahInfoDatabase: URL, imagesURL: URL) {
        self.imagesURL = imagesURL
        self.cropInsets = Self.cropInsetsForMushaf(reading)
        processor = DefaultWordFrameProcessor()
        persistence = SQLiteWordFramePersistence(fileURL: ayahInfoDatabase)
    }

    public func imageForPage(_ page: Page) throws -> ImagePage {
        let imageURL = imageURLForPage(page)
        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            fatalError("No image found for page '\(page)'")
        }

        // preload the image
        let unloadedImage: UIImage = image
        let preloadedImage = preloadImage(unloadedImage, cropInsets: cropInsets)

        let plainWordFrames = try persistence.wordFrameCollectionForPage(page)
        let wordFrames = processor.processWordFrames(plainWordFrames, cropInsets: cropInsets)
        return ImagePage(image: preloadedImage, wordFrames: wordFrames, startAyah: page.firstVerse)
    }

    private static func cropInsetsForMushaf(_ reading: Reading) -> UIEdgeInsets {
        switch (reading) {
            case .hafs_1405:
                return madani1405CropInsets
            case .hafs_1440:
                return madani1440CropInsets
            default:
                // Reaching here means we didn't account for a new mushaf type
                // FIXME: question: should an exception be thrown instead?
                logger.warning("Reading \(reading) does not have insets defined.");
                return madani1405CropInsets;
        }

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
