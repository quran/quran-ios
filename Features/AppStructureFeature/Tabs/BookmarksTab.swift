//
//  BookmarksTab.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import BookmarksFeature
import CompletionsFeature
import Localization
import QuranViewFeature
import UIKit

struct BookmarksTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = BookmarksTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            bookmarksBuilder: BookmarksBuilder(container: container),
            completionsBuilder: CompletionsBuilder(container: container)
        )
        let viewController = BookmarksTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class BookmarksTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, bookmarksBuilder: BookmarksBuilder, completionsBuilder: CompletionsBuilder) {
        self.bookmarksBuilder = bookmarksBuilder
        self.completionsBuilder = completionsBuilder
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    override func start() {
        let bookmarksVC = bookmarksBuilder.build(withListener: self)
        let completionsVC = completionsBuilder.build(withListener: self)

        let segmentedController = BookmarksSegmentedViewController(
            bookmarksViewController: bookmarksVC,
            completionsViewController: completionsVC
        )
        presenter?.setViewControllers([segmentedController], animated: false)
    }

    // MARK: Private

    private let bookmarksBuilder: BookmarksBuilder
    private let completionsBuilder: CompletionsBuilder
}

private final class BookmarksSegmentedViewController: UIViewController {
    // MARK: Lifecycle

    init(bookmarksViewController: UIViewController, completionsViewController: UIViewController) {
        self.bookmarksViewController = bookmarksViewController
        self.completionsViewController = completionsViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.insertSegment(withTitle: lAndroid("menu_bookmarks"), at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Completions", at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        navigationItem.titleView = segmentedControl

        showChild(bookmarksViewController)
    }

    // MARK: Private

    private let segmentedControl = UISegmentedControl()
    private let bookmarksViewController: UIViewController
    private let completionsViewController: UIViewController
    private var currentChild: UIViewController?

    @objc
    private func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            transition(to: bookmarksViewController)
        case 1:
            transition(to: completionsViewController)
        default:
            break
        }
    }

    private func syncBarItems(from viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title ?? viewController.title
        navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
    }

    private func showChild(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        currentChild = viewController
        syncBarItems(from: viewController)
    }

    private func transition(to viewController: UIViewController) {
        guard viewController !== currentChild else { return }

        let from = currentChild
        currentChild = viewController
        syncBarItems(from: viewController)

        addChild(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let from {
            transition(from: from, to: viewController, duration: 0.25, options: .transitionCrossDissolve) {
                // nothing
            } completion: { _ in
                from.removeFromParent()
                viewController.didMove(toParent: self)
            }
        } else {
            view.addSubview(viewController.view)
            viewController.didMove(toParent: self)
        }
    }
}

private class BookmarksTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: lAndroid("menu_bookmarks"),
            image: .symbol("bookmark"),
            selectedImage: .symbol("bookmark.fill")
        )
    }
}
