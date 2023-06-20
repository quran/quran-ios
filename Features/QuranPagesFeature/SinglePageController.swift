//
//  SinglePageController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-08.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import NoorUI
import UIKit
import UIx

class SinglePageController: UIViewController, PagesContainer {
    // MARK: Lifecycle

    init(controller: UIViewController, isLeftSide: Bool) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
        configureView()
        setUpSeparators(isLeftSide: isLeftSide)
        installViewController(isLeftSide: isLeftSide)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let controller: UIViewController

    var pages: [UIViewController] { [controller] }

    // MARK: Private

    private func configureView() {
        loadViewIfNeeded()
        view.backgroundColor = UIColor.reading
        view.semanticContentAttribute = .forceRightToLeft
    }

    private func installViewController(isLeftSide: Bool) {
        addChild(controller)
        view.addAutoLayoutSubview(controller.view)
        controller.view.vc.verticalEdges()
        controller.view.vc.leading(by: isLeftSide ? SidePageSeparator.width : 0)
        controller.view.vc.trailing(by: !isLeftSide ? SidePageSeparator.width : 0)
        controller.didMove(toParent: self)
    }

    private func setUpSeparators(isLeftSide: Bool) {
        if isLeftSide {
            setUpLeftSideSeparators()
        } else {
            setUpRightSideSeparators()
        }
    }

    private func setUpLeftSideSeparators() {
        let middleSeparator = MiddlePageSeparator()
        view.addAutoLayoutSubview(middleSeparator)
        middleSeparator.vc.verticalEdges().left(by: -1 * (MiddleSidePageSeparator.width + ContentDimension.interPageSpacing / 2))

        let rightSeparator = SidePageSeparator.rightSide()
        view.addAutoLayoutSubview(rightSeparator)
        rightSeparator.vc.verticalEdges().right()
    }

    private func setUpRightSideSeparators() {
        let leftSeparator = SidePageSeparator.leftSide()
        view.addAutoLayoutSubview(leftSeparator)
        leftSeparator.vc.verticalEdges().left()
    }
}
