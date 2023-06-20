//
//  VerticalPageController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-08.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import NoorUI
import UIKit
import UIx

class VerticalPageController: UIViewController, PagesContainer {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(controller: UIViewController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
        configureView()
        setUpSeparators()
        installViewController()
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

    private func installViewController() {
        addChild(controller)
        view.addAutoLayoutSubview(controller.view)
        controller.view.vc.edges()
        controller.didMove(toParent: self)
    }

    private func setUpSeparators() {
        let line = UIView()
        line.backgroundColor = UIColor.pageSeparatorLine
        view.addAutoLayoutSubview(line)
        line.vc.horizontalEdges().height(by: 1).bottom(by: ContentDimension.interPageSpacing / 2)
    }
}
