//
//  AppMigratorTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-17.
//

import SystemDependenciesFake
import XCTest
@testable import AppMigrator

final class AppMigratorTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        bundle = SystemBundleFake()
        service = AppMigrator(bundle: bundle)

        worker1 = MigratorTester(blocksUI: true, uiTitle: "Worker 1")
        worker2 = MigratorTester(blocksUI: true, uiTitle: "Worker 2")
        nonBlockingWorker = MigratorTester(blocksUI: false, uiTitle: nil)

        service.register(migrator: worker1, for: "1.16.0")
        service.register(migrator: worker2, for: "1.17.0")
        service.register(migrator: nonBlockingWorker, for: "1.18.0")

        bundle.info["CFBundleShortVersionString"] = "1.18.0"
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AppVersionPreferences.reset()
    }

    func test_futureNewInstallation() async {
        await verifyNoMigration()
    }

    func test_currentNewInstallation() async {
        bundle.info["CFBundleShortVersionString"] = "1.18.0"

        await verifyNoMigration()
    }

    func test_sameVersion() async {
        preferences.appVersion = "1.18.0"
        bundle.info["CFBundleShortVersionString"] = preferences.appVersion

        await verifyNoMigration()
    }

    func test_upgrade_noUpdater() async {
        preferences.appVersion = "1.18.0"
        bundle.info["CFBundleShortVersionString"] = "1.19.0"

        await verifyNoMigration()
    }

    func test_upgrade_runLastUpdater() async {
        preferences.appVersion = "1.17.0"

        let status = service.migrationStatus()
        XCTAssertEqual(status, .migrate(blocksUI: false, titles: []))

        await service.migrate()

        XCTAssertNil(worker1.update)
        XCTAssertNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    func test_upgrade_runLastTwoUpdaters() async {
        preferences.appVersion = "1.16.0"

        let status = service.migrationStatus()
        XCTAssertEqual(status, .migrate(blocksUI: true, titles: ["Worker 2"]))

        await service.migrate()

        XCTAssertNil(worker1.update)
        XCTAssertNotNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    func test_upgrade_runAllUpdaters() async {
        preferences.appVersion = "1.15.0"

        let status = service.migrationStatus()
        XCTAssertEqual(status, .migrate(blocksUI: true, titles: ["Worker 1", "Worker 2"]))

        await service.migrate()

        XCTAssertNotNil(worker1.update)
        XCTAssertNotNil(worker2.update)
        XCTAssertNotNil(nonBlockingWorker.update)
    }

    // MARK: Private

    private var service: AppMigrator!
    private let preferences = AppVersionPreferences.shared
    private var bundle: SystemBundleFake!

    private var worker1: MigratorTester!
    private var worker2: MigratorTester!
    private var nonBlockingWorker: MigratorTester!

    // MARK: - Helpers

    private func verifyNoMigration(file: StaticString = #filePath, line: UInt = #line) async {
        let status = service.migrationStatus()
        XCTAssertEqual(status, .noMigration)

        await service.migrate()

        XCTAssertNil(worker1.update, file: file, line: line)
        XCTAssertNil(worker2.update, file: file, line: line)
        XCTAssertNil(nonBlockingWorker.update, file: file, line: line)
    }
}

private final class MigratorTester: Migrator {
    // MARK: Lifecycle

    init(blocksUI: Bool, uiTitle: String?) {
        self.blocksUI = blocksUI
        self.uiTitle = uiTitle
    }

    // MARK: Internal

    let blocksUI: Bool
    let uiTitle: String?

    var update: LaunchVersionUpdate?

    func execute(update: LaunchVersionUpdate) async {
        self.update = update
    }
}
