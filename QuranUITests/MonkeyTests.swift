//
//  MonkeyTests.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/7/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import SwiftMonkey
import XCTest

class MonkeyTests: XCTestCase {
    func testMonkey() {
        let application = XCUIApplication()
        application.launch()

        // Workaround for bug in Xcode 7.3. Snapshots are not properly updated
        // when you initially call app.frame, resulting in a zero-sized rect.
        // Doing a random query seems to update everything properly.
        // TODO: Remove this when the Xcode bug is fixed!
        _ = application.descendants(matching: .any).element(boundBy: 0).frame

        // Initialise the monkey tester with the current device
        // frame. Giving an explicit seed will make it generate
        // the same sequence of events on each run, and leaving it
        // out will generate a new sequence on each run.
        let monkey = Monkey(frame: application.frame)
        //let monkey = Monkey(seed: 123, frame: application.frame)

        // Add actions for the monkey to perform. We just use a
        // default set of actions for this, which is usually enough.
        // Use either one of these, but maybe not both.
        // XCTest private actions seem to work better at the moment.
        // UIAutomation actions seem to work only on the simulator.
        monkey.addXCTestTapAction(weight: 15)
        monkey.addXCTestLongPressAction(weight: 8)
        monkey.addXCTestDragAction(weight: 10)
        monkey.addXCTestPinchCloseAction(weight: 1)
        monkey.addXCTestPinchOpenAction(weight: 1)
        monkey.addXCTestRotateAction(weight: 1)
        //monkey.addDefaultUIAutomationActions()

        // Occasionally, use the regular XCTest functionality
        // to check if an alert is shown, and click a random
        // button on it.
        monkey.addXCTestTapAlertAction(interval: 100, application: application)

        // Run the monkey tests for 15 minutes
        monkey.monkeyAround(forDuration: 3 * 60)
    }
}
