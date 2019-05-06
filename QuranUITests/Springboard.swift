//
//  Springboard.swift
//  QuranUITests
//
//  Created by Afifi, Mohamed on 5/5/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import XCTest

class Springboard {
    private static let appName = "Quran"

    /**
     Terminate and delete the app via springboard
     */
    class func deleteMyApp() {
        XCUIApplication().terminate()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Force delete the app from the springboard
        let icons = springboard.icons.matching(identifier: appName)
        print("AFIFI: icons", icons.count)
        if icons.count > 0 {
            let icon = icons.allElementsBoundByIndex.min { (lhs, rhs) -> Bool in
                lhs.frame.minY < rhs.frame.minY
            }!
            print("AFIFI: icon", icon)
            print("AFIFI: icon.frame", icon.frame)
            let iconFrame = icon.frame
            let springboardFrame = springboard.frame
            icon.press(forDuration: 3)

            // Tap the little "X" button at approximately where it is. The X is not exposed directly
            springboard.coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3) / springboardFrame.maxX,
                                                                  dy: (iconFrame.minY + 3) / springboardFrame.maxY)).tap()

            // Try multiple times to tap on delete,
            // it doesn't work alway from the first time
            for _ in 0..<3 {
                springboard.alerts.buttons["Delete"].tap()
                if !springboard.alerts.element.exists {
                    break
                }
            }
        }
    }
}
