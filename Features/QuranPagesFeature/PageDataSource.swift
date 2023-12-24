//
//  PageDataSource.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranKit
import UIKit
import VLogging

@MainActor
public protocol PageDataSourceBuilder {
    func build(actions: PageDataSourceActions, pages: [Page]) -> PageDataSource
}

@MainActor
public protocol PageView: UIViewController {
    var page: Page { get }

    func word(at point: CGPoint) -> Word?
    func verse(at point: CGPoint) -> AyahNumber?
}

@MainActor
public struct PageDataSourceActions {
    // MARK: Lifecycle

    public init(visiblePagesUpdated: @Sendable @escaping () async -> Void) {
        self.visiblePagesUpdated = visiblePagesUpdated
    }

    // MARK: Public

    public let visiblePagesUpdated: @Sendable () async -> Void
}

@MainActor
public class PageDataSource {
    // MARK: Lifecycle

    public init(actions: PageDataSourceActions, viewBuilder: @escaping (Page) -> PageView) {
        self.actions = actions
        self.viewBuilder = viewBuilder
    }

    // MARK: Public

    public var items: [Page] = [] {
        didSet {
            updatePageControllerData()
        }
    }

    public var visiblePages: [Page] { pageController?.visibleIndices.map { items[$0] } ?? [] }

    public func usePageViewController(_ pageController: PageController) {
        self.pageController = pageController
        pageController.actions = PageController.Actions(
            viewControllerAtIndex: { [weak self] in self?.pageView(at: $0) ?? UIViewController() },
            indexOfViewController: { [weak self] in self?.indexOfViewController($0) },
            transitionCompleted: { [weak self] in
                logger.info("User manually scrolled UIPageViewController")
                guard let self else { return }
                Task {
                    await self.actions.visiblePagesUpdated()
                }
            },
            singlePageContainer: { [weak self] in
                guard let self else {
                    fatalError("singlePageContainer called with a nil self.")
                }
                return singlePageController(controller: $0, isLeftSide: $1)
            },
            twoPagesContainer: { TwoPagesController(first: $0, second: $1) }
        )
    }

    public func scrollToPage(_ page: Page, animated: Bool, forceReload: Bool) {
        // Don't scroll if page is visible
        if !forceReload, visiblePages.contains(page) {
            return
        }
        guard let scrollIndex = indexOfPage(page) else {
            logger.debug("scrolling to page \(page) not part of loaded pages")
            return
        }
        pageController?.scrollToPageAtIndex(scrollIndex, animated: animated, userInitiated: forceReload)
    }

    // MARK: - Word & Verse position

    public func word(at point: CGPoint, in view: UIView) -> Word? {
        convert(point, from: view)
            .flatMap { $0.word(at: $1) }
    }

    public func verse(at point: CGPoint, in view: UIView) -> AyahNumber? {
        convert(point, from: view)
            .flatMap { $0.verse(at: $1) }
    }

    // MARK: Private

    private let viewBuilder: (Page) -> PageView
    private let actions: PageDataSourceActions

    private var pageController: PageController? {
        didSet {
            updatePageControllerData()
        }
    }

    private var loadedViews: [PageView] {
        pageController?.loadedViews.compactMap { $0 as? PageView } ?? []
    }

    // MARK: - Page Controller

    private func updatePageControllerData() {
        pageController?.clearLoadedViewsCache()
        pageController?.numberOfPages = items.count
    }

    private func singlePageController(controller: UIViewController, isLeftSide: Bool) -> PagesContainer {
        guard let pageController else {
            fatalError("pageController is nil")
        }
        if pageController.navigationOrientation == .horizontal {
            return SinglePageController(controller: controller, isLeftSide: isLeftSide)
        } else {
            return VerticalPageController(controller: controller)
        }
    }

    // MARK: - Creating View

    private func indexOfViewController(_ viewController: UIViewController) -> Int? {
        guard let view = viewController as? PageView else {
            return nil
        }
        return indexOfPage(view.page)
    }

    private func pageView(at index: Int) -> PageView {
        let page = items[index]
        if let existing = loadedViews.first(where: { $0.page == page }) {
            return existing
        } else {
            let view = viewBuilder(page)
            view.view.backgroundColor = nil
            return view
        }
    }

    private func indexOfPage(_ page: Page) -> Int? {
        items.firstIndex(of: page)
    }

    private func convert(_ point: CGPoint, from view: UIView) -> (view: PageView, point: CGPoint)? {
        let controllers = pageController?.visibleControllers as? [PageView] ?? []
        let localPointsAndControllers = controllers.lazy.map { (view: $0, point: $0.view.convert(point, from: view)) }
        let convertedViewPoint = localPointsAndControllers.first { $0.view.view.point(inside: $0.point, with: nil) }
        return convertedViewPoint
    }
}
