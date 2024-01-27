//
//  ContentTranslationViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import QuranKit
import QuranPagesFeature
import SwiftUI
import UIKit

private struct ContentTranslationViewStateHolder: View {
    @StateObject var viewModel: ContentTranslationViewModel

    var body: some View {
        ContentTranslationView(viewModel: viewModel)
    }
}

class ContentTranslationViewController: UIViewController, PageView {
    // MARK: Lifecycle

    private let viewModel: ContentTranslationViewModel

    init(page: Page, viewModel: ContentTranslationViewModel) {
        self.viewModel = viewModel
        self.page = page
        super.init(nibName: nil, bundle: nil)

        viewModel.verses = page.verses

        let view = ContentTranslationViewStateHolder(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController._disableSafeArea = true
        viewController.view.backgroundColor = .clear
        addFullScreenChild(viewController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let page: Page

    func word(at point: CGPoint) -> Word? {
        nil
    }

    func verse(at point: CGPoint) -> AyahNumber? {
        viewModel.ayahAtPoint(point, from: view)
    }
}
