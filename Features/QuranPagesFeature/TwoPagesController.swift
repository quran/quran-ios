//
//  TwoPagesController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-09-29.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import UIKit
import UIx

class TwoPagesController: UIViewController, PagesContainer {
    // MARK: Lifecycle

    init(first: UIViewController, second: UIViewController) {
        self.first = first
        self.second = second
        super.init(nibName: nil, bundle: nil)
        configureView()
        setUpSeparators()
        installViewControllers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let first: UIViewController
    let second: UIViewController

    var pages: [UIViewController] { [first, second] }

    // MARK: Private

    private func configureView() {
        loadViewIfNeeded()
        view.backgroundColor = UIColor.reading
        view.semanticContentAttribute = .forceRightToLeft
    }

    private func installViewControllers() {
        for viewController in [first, second] {
            addChild(viewController)
            view.addAutoLayoutSubview(viewController.view)
            viewController.view.vc.verticalEdges()
        }

        first.view.vc.leading(by: SidePageSeparator.width)
        second.view.vc.trailing(by: SidePageSeparator.width)
        first.view.vc.width(to: second.view)
        view.addSiblingHorizontalContiguous(left: first.view, right: second.view)

        for viewController in [first, second] {
            viewController.didMove(toParent: self)
        }
    }

    private func setUpSeparators() {
        let middleSeparator = MiddlePageSeparator()
        view.addAutoLayoutSubview(middleSeparator)
        middleSeparator.vc.verticalEdges().centerX()

        let rightSeparator = SidePageSeparator.rightSide()
        view.addAutoLayoutSubview(rightSeparator)
        rightSeparator.vc.verticalEdges().leading()

        let leftSeparator = SidePageSeparator.leftSide()
        view.addAutoLayoutSubview(leftSeparator)
        leftSeparator.vc.verticalEdges().trailing()
    }
}
