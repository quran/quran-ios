//
//  PageViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-12-23.
//

// Most of the code is copied from https://github.com/benjaminsage/iPages

import Crashing
import SwiftUI
import UIKit
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

        // Trigger an update.
        updateUIViewController(pageViewController, context: context)

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        let visibleElement = (pageViewController.viewControllers?.first as? PageContentController)?.element
        context.coordinator.parent = self

        // Early return if showing selection's view controller.
        if visibleElement == selection {
            return
        }

        if !context.coordinator.transitionState.shouldApply(selection) {
            context.coordinator.recordPager(
                generation: context.coordinator.transitionGeneration,
                phase: "manual_transition",
                source: "external_selection_deferred",
                visibleElement: visibleElement,
                targetElement: selection,
                pendingElement: selection,
                gestureState: "dragging"
            )
            logger.info("Cannot change page while user dragging in progress")
            return
        }

        let viewController = makeController(selection)

        let previousIndex = visibleElement.flatMap { visibleElement in
            forEach.data.firstIndex { $0 == visibleElement }
        }
        let currentIndex = forEach.data.firstIndex { $0 == selection }
        let direction: UIPageViewController.NavigationDirection = if let previousIndex, let currentIndex {
            currentIndex < previousIndex ? .forward : .reverse
        } else {
            .forward
        }

        let transitionSource = visibleElement == nil ? "initial" : "external_selection"
        let transitionGeneration = context.coordinator.beginPagerTransition(
            phase: "programmatic_transition",
            source: transitionSource,
            visibleElement: visibleElement,
            targetElement: selection,
            pendingElement: nil,
            gestureState: "none"
        )
        logger.info("Pager programmatic transition started")
        pageViewController.setViewControllers(
            [viewController],
            direction: direction,
            animated: animated
        ) { [weak coordinator = context.coordinator] completed in
            coordinator?.finishProgrammaticTransition(
                generation: transitionGeneration,
                phase: completed ? "idle" : "programmatic_incomplete",
                source: transitionSource,
                visibleElement: selection,
                targetElement: selection,
                pendingElement: nil,
                gestureState: "none"
            )
            logger.info("Pager programmatic transition completed: \(completed)")
        }
    }

    func makeController(_ element: Element) -> UIViewController {
        let view = forEach.content(element)
        return PageContentController(rootView: view, element: element)
    }
}

// MARK: - Coordinator

extension _PageViewController {
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        // MARK: Lifecycle

        init(_ pageViewController: _PageViewController) {
            parent = pageViewController
        }

        // MARK: Internal

        var parent: _PageViewController
        var transitionState = PageTransitionState<Element>()
        private(set) var transitionGeneration = 0

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
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            transitionState.userTransitionWillBegin()
            transitionGeneration += 1
            let visibleElement = (pageViewController.viewControllers?.first as? PageContentController)?.element
            let pendingElement = (pendingViewControllers.first as? PageContentController)?.element
            recordPager(
                generation: transitionGeneration,
                phase: "manual_transition",
                source: "user_gesture",
                visibleElement: visibleElement,
                targetElement: pendingElement,
                pendingElement: pendingElement,
                gestureState: "dragging"
            )
            logger.info("Pager manual transition started")
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            let visibleElement = (pageViewController.viewControllers?.first as? PageContentController)?.element
            let pendingSelection = transitionState.userTransitionDidFinish(visibleElement: visibleElement)

            if let visibleElement {
                parent.selection = visibleElement
            }

            if let pendingSelection {
                Task { @MainActor [weak self] in
                    await Task.yield()
                    self?.parent.selection = pendingSelection
                }
            }

            recordPager(
                generation: transitionGeneration,
                phase: completed ? "idle" : "manual_cancelled",
                source: "user_gesture",
                visibleElement: visibleElement,
                targetElement: visibleElement,
                pendingElement: pendingSelection,
                gestureState: "none"
            )
            logger.info("Pager manual transition finished: \(completed)")
        }

        func beginPagerTransition(
            phase: String,
            source: String,
            visibleElement: Element?,
            targetElement: Element?,
            pendingElement: Element?,
            gestureState: String
        ) -> Int {
            transitionGeneration += 1
            recordPager(
                generation: transitionGeneration,
                phase: phase,
                source: source,
                visibleElement: visibleElement,
                targetElement: targetElement,
                pendingElement: pendingElement,
                gestureState: gestureState
            )
            return transitionGeneration
        }

        func finishProgrammaticTransition(
            generation: Int,
            phase: String,
            source: String,
            visibleElement: Element?,
            targetElement: Element?,
            pendingElement: Element?,
            gestureState: String
        ) {
            guard generation == transitionGeneration else {
                logger.info("Ignoring stale pager completion: \(generation), current: \(transitionGeneration)")
                return
            }
            recordPager(
                generation: generation,
                phase: phase,
                source: source,
                visibleElement: visibleElement,
                targetElement: targetElement,
                pendingElement: pendingElement,
                gestureState: gestureState
            )
        }

        func recordPager(
            generation: Int,
            phase: String,
            source: String,
            visibleElement: Element?,
            targetElement: Element?,
            pendingElement: Element?,
            gestureState: String
        ) {
            crashContext.setPager(
                generation: generation,
                phase: phase,
                source: source,
                visibleItem: indexDescription(for: visibleElement),
                targetItem: indexDescription(for: targetElement),
                pendingItem: indexDescription(for: pendingElement),
                gestureState: gestureState
            )
        }

        private func indexDescription(for element: Element?) -> String {
            guard let element,
                  let index = parent.forEach.data.firstIndex(of: element)
            else {
                return "none"
            }
            return String(index)
        }
    }
}

struct PageTransitionState<Element: Equatable> {
    // MARK: Internal

    private(set) var isUserTransitionInProgress = false

    mutating func userTransitionWillBegin() {
        isUserTransitionInProgress = true
        pendingSelection = nil
    }

    mutating func shouldApply(_ selection: Element) -> Bool {
        guard isUserTransitionInProgress else {
            return true
        }

        pendingSelection = selection
        return false
    }

    mutating func userTransitionDidFinish(visibleElement: Element?) -> Element? {
        isUserTransitionInProgress = false
        defer { pendingSelection = nil }

        guard pendingSelection != visibleElement else {
            return nil
        }
        return pendingSelection
    }

    // MARK: Private

    private var pendingSelection: Element?
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
