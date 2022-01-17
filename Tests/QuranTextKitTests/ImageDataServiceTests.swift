//
//  ImageDataServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-09.
//

import QuranKit
import QuranMadaniData
@testable import QuranTextKit
import SnapshotTesting
import XCTest

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
        // assert the image
        assertSnapshot(matching: imagePage.image, as: .image, testName: testName)

        // assert the word frames values
        let frames = imagePage.wordFrames.frames.values.flatMap { $0 }.sorted { $0.word < $1.word }
        assertSnapshot(matching: frames, as: .json, testName: testName)

        if ProcessInfo.processInfo.environment["LocalSnapshots"] != nil {
            print("[Test] Asserting LocalSnapshots")
            // assert the drawn word frames
            let highlightedImage = try drawFrames(imagePage.image, frames: imagePage.wordFrames, strokeWords: false)
            assertSnapshot(matching: highlightedImage, as: .image, testName: testName)
        }
    }

    private func drawFrames(_ image: UIImage, frames: WordFrameCollection, strokeWords: Bool) throws -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        let fillColors: [UIColor] = [
            .systemRed,
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemTeal,
        ]
        let strokeColor = UIColor.gray
        let verses = frames.frames.keys.sorted()
        for (offset, verse) in verses.enumerated() {
            let frames = try XCTUnwrap(frames.frames[verse])
            let color = fillColors[offset % fillColors.count]
            color.setFill()
            strokeColor.setStroke()
            for frame in frames {
                let path = UIBezierPath(rect: frame.rect)
                path.fill()
                if strokeWords {
                    path.stroke()
                }
            }
        }
        image.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(newImage)
    }
}
