import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NavigationSearchTests: XCTestCase {
    // MARK: Internal

    func test_iPhoneAndIPad_searchWithANavigationBarSearchController() {
        let search = makeSearch(isiOSAppOnMac: false)
        let navigationItem = UINavigationItem()

        search.install(in: navigationItem, hidesSearchBarWhenScrolling: false)

        let searchController = navigationItem.searchController
        XCTAssertNotNil(searchController)
        XCTAssertIdentical(searchController?.searchBar, search.searchBar)
        XCTAssertEqual(searchController?.obscuresBackgroundDuringPresentation, false)
        XCTAssertEqual(searchController?.hidesNavigationBarDuringPresentation, true)
        XCTAssertFalse(navigationItem.hidesSearchBarWhenScrolling)
        XCTAssertNil(search.barButtonItem)
        assertConfigured(search.searchBar)
    }

    // Regression: activating a navigation bar search controller in an iOS app on a Mac throws
    // "Accessing the focus system through UIScreen is no longer supported."
    func test_iOSAppOnMac_searchesWithoutASearchController() {
        let search = makeSearch(isiOSAppOnMac: true)
        let viewController = UIViewController()
        search.install(in: viewController.navigationItem, hidesSearchBarWhenScrolling: false)
        viewController.navigationItem.rightBarButtonItem = search.barButtonItem

        XCTAssertNil(viewController.navigationItem.searchController)
        XCTAssertIdentical(search.barButtonItem?.customView, search.searchBar)
        assertConfigured(search.searchBar)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = UINavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        defer { window.isHidden = true }

        XCTAssertTrue(search.searchBar.isDescendant(of: window))
        XCTAssertTrue(search.searchBar.becomeFirstResponder())
        XCTAssertNil(viewController.presentedViewController)

        search.deactivate()
        XCTAssertFalse(search.searchBar.searchTextField.isFirstResponder)
    }

    func test_iOSAppOnMac_searchBarWidthFollowsDynamicTypeAndCanShrink() throws {
        guard #available(iOS 17.0, *) else { return }
        let search = makeSearch(isiOSAppOnMac: true)
        let width = try XCTUnwrap(search.searchBar.constraints.first { $0.firstAttribute == .width && $0.secondItem == nil })
        XCTAssertLessThan(width.priority, .required)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.preferredContentSizeCategory = .large
        window.addSubview(search.searchBar)
        window.isHidden = false
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        let defaultWidth = width.constant

        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        window.layoutIfNeeded()

        XCTAssertGreaterThan(width.constant, defaultWidth)
    }

    // MARK: Private

    private let delegate = SearchBarDelegate()

    private func makeSearch(isiOSAppOnMac: Bool) -> NavigationSearch {
        NavigationSearch(
            placeholder: "Search",
            delegate: delegate,
            hidesNavigationBarDuringPresentation: true,
            isiOSAppOnMac: isiOSAppOnMac
        )
    }

    private func assertConfigured(_ searchBar: UISearchBar, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(searchBar.placeholder, "Search", file: file, line: line)
        XCTAssertIdentical(searchBar.delegate, delegate, file: file, line: line)
    }
}

private final class SearchBarDelegate: NSObject, UISearchBarDelegate {
}
