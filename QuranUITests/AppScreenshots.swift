//
//  AppScreenshots.swift
//  QuranUITests
//
//  Created by Afifi, Mohamed on 5/5/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import XCTest

class AppScreenshots: XCTestCase {

    override func setUp() {
        Springboard.deleteMyApp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = ["disable-bars-timer"]
        app.launch()
    }

    func testBookmarks() {

        let app = XCUIApplication()
        app.tables.staticTexts["Al-Fatihah"].tap()

        let bookmarkEmptyButton = app.navigationBars["Surahs"].buttons["bookmark empty"]
        let element = app.collectionViews.scrollViews.children(matching: .other).element

        // first page
        bookmarkEmptyButton.tap()

        // second page
        element.swipeRight()
        element.tap()
        bookmarkEmptyButton.tap()

        // third page
        element.swipeRight()
        element.tap()
        bookmarkEmptyButton.tap()

        // Ayah page
        app.longTapOnQuranImage(at: CGPoint(x: 600, y: 1000))
        app.menuItems["Bookmark﻿​"].tap()

        // navigate to bookmarks list
        app.navigationBars["Surahs"].buttons["Surahs"].tap()
        app.tabBars.buttons["Bookmarks"].tap()

        record("3_bookmarks")
    }

    func testQari() {
        let app = XCUIApplication()
        app.tables.staticTexts["Al-Fatihah"].tap()
        app.buttons["Qari banner"].tap()
        record("5_qaris")
    }

    func testTranslation() {

        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["An-Nisa'"].tap()

        app.navigationBars["Surahs"].buttons["more horiz"].tap()
        tablesQuery.buttons["Translation"].tap()
        Thread.sleep(forTimeInterval: 5)

        let sahih = tablesQuery.cells.containing(.staticText, identifier:"Translator: Sahih International").children(matching: .button).element
        _ = sahih.waitForExistence(timeout: 15)

        sahih.tap()
        Thread.sleep(forTimeInterval: 5)
        tablesQuery.cells.containing(.staticText, identifier:"Translator: Abdul Haleem").children(matching: .button).element.tap()
        Thread.sleep(forTimeInterval: 5)

        tablesQuery.cells.containing(.staticText, identifier:"Translator: Sahih International").element.tap()
        tablesQuery.cells.containing(.staticText, identifier:"Translator: Abdul Haleem").element.tap()

        app.navigationBars["Select Translations/Tafseer"].buttons["Done"].tap()

        record("2_translation")
    }

    func testArabic() {
        let app = XCUIApplication()
        app.tables.staticTexts["Aal-E-Imran"].tap()
        app.longTapOnQuranImage(at: CGPoint(x: 460, y: 820))
        record("1_arabic")
    }

    func testSearch() {
        let app = XCUIApplication()
        app.tabBars.buttons["Search"].tap()
        app.buttons["تبارك"].tap()
        record("4_search")
    }

    private func record(_ name: String) {
        Thread.sleep(forTimeInterval: 1)
        snapshot(name)
    }

}

extension XCUIApplication {

    func longTapOnQuranImage(at point: CGPoint) {
        let quranImage = self.images["quranImage"]
        let imageSize = CGSize(width: 1280, height: 2071)
        let scale = getScale(imageViewSize: quranImage.frame.size, imageSize: imageSize)
        let scaledPoint = scale.scaling(point)

        quranImage.coordinate(withNormalizedOffset: CGVector(dx: scaledPoint.x / quranImage.frame.width,
                                                             dy: scaledPoint.y / quranImage.frame.height)).press(forDuration: 2.0)
    }

    private struct Scale {
        let scale: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        func scaling(_ point: CGPoint) -> CGPoint {
            return CGPoint(x: point.x * scale + xOffset,
                           y: point.y * scale + yOffset)
        }
    }

    private func getScale(imageViewSize: CGSize, imageSize: CGSize) -> Scale {
        let scale: CGFloat
        if imageSize.width / imageSize.height < imageViewSize.width / imageViewSize.height {
            scale = imageViewSize.height / imageSize.height
        } else {
            scale = imageViewSize.width / imageSize.width
        }
        let xOffset = (imageViewSize.width - (scale * imageSize.width)) / 2
        let yOffset = (imageViewSize.height - (scale * imageSize.height)) / 2
        return Scale(scale: scale, xOffset: xOffset, yOffset: yOffset)
    }
}
