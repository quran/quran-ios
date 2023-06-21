//
//  ContentTranslationViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Caching
import Combine
import Crashing
import NoorUI
import QuranKit
import QuranPagesFeature
import QuranTextKit
import TranslationService
import UIKit
import Utilities

@MainActor
class ContentTranslationViewController: UIViewController, PageView {
    // MARK: Lifecycle

    init(dataService: PagesCacheableService<Page, TranslatedPage>, page: Page) {
        self.dataService = dataService
        super.init(nibName: nil, bundle: nil)
        contentView.page = page
        reloadData()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var page: Page {
        contentView.page!
    }

    var quranUITraits: QuranUITraits {
        get { contentView.quranUITraits }
        set { contentView.quranUITraits = newValue }
    }

    override func loadView() {
        view = contentView
    }

    func word(at point: CGPoint) -> Word? {
        contentView.word(at: point)
    }

    func verse(at point: CGPoint) -> AyahNumber? {
        contentView.verse(at: point)
    }

    // MARK: Private

    private let contentView = ContentTranslationView()
    private let dataService: PagesCacheableService<Page, TranslatedPage>

    private func reloadData() {
        if let element = dataService.getCached(page) {
            configureWithElement(element)
        } else {
            Task { @MainActor in
                do {
                    let element = try await dataService.get(page)
                    configureWithElement(element)
                } catch {
                    // TODO: should show error to the user
                    crasher.recordError(error, reason: "Failed to retrieve quran page details")
                }
            }
        }
    }

    private func configureWithElement(_ element: TranslatedPage) {
        contentView.configure(for: element)
    }
}
