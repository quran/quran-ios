import XCTest
@testable import AppStructureFeature

final class StoreOpenStartupStateTests: XCTestCase {
    func testOpenedStoresContinueLaunch() {
        var sut = StoreOpenStartupState()

        XCTAssertEqual(sut.storesOpened(), .continueLaunch)
        XCTAssertFalse(sut.isWaitingForStorage)
    }

    func testFirstStorageFullShowsTheScreenAndWaits() {
        var sut = StoreOpenStartupState()

        XCTAssertEqual(sut.storageFull(), .showStorageFull)
        XCTAssertTrue(sut.isWaitingForStorage)
    }

    func testRepeatedStorageFullKeepsWaitingWithoutShowingAgain() {
        var sut = StoreOpenStartupState()
        _ = sut.storageFull()

        XCTAssertEqual(sut.storageFull(), .keepWaiting)
        XCTAssertEqual(sut.storageFull(), .keepWaiting)
        XCTAssertTrue(sut.isWaitingForStorage)
    }

    func testOpeningAfterStorageFullContinuesLaunchOnce() {
        var sut = StoreOpenStartupState()
        _ = sut.storageFull()

        XCTAssertEqual(sut.storesOpened(), .continueLaunch)
        XCTAssertFalse(sut.isWaitingForStorage)
        XCTAssertEqual(sut.storesOpened(), .none)
    }

    func testStorageFullAfterOpeningIsIgnored() {
        var sut = StoreOpenStartupState()
        _ = sut.storesOpened()

        XCTAssertEqual(sut.storageFull(), .none)
        XCTAssertFalse(sut.isWaitingForStorage)
    }
}
