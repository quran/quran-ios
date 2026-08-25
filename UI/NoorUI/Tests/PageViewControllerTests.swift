import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class PageViewControllerTests: XCTestCase {
    func test_notifiesWhenInitialAndProgrammaticPagesBecomeVisible() {
        let pages = [Page(id: 1), Page(id: 2)]
        let model = PageSelectionModel(selection: pages[0])
        let initialPageVisible = expectation(description: "Initial page visible")
        let changedPageVisible = expectation(description: "Changed page visible")
        var callbackCount = 0
        let view = PageViewControllerTestView(model: model, pages: pages) {
            callbackCount += 1
            if callbackCount == 1 {
                initialPageVisible.fulfill()
            } else if callbackCount == 2 {
                changedPageVisible.fulfill()
            }
        }
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        wait(for: [initialPageVisible], timeout: 1)

        model.selection = pages[1]
        window.layoutIfNeeded()

        wait(for: [changedPageVisible], timeout: 1)
        window.isHidden = true
    }
}

private struct PageViewControllerTestView: View {
    @ObservedObject var model: PageSelectionModel
    let pages: [Page]
    let onVisiblePageChanged: () -> Void

    var body: some View {
        PageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            interPageSpacing: 0,
            animated: false,
            selection: $model.selection,
            onVisiblePageChanged: onVisiblePageChanged
        ) {
            ForEach(pages) { page in
                Text("Page \(page.id)")
            }
        }
    }
}

private final class PageSelectionModel: ObservableObject {
    init(selection: Page) {
        self.selection = selection
    }

    @Published var selection: Page
}

private struct Page: Identifiable, Equatable {
    let id: Int
}
