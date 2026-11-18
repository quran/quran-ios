//
//  TabSwitchRotationTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import UIKit
import XCTest
@testable import AppStructureFeature

final class TabSwitchRotationTests: XCTestCase {
    func test_leavingAPortraitOnlyTabInLandscape_rotatesBackToTheDevice() {
        // Search is portrait only. The device is held in landscape while it shows.
        let orientations = TabSwitchRotation.orientations(
            previousTab: .portrait,
            targetTab: .allButUpsideDown,
            interface: .portrait,
            device: .landscapeRight
        )

        XCTAssertEqual(orientations, .landscapeRight)
    }

    func test_moreMenuLandscape_switchingBetweenAllOrientationTabs_keepsTheOrientation() {
        // The device is upright, but the reader's More menu rotated the interface to landscape.
        let orientations = TabSwitchRotation.orientations(
            previousTab: .allButUpsideDown,
            targetTab: .allButUpsideDown,
            interface: .landscapeLeft,
            device: .portrait
        )

        XCTAssertNil(orientations)
    }

    func test_targetWithoutTheCurrentOrientation_rotatesToTheTarget() {
        let orientations = TabSwitchRotation.orientations(
            previousTab: .allButUpsideDown,
            targetTab: .portrait,
            interface: .landscapeLeft,
            device: .landscapeRight
        )

        XCTAssertEqual(orientations, .portrait)
    }

    func test_interfaceMatchingTheDevice_staysPut() {
        let orientations = TabSwitchRotation.orientations(
            previousTab: .portrait,
            targetTab: .allButUpsideDown,
            interface: .portrait,
            device: .portrait
        )

        XCTAssertNil(orientations)
    }

    func test_unknownDeviceOrientation_staysPut() {
        let orientations = TabSwitchRotation.orientations(
            previousTab: .portrait,
            targetTab: .allButUpsideDown,
            interface: .portrait,
            device: nil
        )

        XCTAssertNil(orientations)
    }
}
