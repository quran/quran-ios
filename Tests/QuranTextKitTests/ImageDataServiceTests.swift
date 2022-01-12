//
//  ImageDataServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-09.
//

import QuranKit
import QuranMadaniData
@testable import QuranTextKit
import XCTest
import SnapshotTesting

class ImageDataServiceTests: XCTestCase {
    var service: ImageDataService!
    let quran = Quran.madani

    override func setUpWithError() throws {
        service = ImageDataService(
            ayahInfoDatabase: QuranMadaniData.ayahInfoDatabase,
            imagesURL: QuranMadaniData.images
        )
    }

    func testGettingImageAtPage1() throws {
        let page = quran.pages[0]
        let image = try service.imageForPage(page)
        XCTAssertEqual(image.startAyah, page.firstVerse)
        try verifyImagePage(image)
    }

    func testGettingImageAtPage3() throws {
        let page = quran.pages[2]
        let image = try service.imageForPage(page)
        XCTAssertEqual(image.startAyah, page.firstVerse)
        try verifyImagePage(image)
    }

    func testGettingImageAtPage604() throws {
        let page = quran.pages.last!
        let image = try service.imageForPage(page)
        XCTAssertEqual(image.startAyah, page.firstVerse)
        try verifyImagePage(image)
    }

    private func verifyImagePage(_ imagePage: ImagePage, testName: String = #function) throws {
        assertSnapshot(matching: imagePage.image, as: .image, testName: testName)
        assertSnapshot(matching: try drawFrames(imagePage.image, frames: imagePage.wordFrames), as: .image, testName: testName)
    }

    private func drawFrames(_ image: UIImage, frames: WordFrameCollection) throws -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        let colors: [UIColor] = [
            .systemRed,
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemTeal,
        ]
        let verses = frames.frames.keys.sorted()
        for (offset, verse) in verses.enumerated() {
            let frames = try XCTUnwrap(frames.frames[verse])
            let color = colors[offset % colors.count]
            color.setFill()
            UIColor.gray.setStroke()
            for frame in frames {
                UIBezierPath(rect: frame.rect).fill()
                UIBezierPath(rect: frame.rect).stroke()
            }
        }
        image.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(newImage)
    }
}
