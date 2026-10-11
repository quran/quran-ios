import Foundation
import QuranTextKit
import XCTest
@testable import MoreMenuFeature

@MainActor
final class MoreMenuViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        originalValue = UserDefaults.standard.object(forKey: focusModeKey)
    }

    override func tearDown() async throws {
        if let originalValue {
            UserDefaults.standard.set(originalValue, forKey: focusModeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: focusModeKey)
        }
        try await super.tearDown()
    }

    func testFocusModeIsOffByDefault() {
        UserDefaults.standard.removeObject(forKey: focusModeKey)

        let sut = makeSUT()

        XCTAssertFalse(QuranContentStatePreferences.shared.focusModeEnabled)
        XCTAssertFalse(sut.focusModeEnabled)
    }

    func testFocusModeIsSeededFromPreference() {
        QuranContentStatePreferences.shared.focusModeEnabled = true

        let sut = makeSUT()

        XCTAssertTrue(sut.focusModeEnabled)
    }

    func testChangingFocusModeWritesPreference() {
        QuranContentStatePreferences.shared.focusModeEnabled = false
        let sut = makeSUT()

        sut.focusModeEnabled = true
        XCTAssertTrue(QuranContentStatePreferences.shared.focusModeEnabled)

        sut.focusModeEnabled = false
        XCTAssertFalse(QuranContentStatePreferences.shared.focusModeEnabled)
    }

    func testFocusModeControlIsShownByDefault() {
        XCTAssertEqual(MoreMenuControlsState().focusMode, .conditional)
    }

    // MARK: Private

    private let focusModeKey = "focusModeEnabled"
    private var originalValue: Any?

    private func makeSUT() -> MoreMenuViewModel {
        MoreMenuViewModel(model: MoreMenuModel(isWordPointerActive: false, state: MoreMenuControlsState()))
    }
}
