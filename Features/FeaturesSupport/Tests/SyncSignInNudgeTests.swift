#if QURAN_SYNC
import AnalyticsFake
import AuthenticationClientFake
import Combine
import SystemDependenciesFake
import UIKit
import XCTest
@testable import FeaturesSupport

@MainActor
final class SyncSignInNudgeTests: XCTestCase {
    private let week: TimeInterval = 7 * 24 * 60 * 60
    private let authenticationClient = AuthenticationClientFake()
    private let analytics = AnalyticsLibrarySpy()
    private let time = SystemTimeFake()
    private let window = UIWindow()
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        SyncSignInNudgePreferences.shared.reset()
    }

    override func tearDown() {
        SyncSignInNudgePreferences.shared.reset()
        super.tearDown()
    }

    func test_toast_doesNotShowOnceSeenSignedIn() async {
        let sut = makeSUT()
        authenticationClient.authenticationStateValue = .authenticated
        let signedInToast = await sut.toast(after: .note)

        authenticationClient.authenticationStateValue = .notAuthenticated
        let signedOutToast = await sut.toast(after: .note)

        XCTAssertNil(signedInToast)
        XCTAssertNil(signedOutToast)
    }

    func test_secondToast_waitsSevenDaysAfterTheFirst() async {
        let sut = makeSUT()
        let first = await sut.toast(after: .note)

        time.now = time.now.addingTimeInterval(week - 1)
        let tooSoon = await sut.toast(after: .collection)
        time.now = time.now.addingTimeInterval(1)
        let second = await sut.toast(after: .collection)

        XCTAssertNotNil(first)
        XCTAssertNil(tooSoon)
        XCTAssertNotNil(second)
        XCTAssertEqual(analytics.events, [
            .init(name: "QuranSyncSignInNudgeShown", value: "note_saved_toast"),
            .init(name: "QuranSyncSignInNudgeShown", value: "collection_created_toast"),
        ])
    }

    func test_toast_showsAtMostTwice() async {
        let sut = makeSUT()
        for _ in 0 ..< 2 {
            let toast = await sut.toast(after: .note)
            XCTAssertNotNil(toast)
            time.now = time.now.addingTimeInterval(week)
        }

        time.now = time.now.addingTimeInterval(10 * week)
        let third = await sut.toast(after: .note)

        XCTAssertNil(third)
    }

    func test_signInTap_signsInFromTheToastAndStopsTheReminder() async throws {
        let sut = makeSUT()
        authenticationClient.authenticationStateAfterLogin = .authenticated
        let signedIn = expectation(description: "signed in")
        authenticationClient.authenticationStateChanges
            .sink { _ in signedIn.fulfill() }
            .store(in: &cancellables)
        let shown = await sut.toast(after: .note)
        let toast = try XCTUnwrap(shown)

        toast.action?.handler()
        await fulfillment(of: [signedIn], timeout: 5)
        authenticationClient.authenticationStateValue = .notAuthenticated
        time.now = time.now.addingTimeInterval(week)
        let next = await sut.toast(after: .note)

        XCTAssertNil(next)
        XCTAssertEqual(analytics.events.last, .init(name: "QuranSyncSignIn", value: "note_saved_toast"))
    }

    func test_signInTap_afterTheFirstScreenCloses_signsInFromTheScreenUnderIt() async throws {
        var closedScreen: UIViewController? = screenInWindow()
        let screenUnder = screenInWindow()
        let sut = SyncSignInNudge(
            authenticationClient: authenticationClient,
            analytics: analytics,
            time: time,
            signInViewControllers: { [weak closedScreen] in [closedScreen, screenUnder].compactMap { $0 } }
        )
        let signedIn = expectation(description: "signed in")
        authenticationClient.authenticationStateAfterLogin = .authenticated
        authenticationClient.authenticationStateChanges
            .sink { _ in signedIn.fulfill() }
            .store(in: &cancellables)
        let shown = await sut.toast(after: .note)
        let toast = try XCTUnwrap(shown)

        closedScreen = nil
        toast.action?.handler()
        await fulfillment(of: [signedIn], timeout: 5)

        XCTAssertTrue(authenticationClient.events.contains(.login))
        XCTAssertEqual(analytics.events.last, .init(name: "QuranSyncSignIn", value: "note_saved_toast"))
    }

    func test_userDismiss_stopsTheReminder() async throws {
        let sut = makeSUT()
        let shown = await sut.toast(after: .collection)
        let toast = try XCTUnwrap(shown)

        toast.onUserDismiss?()
        time.now = time.now.addingTimeInterval(week)
        let next = await sut.toast(after: .collection)

        XCTAssertNil(next)
        XCTAssertEqual(
            analytics.events.last,
            .init(name: "QuranSyncSignInNudgeDismissed", value: "collection_created_toast")
        )
    }

    // MARK: - Helpers

    private func makeSUT() -> SyncSignInNudge {
        let presenter = screenInWindow()
        return SyncSignInNudge(
            authenticationClient: authenticationClient,
            analytics: analytics,
            time: time,
            signInViewControllers: { [presenter] }
        )
    }

    private func screenInWindow() -> UIViewController {
        let viewController = UIViewController()
        window.addSubview(viewController.view)
        return viewController
    }
}
#endif
