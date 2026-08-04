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
        sut.restoreStateResult = .failure(.notAuthenticated(underlying: NSError(domain: "test", code: 1)))
        sut.authenticationStateValue = .authenticated

        let state = await sut.safelyRestoreState()

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(sut.events, [.restoreState, .readAuthenticationState])
    }

    func testAuthenticationClientErrorPreservesInspectableUnderlyingError() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let error = AuthenticationClientError.networkFailure(underlying: underlyingError)

        guard case let .networkFailure(inspectedError) = error else {
            return XCTFail("Expected networkFailure")
        }
        XCTAssertEqual(inspectedError as NSError, underlyingError)
        XCTAssertEqual(error.underlyingError as NSError?, underlyingError)
    }
}

#endif
