//
//  SystemBundleVersionAndBuildTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-16.
//

import SystemDependenciesFake
import XCTest
@testable import SettingsFeature

final class SystemBundleVersionAndBuildTests: XCTestCase {
    // MARK: Internal

    func test_versionAndBuild_showsTheBuildAfterTheVersion() {
        bundle.info["CFBundleShortVersionString"] = "2.4.0"
        bundle.info["CFBundleVersion"] = "310"

        XCTAssertEqual(bundle.versionAndBuild, "2.4.0 (310)")
    }

    func test_versionAndBuild_isTheVersionAloneWithoutABuild() {
        bundle.info["CFBundleShortVersionString"] = "2.4.0"

        XCTAssertEqual(bundle.versionAndBuild, "2.4.0")
    }

    func test_versionAndBuild_isNilWithoutAVersion() {
        bundle.info["CFBundleVersion"] = "310"

        XCTAssertNil(bundle.versionAndBuild)
    }

    // MARK: Private

    private let bundle = SystemBundleFake()
}
