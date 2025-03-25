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
        view.backgroundColor = .readingBackground
        setUpGesture()
        setUpPagesView()
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    public func word(at point: CGPoint) -> Word? {
        let actions = viewModel.geometryActions
        for action in actions {
            if let word = action.word(point) {
                return word
            }
        }
        return nil
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

    private func setUpPagesView() {
        let viewModel = viewModel
        let pagesView = PagesView(viewModel: viewModel)
        let pagingController = UIHostingController(rootView: pagesView)
        addFullScreenChild(pagingController)
    }

    private func verse(at point: CGPoint) -> AyahNumber? {
        let actions = viewModel.geometryActions
        for action in actions {
            if let verse = action.verse(point) {
                return verse
            }
        }
        return nil
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
        let globalPoint = sender.location(in: nil)

        switch sender.state {
        case .began:
            if let verse = verse(at: globalPoint) {
                viewModel.onViewLongPressStarted(at: point, sourceView: targetView, verse: verse)
            }
        case .changed:
            if let verse = verse(at: globalPoint) {
                viewModel.onViewLongPressChanged(to: point, verse: verse)
            }
        case .ended:
            viewModel.onViewLongPressEnded()
        default:
            viewModel.onViewLongPressCancelled()
        }
    }
}
