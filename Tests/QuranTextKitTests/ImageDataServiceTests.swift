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
        assertSnapshot(matching: imagePage.image, as: .image, testName: testName)
        assertSnapshot(matching: try drawFrames(imagePage.image, frames: imagePage.wordFrames), as: .image, testName: testName)
        let frames = imagePage.wordFrames.frames.values.flatMap { $0 }.sorted { $0.word < $1.word }
        assertSnapshot(matching: frames, as: .json, testName: testName)
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
            for frame in frames {
                UIBezierPath(rect: frame.rect).fill()
            }
        }
        image.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(newImage)
    }
}

extension AyahNumber: Encodable {
    enum CodingKeys: String, CodingKey {
        case sura
        case ayah
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sura.suraNumber, forKey: .sura)
        try container.encode(ayah, forKey: .ayah)
    }
}

extension Word: Encodable {
    enum CodingKeys: String, CodingKey {
        case verse
        case word
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verse, forKey: .verse)
        try container.encode(wordNumber, forKey: .word)
    }
}

extension WordFrame: Encodable {
    enum CodingKeys: String, CodingKey {
        case word
        case frame
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(rect, forKey: .frame)
    }
}
