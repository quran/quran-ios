//
//  NavigationDrawerBuilder.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import QuranAnnotations
import QuranKit
import UIKit

/// Public entry point for callers that want to present the navigation drawer.
/// Mirrors the Builder pattern used by other features (NoteEditorBuilder, etc.).
@MainActor
public struct NavigationDrawerBuilder {
    public init() {}

    /// Builds the drawer view controller, ready to be presented modally.
    ///
    /// - Parameters:
    ///   - quran: The Quran model used to populate Surah and Juz lists.
    ///   - currentPage: The page currently visible in the reader, used to
    ///     highlight the matching Surah/Juz row.
    ///   - notes: A snapshot of the user's notes to render in the Notes tab.
    ///   - pageBookmarks: A snapshot of the user's page bookmarks for the
    ///     Bookmarks tab.
    ///   - onSelectPage: Called when the user taps a destination. The caller
    ///     should dismiss the drawer and scroll the reader to the page.
    public func build(
        quran: Quran,
        currentPage: Page,
        notes: [Note],
        pageBookmarks: [PageBookmark],
        onSelectPage: @escaping (Page) -> Void
    ) -> UIViewController {
        let controllerHolder = ViewControllerHolder()
        let viewModel = NavigationDrawerViewModel(
            quran: quran,
            currentPage: currentPage,
            notes: notes,
            pageBookmarks: pageBookmarks,
            onSelectPage: { page in
                controllerHolder.controller?.dismiss(animated: true) {
                    onSelectPage(page)
                }
            },
            onClose: { controllerHolder.controller?.dismiss(animated: true) }
        )
        let controller = NavigationDrawerViewController(viewModel: viewModel)
        controllerHolder.controller = controller
        return controller
    }
}

/// Indirection so the view-model's callbacks can dismiss the controller without
/// retain cycles.
@MainActor
private final class ViewControllerHolder {
    weak var controller: UIViewController?
}
