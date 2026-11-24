import SwiftUI
import UIKit
import XCTest
@testable import UIx

@MainActor
final class WindowSafeAreaInsetsReaderTests: XCTestCase {
    func test_verticalBarContentChangeReadsWindowSafeAreaWithoutLayoutPass() async {
        let insets = InsetsBox()
        let controller = UIHostingController(rootView: ReaderView(insets: insets, content: VerticalBarContent()))
        let window = SafeAreaWindow(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        defer { window.isHidden = true }
        window.fakeSafeAreaInsets.top = 20
        window.rootViewController = controller
        window.makeKeyAndVisible()
        await waitForInsets(insets) { $0.top == 20 }

        // Like the unfolded iPhone Duo's status column: the window's safe area moves without a layout pass.
        window.fakeSafeAreaInsets.left = 84
        controller.rootView = ReaderView(insets: insets, content: VerticalBarContent(statusBarHidden: true))

        await waitForInsets(insets) { $0.leading == 84 }
        XCTAssertEqual(insets.value, EdgeInsets(top: 20, leading: 84, bottom: 0, trailing: 0))
    }

    private func waitForInsets(_ insets: InsetsBox, until condition: @escaping (EdgeInsets) -> Bool) async {
        let matched = expectation(description: "Reader's insets match")
        matched.assertForOverFulfill = false
        insets.onChange = { if condition($0) { matched.fulfill() } }
        await fulfillment(of: [matched], timeout: 1)
        insets.onChange = nil
    }
}

private final class SafeAreaWindow: UIWindow {
    var fakeSafeAreaInsets = UIEdgeInsets.zero

    override var safeAreaInsets: UIEdgeInsets { fakeSafeAreaInsets }
}

@MainActor
private final class InsetsBox {
    var value = EdgeInsets()
    var onChange: ((EdgeInsets) -> Void)?

    var binding: Binding<EdgeInsets> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                self.onChange?(newValue)
            }
        )
    }
}

private struct ReaderView: View {
    let insets: InsetsBox
    let content: VerticalBarContent

    var body: some View {
        Color.clear
            .readWindowSafeAreaInsets(insets.binding)
            .environment(\.verticalBarContent, content)
    }
}
