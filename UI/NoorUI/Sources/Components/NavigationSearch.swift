//
//  NavigationSearch.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import UIKit

/// The search field of a screen's navigation bar.
///
/// iPhone and iPad get a `UISearchController` in the navigation item. An iOS app running on a Mac
/// gets a plain search bar in a bar button item instead. There, activating a navigation bar search
/// controller lays out its presentation with `+[UINavigationBar defaultSizeForOrientation:]`, which
/// reads the main scene bounds through `UIScreen`. For a single-scene app built with a recent SDK
/// (the iOS 27 SDK on macOS 27), UIKit on the Mac throws "Accessing the focus system through UIScreen
/// is no longer supported." A plain search bar has no presentation, so it never takes that path.
@MainActor
public final class NavigationSearch {
    // MARK: Lifecycle

    public convenience init(placeholder: String, delegate: UISearchBarDelegate, hidesNavigationBarDuringPresentation: Bool) {
        self.init(
            placeholder: placeholder,
            delegate: delegate,
            hidesNavigationBarDuringPresentation: hidesNavigationBarDuringPresentation,
            isiOSAppOnMac: ProcessInfo.processInfo.isiOSAppOnMac
        )
    }

    init(placeholder: String, delegate: UISearchBarDelegate, hidesNavigationBarDuringPresentation: Bool, isiOSAppOnMac: Bool) {
        if isiOSAppOnMac {
            searchController = nil
            searchBar = UISearchBar()
            searchBar.searchBarStyle = .minimal
            searchBar.widthAnchor.constraint(equalToConstant: UIFontMetrics.default.scaledValue(for: Self.macSearchBarWidth)).isActive = true
            barButtonItem = UIBarButtonItem(customView: searchBar)
        } else {
            let searchController = UISearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarDuringPresentation
            self.searchController = searchController
            searchBar = searchController.searchBar
            barButtonItem = nil
        }
        searchBar.placeholder = placeholder
        searchBar.delegate = delegate
    }

    // MARK: Public

    public let searchBar: UISearchBar

    /// Shows the search bar when there is no search controller. Place it with the navigation item's trailing items.
    public let barButtonItem: UIBarButtonItem?

    /// Adds the search controller, if any, to the navigation item.
    public func install(in navigationItem: UINavigationItem, hidesSearchBarWhenScrolling: Bool) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
    }

    public func deactivate() {
        if let searchController {
            searchController.isActive = false
        } else {
            searchBar.endEditing(true)
        }
    }

    // MARK: Internal

    let searchController: UISearchController?

    // MARK: Private

    private static let macSearchBarWidth: CGFloat = 220
}
