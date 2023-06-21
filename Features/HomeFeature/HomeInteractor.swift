//
//  HomeInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import FeaturesSupport
import QuranAnnotations
import QuranKit
import UIKit

@MainActor
protocol HomePresentable: UIViewController {
    func selectSuras()
    func selectJuzs()
}

@MainActor
final class HomeInteractor: QuranNavigator {
    // MARK: Lifecycle

    init(surasBuilder: HomeSegmentBuildable, juzsBuilder: HomeSegmentBuildable) {
        self.surasBuilder = surasBuilder
        self.juzsBuilder = juzsBuilder
    }

    // MARK: Internal

    weak var listener: QuranNavigator?
    weak var presenter: HomePresentable?

    func start() {
        presenter?.selectSuras()
    }

    func navigateTo(page: Page, lastPage: LastPage?, highlightingSearchAyah: AyahNumber?) {
        listener?.navigateTo(page: page, lastPage: lastPage, highlightingSearchAyah: highlightingSearchAyah)
    }

    func surasSelected() {
        show(builder: surasBuilder, existingController: &surasRouter)
    }

    func juzsSelected() {
        show(builder: juzsBuilder, existingController: &juzsRouter)
    }

    // MARK: Private

    private let surasBuilder: HomeSegmentBuildable
    private let juzsBuilder: HomeSegmentBuildable

    private var surasRouter: UIViewController?
    private var juzsRouter: UIViewController?

    private var showing: UIViewController? {
        didSet {
            if showing === oldValue {
                return
            }

            if let oldValue {
                presenter?.removeChild(oldValue)
            }

            if let showing {
                presenter?.addFullScreenChild(showing)
            }
        }
    }

    private func show(builder: HomeSegmentBuildable, existingController: inout UIViewController?) {
        let viewController: UIViewController
        if let existingController {
            viewController = existingController
        } else {
            let newController = builder.build(withListener: self)
            existingController = newController
            viewController = newController
        }
        showing = viewController
    }
}
