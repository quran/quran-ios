//
//  TabInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import FeaturesSupport
import QuranAnnotations
import QuranContentFeature
import QuranKit
import QuranViewFeature
import UIKit

protocol TabPresenter: UINavigationController {
}

class TabInteractor: QuranNavigator {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder) {
        self.quranBuilder = quranBuilder
    }

    // MARK: Internal

    weak var presenter: TabPresenter?

    func navigateTo(page: Page, lastPage: LastPage?, highlightingSearchAyah: AyahNumber?) {
        let input = QuranInput(initialPage: page, lastPage: lastPage, highlightingSearchAyah: highlightingSearchAyah)
        let viewController = quranBuilder.build(input: input)
        presenter?.pushViewController(viewController, animated: true)
    }

    func start() {
    }

    // MARK: Private

    private let quranBuilder: QuranBuilder
}
