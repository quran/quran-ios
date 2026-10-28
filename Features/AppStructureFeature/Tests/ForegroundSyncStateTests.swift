#if QURAN_SYNC
import XCTest
@testable import AppStructureFeature

final class ForegroundSyncStateTests: XCTestCase {
    func testLaunchForegroundDoesNotSync() {
        var sut = ForegroundSyncState()

        XCTAssertFalse(sut.willEnterForeground())
    }

    func testReturningFromTheBackgroundSyncs() {
        var sut = ForegroundSyncState()

        sut.didEnterBackground()

        XCTAssertTrue(sut.willEnterForeground())
    }

    func testEachReturnSyncsOnce() {
        var sut = ForegroundSyncState()
        sut.didEnterBackground()
        _ = sut.willEnterForeground()

        XCTAssertFalse(sut.willEnterForeground())

        sut.didEnterBackground()
        XCTAssertTrue(sut.willEnterForeground())
    }
}
#endif
