#if QURAN_SYNC

import AuthenticationClientFake
import XCTest
@testable import AuthenticationClient

final class AuthenticationClientTests: XCTestCase {
    func testSafelyRestoreStateReturnsRestoredStateOnSuccess() async {
        let sut = AuthenticationClientFake()
        sut.restoreStateResult = .success(.authenticated)

        let state = await sut.safelyRestoreState()

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(sut.events, [.restoreState])
    }

    func testSafelyRestoreStateReturnsCurrentStateOnFailure() async {
        let sut = AuthenticationClientFake()
        sut.restoreStateResult = .failure(.clientIsNotAuthenticated(NSError(domain: "test", code: 1)))
        sut.authenticationStateValue = .authenticated

        let state = await sut.safelyRestoreState()

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(sut.events, [.restoreState, .readAuthenticationState])
    }
}

#endif
