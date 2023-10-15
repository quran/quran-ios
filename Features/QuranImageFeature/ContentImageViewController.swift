//
//  ContentImageViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Caching
import Crashing
import ImageService
import QuranAnnotations
import QuranGeometry
import QuranKit
import QuranPagesFeature
import UIKit

class ContentImageViewController: UIViewController, PageView {
    // MARK: Lifecycle

    init(
        page: Page,
        dataService: PagesCacheableService<Page, ImagePage>,
        pageMarkerService: PagesCacheableService<Page, PageMarkers>?
    ) {
        self.dataService = dataService
        self.pageMarkerService = pageMarkerService
        super.init(nibName: nil, bundle: nil)
        contentView.page = page
        loadPageImage(page)
        if let pageMarkerService {
            loadPageMarkers(page, dataService: pageMarkerService)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var quranUITraits: QuranUITraits {
        get { contentView.quranUITraits }
        set { contentView.quranUITraits = newValue }
    }

    var page: Page {
        contentView.page!
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

    private let contentView = ContentImageView()
    private let dataService: PagesCacheableService<Page, ImagePage>
    private let pageMarkerService: PagesCacheableService<Page, PageMarkers>?

    private func loadPageImage(_ page: Page) {
        if let element = dataService.getCached(page) {
            configure(with: element)
        } else {
            Task { @MainActor in
                do {
                    let element = try await dataService.get(page)
                    configure(with: element)
                } catch {
                    // TODO: should show error to the user
                    crasher.recordError(error, reason: "Failed to retrieve quran page details")
                }
            }
        }
    }

    private func configure(with element: ImagePage) {
        contentView.configure(with: element)
    }

    // MARK: - Page Markers

    private func loadPageMarkers(_ page: Page, dataService: PagesCacheableService<Page, PageMarkers>) {
        if let element = dataService.getCached(page) {
            configure(with: element)
        } else {
            Task {
                do {
                    let element = try await dataService.get(page)
                    configure(with: element)
                } catch {
                    // TODO: should show error to the user
                    crasher.recordError(error, reason: "Failed to retrieve quran page markers \(page)")
                }
            }
        }
    }

    private func configure(with element: PageMarkers) {
        contentView.configure(with: element)
    }
}
