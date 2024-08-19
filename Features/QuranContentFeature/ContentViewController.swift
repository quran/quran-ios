//
//  ContentViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import NoorUI
import QuranKit
import QuranPagesFeature
import QuranTextKit
import SwiftUI
import UIKit
import UIx

public final class ContentViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: Lifecycle

    public init(viewModel: ContentViewModel) {
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

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .reading
        setUpGesture()
        setUpPagesView()
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    public func word(at point: CGPoint, in view: UIView) -> Word? {
        convert(point, from: view)
            .flatMap { $0.word(at: $1) }
    }

    // MARK: Internal

    @objc
    func onViewPanned(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            viewModel.listener?.userWillBeginDragScroll()
        }
    }

    // MARK: Private

    private let viewModel: ContentViewModel

    private var pageViews: [PageView] {
        findPageViews(in: self)
    }

    private func setUpPagesView() {
        let pagesView = PagesView(viewModel: viewModel)
        let pagingController = UIHostingController(rootView: pagesView)
        addFullScreenChild(pagingController)
    }

    private func verse(at point: CGPoint, in view: UIView) -> AyahNumber? {
        convert(point, from: view)
            .flatMap { $0.verse(at: $1) }
    }

    private func convert(_ point: CGPoint, from view: UIView) -> (view: PageView, point: CGPoint)? {
        let localPointsAndControllers = pageViews.map { (view: $0, point: $0.view.convert(point, from: view)) }
        let convertedViewPoint = localPointsAndControllers.first { $0.view.view.point(inside: $0.point, with: nil) }
        return convertedViewPoint
    }

    private func findPageViews(in viewController: UIViewController) -> [PageView] {
        var result = [PageView]()

        for child in viewController.children {
            if let fooVC = child as? PageView {
                result.append(fooVC)
            }

            // Recursively search in the child's children
            result.append(contentsOf: findPageViews(in: child))
        }

        return result
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
            if let verse = verse(at: point, in: targetView) {
                viewModel.onViewLongPressStarted(at: point, sourceView: targetView, verse: verse)
            }
        case .changed:
            if let verse = verse(at: point, in: targetView) {
                viewModel.onViewLongPressChanged(to: point, verse: verse)
            }
        case .ended:
            viewModel.onViewLongPressEnded()
        default:
            viewModel.onViewLongPressCancelled()
        }
    }
}

private struct PagesView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        GeometryReader { geometry in
            QuranPaginationView(
                pagingStrategy: pagingStrategy(with: geometry),
                selection: $viewModel.visiblePages,
                pages: viewModel.deps.quran.pages
            ) { page in
                StaticViewControllerRepresentable(viewController: viewModel.pageViewBuilder.build(at: page))
            }
            .id(viewModel.quranMode)
        }
    }

    func pagingStrategy(with geometry: GeometryProxy) -> PagingStrategy {
        if geometry.size.height > geometry.size.width {
            return .singlePage
        }

        if !TwoPagesUtils.hasEnoughHorizontalSpace() {
            return .singlePage
        }

        return viewModel.pagingStrategy
    }
}
