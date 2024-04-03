//
//  ContentImageViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import QuranKit
import QuranPagesFeature
import SwiftUI

private struct ContentImageViewStateHolder: View {
    @StateObject var viewModel: ContentImageViewModel

    var body: some View {
        ContentImageView(viewModel: viewModel)
    }
}

class ContentImageViewController: UIViewController, PageView {
    // MARK: Lifecycle

    private let viewModel: ContentImageViewModel

    init(page: Page, viewModel: ContentImageViewModel) {
        self.viewModel = viewModel
        self.page = page
        super.init(nibName: nil, bundle: nil)

        let view = ContentImageViewStateHolder(viewModel: viewModel)
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
        let globalPoint = view.convert(point, to: view.window)
        return viewModel.wordAtGlobalPoint(globalPoint)
    }

    func verse(at point: CGPoint) -> AyahNumber? {
        word(at: point)?.verse
    }
}
