//
//  ContentViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import NoorUI
import QuranKit
import QuranPagesFeature
import QuranTextKit
import UIKit
import UIx

final class ContentViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: Lifecycle

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Internal

    var isLandscape: Bool { view.bounds.width > view.bounds.height }
    var pagingStrategy: PageController.PagingStrategy = .singlePage {
        didSet {
            pageController?.pagingStrategy = pagingStrategy
        }
    }

    // MARK: - View hierarchy

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .reading
        setUpGesture()
        setUpPagingStrategyChanges()
        setUpDataSourceChanges()
        setUpBackgroundListener()
        setUpQuranUITraitsListener()
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    @objc
    func onViewPanned(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            viewModel.userWillBeginDragScroll()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            updatePagingStrategy()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePagingStrategy()
    }

    // MARK: Private

    private var pageController: PageController?
    private let viewModel: ContentViewModel
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Scrolling

    private func setUpQuranUITraitsListener() {
        viewModel.$quranUITraits
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTraits in
                Task {
                    await self?.quranUITraitsUpdatedTo(newTraits)
                }
            }
            .store(in: &cancellables)
    }

    private func quranUITraitsUpdatedTo(_ quranUITraits: QuranUITraits) async {
        guard let dataSource = viewModel.dataSource else {
            return
        }
        let oldValue = dataSource.quranUITraits
        dataSource.quranUITraits = quranUITraits

        func scrollToPageIfChanged(_ keyPath: KeyPath<QuranUITraits, [AyahNumber]>) async -> Bool {
            let ayahToScrollTo = quranUITraits[keyPath: keyPath].last
            if quranUITraits[keyPath: keyPath] != oldValue[keyPath: keyPath] {
                if let ayah = ayahToScrollTo {
                    await scrollTo(page: ayah.page, animated: true, forceReload: false)
                }
            }
            return ayahToScrollTo != nil
        }

        if await !scrollToPageIfChanged(\.shareHighlights) {
            _ = await scrollToPageIfChanged(\.readingHighlights)
        }
    }

    private func scrollTo(page: Page, animated: Bool, forceReload: Bool) async {
        if UIApplication.shared.applicationState != .background {
            // update the UI only when the app is in foreground
            viewModel.dataSource?.scrollToPage(page, animated: animated, forceReload: forceReload)
            await viewModel.visiblePagesUpdated()
        } else {
            // Only update last page while in background
            await viewModel.updateLastPageTo([page])
        }
    }

    // MARK: - Background

    private func setUpBackgroundListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func applicationDidBecomeActive() {
        viewModel.dataSource?.scrollToPage(viewModel.lastViewedPage, animated: false, forceReload: false)
    }

    // MARK: - Page controller

    private func setUpDataSourceChanges() {
        viewModel.$dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dataSource in
                Task {
                    await self?.install(dataSource)
                }
            }
            .store(in: &cancellables)
    }

    private func createPageController(navigationOrientation: UIPageViewController.NavigationOrientation) -> PageController {
        if let oldPageController = pageController {
            removeChild(oldPageController.viewController)
        }

        let pageController = PageController(
            transitionStyle: .scroll,
            navigationOrientation: navigationOrientation,
            interPageSpacing: ContentDimension.interPageSpacing
        )
        pageController.pagingStrategy = pagingStrategy

        pageController.viewController.view.accessibilityIdentifier = "pages"
        pageController.viewController.view.backgroundColor = UIColor.reading
        pageController.viewController.view.semanticContentAttribute = .forceRightToLeft
        addFullScreenChild(pageController.viewController)

        self.pageController = pageController
        return pageController
    }

    private func install(_ dataSource: PageDataSource?) async {
        guard let dataSource else {
            return
        }

        let navigationOrientation: UIPageViewController.NavigationOrientation = viewModel.verticalScrollingEnabled ? .vertical : .horizontal
        let pageController = createPageController(navigationOrientation: navigationOrientation)
        pageController.pagingStrategy = newPageStrategy()
        dataSource.usePageViewController(pageController)

        dataSource.scrollToPage(viewModel.lastViewedPage, animated: false, forceReload: true)
        await viewModel.visiblePagesLoaded()
    }

    // MARK: - Gestures

    private func setUpGesture() {
        // Long press gesture on verses to select
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))

        // dismiss bars when view is panned
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onViewPanned(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    @objc
    private func onLongPress(_ sender: UILongPressGestureRecognizer) {
        guard let targetView = sender.view else {
            return
        }

        let point = sender.location(in: targetView)

        switch sender.state {
        case .began:
            viewModel.onViewLongPressStarted(at: point, sourceView: targetView)
        case .changed:
            viewModel.onViewLongPressChanged(to: point)
        case .ended:
            viewModel.onViewLongPressEnded()
        default:
            viewModel.onViewLongPressCancelled()
        }
    }

    // MARK: - Paging Strategy

    private func setUpPagingStrategyChanges() {
        viewModel.$twoPagesEnabled.sink { [weak self] twoPagesEnabled in
            self?.updatePagingStrategy(twoPagesEnabled)
        }
        .store(in: &cancellables)
    }

    private func updatePagingStrategy() {
        pageController?.pagingStrategy = newPageStrategy()
    }

    private func updatePagingStrategy(_ twoPagesEnabled: Bool) {
        pageController?.pagingStrategy = newPageStrategy(twoPagesEnabled)
    }

    private func newPageStrategy() -> PageController.PagingStrategy {
        newPageStrategy(viewModel.twoPagesEnabled)
    }

    private func newPageStrategy(_ twoPagesEnabled: Bool) -> PageController.PagingStrategy {
        let enoughHorizontalSpace = TwoPagesUtils.hasEnoughHorizontalSpace()
        let verticalScrolling = viewModel.verticalScrollingEnabled

        let shouldDisplayTwoPages = !verticalScrolling
            && isLandscape
            && enoughHorizontalSpace
            && twoPagesEnabled

        return shouldDisplayTwoPages ? .twoPages : .singlePage
    }
}
