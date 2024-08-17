//
//  PageViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-12-23.
//

// Most of the code is copied from https://github.com/benjaminsage/iPages

import SwiftUI
import UIKit
import UIx
import VLogging

public struct PageViewController<Element, Content>: View
    where Element: Identifiable,
    Element: Equatable,
    Content: View
{
    // MARK: Lifecycle

    public init(
        transitionStyle: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        interPageSpacing: CGFloat,
        animated: Bool,
        selection: Binding<Element>,
        @ViewBuilder forEach: () -> ForEach<[Element], Element.ID, Content>
    ) {
        self.transitionStyle = transitionStyle
        self.navigationOrientation = navigationOrientation
        self.interPageSpacing = interPageSpacing
        self.animated = animated
        _selection = selection
        self.forEach = forEach()
    }

    // MARK: Public

    public var body: some View {
        _PageViewController<Element, Content>(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            interPageSpacing: interPageSpacing,
            animated: animated,
            forEach: forEach,
            selection: $selection
        )
    }

    // MARK: Internal

    let transitionStyle: UIPageViewController.TransitionStyle
    let navigationOrientation: UIPageViewController.NavigationOrientation
    let interPageSpacing: CGFloat
    let animated: Bool

    @Binding var selection: Element
    let forEach: ForEach<[Element], Element.ID, Content>
}

private struct _PageViewController<Element, Content>: UIViewControllerRepresentable
    where
    Element: Identifiable,
    Element: Equatable,
    Content: View
{
    let transitionStyle: UIPageViewController.TransitionStyle
    let navigationOrientation: UIPageViewController.NavigationOrientation
    let interPageSpacing: CGFloat
    let animated: Bool

    let forEach: ForEach<[Element], Element.ID, Content>
    @Binding var selection: Element

    @State var userDraggingStartedTransitionInProgress = false

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let options: [UIPageViewController.OptionsKey: Any] = [
            .interPageSpacing: interPageSpacing,
        ]
        let pageViewController = UIPageViewController(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            options: options
        )

        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        pageViewController.view.backgroundColor = .clear

        for view in pageViewController.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = context.coordinator
                break
            }
        }

        // Trigger an update.
        updateUIViewController(pageViewController, context: context)

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // Early return if showing selection's view controller.
        if let visibleController = pageViewController.viewControllers?.first as? PageContentController {
            if visibleController.element == selection {
                return
            }
        }

        if userDraggingStartedTransitionInProgress {
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

        let previousSelection = context.coordinator.parent.selection
        context.coordinator.parent = self

        let viewController = makeController(selection)

        let previousIndex = forEach.data.firstIndex { $0 == previousSelection }
        let currentIndex = forEach.data.firstIndex { $0 == selection }
        let direction: UIPageViewController.NavigationDirection = if let previousIndex, let currentIndex {
            currentIndex < previousIndex ? .forward : .reverse
        } else {
            .forward
        }

        pageViewController.setViewControllers([viewController], direction: direction, animated: animated)
    }

    func makeController(_ element: Element) -> UIViewController {
        let view = forEach.content(element)
        return PageContentController(rootView: view, element: element)
    }
}

// MARK: - Coordinator

extension _PageViewController {
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
        // MARK: Lifecycle

        init(_ pageViewController: _PageViewController) {
            parent = pageViewController
        }

        // MARK: Internal

        var parent: _PageViewController

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let contentController = viewController as? PageContentController else {
                return nil
            }

            guard let index = parent.forEach.data.firstIndex(of: contentController.element) else {
                return nil
            }

            let newIndex = index - 1
            if newIndex < 0 {
                return nil
            }
            let element = parent.forEach.data[newIndex]
            return parent.makeController(element)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let contentController = viewController as? PageContentController else {
                return nil
            }

            guard let index = parent.forEach.data.firstIndex(of: contentController.element) else {
                return nil
            }

            let newIndex = index + 1

            if newIndex >= parent.forEach.data.count {
                return nil
            }
            let element = parent.forEach.data[newIndex]
            return parent.makeController(element)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let contentController = visibleViewController as? PageContentController
            {
                parent.selection = contentController.element
            }
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView.isTracking || scrollView.isDecelerating {
                parent.userDraggingStartedTransitionInProgress = true
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            parent.userDraggingStartedTransitionInProgress = false
        }
    }
}

extension _PageViewController {
    private class PageContentController: UIHostingController<Content> {
        // MARK: Lifecycle

        init(rootView: Content, element: Element) {
            self.element = element
            super.init(rootView: rootView)
            view.backgroundColor = .clear
            _disableSafeArea = true
        }

        @available(*, unavailable)
        @objc
        dynamic required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        let element: Element

        var description1: String {
            "<PageContentController: \(ObjectIdentifier(self))>"
        }
    }
}

struct PaginationView_Previews: PreviewProvider {
    struct PaginationViewPreview: View {
        struct Page: Identifiable, Equatable { let id: Int }

        // MARK: Internal

        let pages = (0 ..< 604).map(Page.init)
        @State var currentPage = Page(id: 45)

        var body: some View {
            PageViewController(
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                interPageSpacing: 10,
                animated: true,
                selection: $currentPage
            ) {
                ForEach(pages) { page in
                    VStack {
                        Text("Top")
                        Spacer()
                        Text("Page: \(page.id)")
                        Spacer()
                        Text("Top")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(page.id % 2 == 0 ? Color.red : Color.green)
                }
            }
            .ignoresSafeArea()
            .background(Color.blue)
            .border(Color.purple)
        }
    }

    // MARK: Internal

    static var previews: some View {
        PaginationViewPreview()
    }
}
