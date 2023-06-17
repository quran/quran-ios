//
//  ImageDataServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-09.
//

import QuranGeometry
import QuranKit
import SnapshotTesting
import TestResources
import WordFrameService
import XCTest
@testable import ImageService

@MainActor
class ImageDataServiceTests: XCTestCase {
    var service: ImageDataService!
    let quran = Quran.hafsMadani1405

    override func setUpWithError() throws {
        service = ImageDataService(
            ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
            imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
            cropInsets: UIEdgeInsets(top: 10, left: 34, bottom: 40, right: 24)
        )
    }

    func testPageMarkers() async throws {
        let quran = Reading.hafs_1421.quran
        service = ImageDataService(
            ayahInfoDatabase: TestResources.resourceURL("hafs_1421_ayahinfo_1120.db"),
            imagesURL: URL(string: "invalid")!,
            cropInsets: .zero
        )

        var surasHeaders = 0
        for page in quran.pages {
            let markers = try await service.pageMarkers(page)
            XCTAssertEqual(markers.ayahNumbers.count, page.verses.count, "Page \(page.pageNumber)")
            surasHeaders += markers.suraHeaders.count
        }
        XCTAssertEqual(surasHeaders, quran.suras.count)
    }

    func testWordFrameCollection() async throws {
        let page = quran.pages[0]
        let image = try await service.imageForPage(page)
        let wordFrames = image.wordFrames

        XCTAssertEqual(wordFrames.frames[page.firstVerse], wordFrames.wordFramesForVerse(page.firstVerse))
        XCTAssertEqual(CGRect(x: 671.0, y: 244.0, width: 46.0, height: 95.0),
                       wordFrames.wordFrameForWord(Word(verse: page.firstVerse, wordNumber: 2))?.rect)
        XCTAssertNil(wordFrames.wordFramesForVerse(quran.lastVerse))

        let verticalScaling = WordFrameScale.scaling(imageSize: image.image.size, into: CGSize(width: 359, height: 668))
        let horizontalScaling = WordFrameScale.scaling(imageSize: image.image.size, into: CGSize(width: 708, height: 1170.923076923077))

        XCTAssertEqual(Word(verse: AyahNumber(quran: quran, sura: 1, ayah: 6)!, wordNumber: 1),
                       wordFrames.wordAtLocation(CGPoint(x: 69, y: 225), imageScale: verticalScaling))

        XCTAssertEqual(Word(verse: AyahNumber(quran: quran, sura: 1, ayah: 3)!, wordNumber: 1),
                       wordFrames.wordAtLocation(CGPoint(x: 570, y: 280), imageScale: horizontalScaling))

        XCTAssertNil(wordFrames.wordAtLocation(.zero, imageScale: verticalScaling))
    }

    func testGettingImageAtPage1() async throws {
        let page = quran.pages[0]
        let image = try await service.imageForPage(page)
        XCTAssertEqual(image.startAyah, page.firstVerse)
        try verifyImagePage(image)
    }

    func testGettingImageAtPage3() async throws {
        let page = quran.pages[2]
        let image = try await service.imageForPage(page)
        XCTAssertEqual(image.startAyah, page.firstVerse)
        try verifyImagePage(image)
    }

    func testGettingImageAtPage604() async throws {
        let page = quran.pages.last!
        let image = try await service.imageForPage(page)
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
