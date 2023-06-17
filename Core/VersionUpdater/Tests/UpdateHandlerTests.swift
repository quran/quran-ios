//
//  UpdateHandlerTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-17.
//

import SystemDependenciesFake
import XCTest
@testable import VersionUpdater

final class UpdateHandlerTests: XCTestCase {
    private var service: UpdateHandler!
    private let preferences = AppVersionPreferences.shared
    private var bundle: SystemBundleFake!

    private var worker1: VersionUpdaterTester!
    private var worker2: VersionUpdaterTester!
    private var nonBlockingWorker: VersionUpdaterTester!

    override func setUp() async throws {
        try await super.setUp()
        bundle = SystemBundleFake()
        service = UpdateHandler(bundle: bundle)

        worker1 = VersionUpdaterTester(blocksUI: true, uiTitle: "Worker 1")
        worker2 = VersionUpdaterTester(blocksUI: true, uiTitle: "Worker 2")
        nonBlockingWorker = VersionUpdaterTester(blocksUI: false, uiTitle: nil)

        service.register(updater: worker1, for: "1.16.0")
        service.register(updater: worker2, for: "1.17.0")
        service.register(updater: nonBlockingWorker, for: "1.18.0")

        bundle.info["CFBundleShortVersionString"] = "1.18.0"
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AppVersionPreferences.reset()
    }

    func test_futureNewInstallation() async {
        await verifyNoUpgrade()
    }

    func test_currentNewInstallation() async {
        bundle.info["CFBundleShortVersionString"] = "1.18.0"

        await verifyNoUpgrade()
    }

    func test_sameVersion() async {
        preferences.appVersion = "1.18.0"
        bundle.info["CFBundleShortVersionString"] = preferences.appVersion

        await verifyNoUpgrade()
    }

    func test_upgrade_noUpdater() async {
        preferences.appVersion = "1.18.0"
        bundle.info["CFBundleShortVersionString"] = "1.19.0"

        await verifyNoUpgrade()
    }

    func test_upgrade_runLastUpdater() async {
        preferences.appVersion = "1.17.0"

        let status = service.shouldUpgrade()
        XCTAssertEqual(status, .upgrade(blocksUI: false, titles: []))

        await service.upgrade()

        XCTAssertNil(worker1.update)
        XCTAssertNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    func test_upgrade_runLastTwoUpdaters() async {
        preferences.appVersion = "1.16.0"

        let status = service.shouldUpgrade()
        XCTAssertEqual(status, .upgrade(blocksUI: true, titles: ["Worker 2"]))

        await service.upgrade()

        XCTAssertNil(worker1.update)
        XCTAssertNotNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    func test_upgrade_runAllUpdaters() async {
        preferences.appVersion = "1.15.0"

        let status = service.shouldUpgrade()
        XCTAssertEqual(status, .upgrade(blocksUI: true, titles: ["Worker 1", "Worker 2"]))

        await service.upgrade()

        XCTAssertNotNil(worker1.update)
        XCTAssertNotNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    // MARK: - Helpers

    private func verifyNoUpgrade(file: StaticString = #filePath, line: UInt = #line) async {
        let status = service.shouldUpgrade()
        XCTAssertEqual(status, .noUpgrade)

        await service.upgrade()

        XCTAssertNil(worker1.update, file: file, line: line)
        XCTAssertNil(worker2.update, file: file, line: line)
        XCTAssertNil(nonBlockingWorker.update, file: file, line: line)
    }
}

private final class VersionUpdaterTester: VersionUpdater {
    let blocksUI: Bool
    let uiTitle: String?

    init(blocksUI: Bool, uiTitle: String?) {
        self.blocksUI = blocksUI
        self.uiTitle = uiTitle
    }

    var update: LaunchVersionUpdate?
    func execute(update: LaunchVersionUpdate) async {
        self.update = update
    }
}
