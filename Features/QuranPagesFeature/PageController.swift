//
//  PageController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-09-04.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import UIKit
import VLogging
import WeakSet

@MainActor
public class PageController {
    struct Actions {
        let viewControllerAtIndex: @MainActor (Int) -> UIViewController
        let indexOfViewController: @MainActor (UIViewController) -> Int?
        let transitionCompleted: @MainActor () -> Void
        let singlePageContainer: @MainActor (UIViewController, Bool) -> PagesContainer
        let twoPagesContainer: @MainActor (UIViewController, UIViewController) -> PagesContainer
    }

    // MARK: Lifecycle

    public init(
        transitionStyle: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        interPageSpacing: CGFloat
    ) {
        self.navigationOrientation = navigationOrientation
        underlying = UIPageViewController(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            options: [.interPageSpacing: interPageSpacing]
        )
        handler = PageControllerDelegateHandler(controller: self)

        underlying.delegate = handler
        underlying.dataSource = handler
        for subview in underlying.view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.delegate = handler
            }
        }
    }

    // MARK: Public

    public enum PagingStrategy {
        case singlePage
        case twoPages
    }

    public var pagingStrategy: PagingStrategy = .singlePage {
        didSet {
            if oldValue == pagingStrategy {
                return
            }
            clearLoadedViewsCache()
            if let firstVisibleIndex = visibleIndices.first {
                scrollToPageAtIndex(firstVisibleIndex, animated: false, userInitiated: true)
            }
        }
    }

    public var viewController: UIViewController { underlying }

    // MARK: Internal

    var navigationOrientation: UIPageViewController.NavigationOrientation

    var actions: Actions?
    var numberOfPages: Int = 0

    var visibleControllers: [UIViewController] { usersViewControllers(underlying.viewControllers ?? []) }
    var visibleIndices: [Int] { visibleControllers.compactMap { actions?.indexOfViewController($0) } }
    var loadedViews: [UIViewController] { usersViewControllers(handler.map { Array($0.loadedViews) } ?? []) }

    func clearLoadedViewsCache() {
        handler?.loadedViews.removeAllObjects()
    }

    func scrollToPageAtIndex(_ scrollIndex: Int, animated: Bool, userInitiated: Bool) {
        let forward = visibleIndices.allSatisfy { $0 > scrollIndex }
        setViewControllers(
            [viewControllerAtIndex(scrollIndex)],
            direction: forward ? .forward : .reverse,
            animated: animated,
            userInitiated: userInitiated
        )
    }

    func viewControllerAfter(_ viewController: UIViewController) -> UIViewController? {
        guard let userViewController = usersViewControllers([viewController]).last else {
            return nil
        }
        guard let previousIndex = actions?.indexOfViewController(userViewController) else {
            return nil
        }
        let newIndex = previousIndex + 1
        if newIndex >= numberOfPages {
            return nil
        }
        return viewControllerAtIndex(newIndex)
    }

    func viewControllerBefore(_ viewController: UIViewController) -> UIViewController? {
        guard let userViewController = usersViewControllers([viewController]).first else {
            return nil
        }
        guard let previousIndex = actions?.indexOfViewController(userViewController) else {
            return nil
        }
        let newIndex = previousIndex - 1
        if newIndex < 0 {
            return nil
        }
        return viewControllerAtIndex(newIndex)
    }

    // MARK: Private

    private let underlying: UIPageViewController
    private var handler: PageControllerDelegateHandler?

    private func setViewControllers(
        _ viewControllers: [UIViewController],
        direction: UIPageViewController.NavigationDirection,
        animated: Bool,
        userInitiated: Bool
    ) {
        if !userInitiated && (handler?.userDraggingStartedTransitionInProgress ?? false) {
            logger.info("Cannot change page while user dragging in progress")

            // when user dragging initiated transition is still in progress,
            // prevent the app from starting simultaneous transitions to avoid assertion failure and crash
            // reference: https://github.com/hons82/THSegmentedPager/blob/master/THSegmentedPager/THSegmentedPager.m#L233

            // failure type 1: Assertion failure in
            // -[UIPageViewController queuingScrollView:didEndManualScroll:toRevealView:direction:animated:didFinish:didComplete:],
            // /SourceCache/UIKit_Sim/UIKit-2935.137/UIPageViewController.m:1866
            // Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'No view controller managing visible view

            // failure type 2: Assertion failure in -[_UIQueuingScrollView _enqueueCompletionState:],
            // /SourceCache/UIKit_Sim/UIKit-2935.137/_UIQueuingScrollView.m:499
            // Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Duplicate states in queue'
            return
        }

        viewControllers.forEach { handler?.loadedViews.insert($0) }
        underlying.setViewControllers(viewControllers, direction: direction, animated: animated)
    }

    private func viewControllerAtIndex(_ index: Int) -> PagesContainer {
        guard let actions else {
            fatalError("viewControllerAtIndex is called with no configured actions")
        }
        switch pagingStrategy {
        case .singlePage:
            return actions.singlePageContainer(actions.viewControllerAtIndex(index), index % 2 == 0)
        case .twoPages:
            let otherIndex = index % 2 == 0 ? index + 1 : index - 1
            let indices = [index, otherIndex].sorted()
            return actions.twoPagesContainer(
                actions.viewControllerAtIndex(indices[0]),
                actions.viewControllerAtIndex(indices[1])
            )
        }
    }

    private func usersViewControllers(_ viewControllers: [UIViewController]) -> [UIViewController] {
        viewControllers.flatMap { viewController -> [UIViewController] in
            if let container = viewController as? PagesContainer {
                return container.pages
            } else {
                fatalError("ViewController \(viewController) is not a PagesContainer")
            }
        }
    }
}

private class PageControllerDelegateHandler: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    // MARK: Lifecycle

    init(controller: PageController) {
        self.controller = controller
    }

    // MARK: Internal

    var userDraggingStartedTransitionInProgress = false

    // we need to keep track of loaded views
    // because page controller could caches views
    // but doesn't expose them and we need them for reloading
    let loadedViews = UnsafeWeakSet<UIViewController>()

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let viewController = controller?.viewControllerBefore(viewController)
        if let viewController {
            loadedViews.insert(viewController)
        }
        return viewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let viewController = controller?.viewControllerAfter(viewController)
        if let viewController {
            loadedViews.insert(viewController)
        }
        return viewController
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            controller?.actions?.transitionCompleted()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDecelerating {
            userDraggingStartedTransitionInProgress = true
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        userDraggingStartedTransitionInProgress = false
    }

    // MARK: Private

    private weak var controller: PageController?
}
