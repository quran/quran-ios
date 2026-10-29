#if QURAN_SYNC
import MobileSyncTestSupport
import UIKit
import XCTest
@testable import AppStructureFeature

@MainActor
final class ForegroundSyncTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        notificationCenter = NotificationCenter()
        sut = ForegroundSync(quranDataService: database.quranDataService, notificationCenter: notificationCenter)
    }

    override func tearDown() async throws {
        sut = nil
        notificationCenter = nil
        try await database.reset()
        try await super.tearDown()
    }

    func testLaunchForegroundDoesNotSync() {
        XCTAssertFalse(sut.willEnterForeground())
    }

    func testReturningFromTheBackgroundSyncs() {
        sut.didEnterBackground()

        XCTAssertTrue(sut.willEnterForeground())
    }

    func testEachReturnSyncsOnce() {
        sut.didEnterBackground()
        sut.willEnterForeground()

        XCTAssertFalse(sut.willEnterForeground())

        sut.didEnterBackground()
        XCTAssertTrue(sut.willEnterForeground())
    }

    func testEnteringTheBackgroundIsObserved() {
        sut.start()

        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        XCTAssertTrue(sut.willEnterForeground())
    }

    func testReturningToTheForegroundIsObserved() {
        sut.start()
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertFalse(sut.willEnterForeground())
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared
    private var notificationCenter: NotificationCenter!
    private var sut: ForegroundSync!
}
#endif
