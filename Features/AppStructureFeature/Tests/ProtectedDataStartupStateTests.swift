import XCTest
@testable import AppStructureFeature

final class ProtectedDataStartupStateTests: XCTestCase {
    func testLaunchStartsImmediatelyWhenProtectedDataIsAvailable() {
        var sut = ProtectedDataStartupState()

        XCTAssertEqual(sut.launch(isProtectedDataAvailable: true), .start)
    }

    func testLaunchWaitsUntilProtectedDataBecomesAvailable() {
        var sut = ProtectedDataStartupState()

        XCTAssertEqual(sut.launch(isProtectedDataAvailable: false), .wait)
        XCTAssertEqual(sut.protectedDataDidBecomeAvailable(), .start)
    }

    func testDuplicateAvailabilityNotificationDoesNotStartTwice() {
        var sut = ProtectedDataStartupState()
        _ = sut.launch(isProtectedDataAvailable: false)
        _ = sut.protectedDataDidBecomeAvailable()

        XCTAssertEqual(sut.protectedDataDidBecomeAvailable(), .none)
    }
}
