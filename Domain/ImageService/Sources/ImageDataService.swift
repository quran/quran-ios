//
//  ImageDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-15.
//

import QuranGeometry
import QuranKit
import UIKit
import VLogging
import WordFramePersistence
import WordFrameService

public struct ImageDataService {
    // MARK: Lifecycle

    public init(ayahInfoDatabase: URL, imagesURL: URL, cropInsets: UIEdgeInsets) {
        self.imagesURL = imagesURL
        self.cropInsets = cropInsets
        persistence = GRDBWordFramePersistence(fileURL: ayahInfoDatabase)
    }

    // MARK: Public

    public func suraHeaders(_ page: Page) async throws -> [SuraHeaderLocation] {
        try await persistence.suraHeaders(page)
    }

    public func ayahNumbers(_ page: Page) async throws -> [AyahNumberLocation] {
        try await persistence.ayahNumbers(page)
    }

    public func imageForPage(_ page: Page) async throws -> ImagePage {
        let imageURL = imageURLForPage(page)
        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            logFiles(directory: imagesURL) // <reading>/images/width/
            logFiles(directory: imagesURL.deletingLastPathComponent()) // <reading>/images/
            logFiles(directory: imagesURL.deletingLastPathComponent().deletingLastPathComponent()) // <reading>/
            fatalError("No image found for page '\(page)'")
        }

        // preload the image
        let unloadedImage: UIImage = image
        let preloadedImage = preloadImage(unloadedImage, cropInsets: cropInsets)

        let plainWordFrames = try await persistence.wordFrameCollectionForPage(page)
        let wordFrames = processor.processWordFrames(plainWordFrames, cropInsets: cropInsets)
        return ImagePage(image: preloadedImage, wordFrames: wordFrames, startAyah: page.firstVerse)
    }

    // MARK: Private

    private let processor = WordFrameProcessor()
    private let persistence: WordFramePersistence
    private let cropInsets: UIEdgeInsets
    private let imagesURL: URL

    private func logFiles(directory: URL) {
        let fileManager = FileManager.default
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        let fileNames = files.map(\.lastPathComponent)
        logger.error("Images: Directory \(directory) contains files \(fileNames)")
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
        let imageContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colourSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )

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
