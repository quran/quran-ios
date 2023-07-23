//
//  ContentImageBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/16/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Caching
import Foundation
import ImageService
import NoorUI
import QuranGeometry
import QuranKit
import QuranPagesFeature
import ReadingService
import UIKit
import Utilities

@MainActor
public struct ContentImageBuilder: PageDataSourceBuilder {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func build(actions: PageDataSourceActions, pages: [Page]) -> PageDataSource {
        let reading = ReadingPreferences.shared.reading

        let imageService = ImageDataService(
            ayahInfoDatabase: reading.ayahInfoDatabase,
            imagesURL: reading.images,
            cropInsets: reading.cropInsets
        )

        let cacheableImageService = createCahceableImageService(imageService: imageService, pages: pages)
        let cacheablePageMarkers = createPageMarkersService(imageService: imageService, reading: reading, pages: pages)
        return PageDataSource(actions: actions) { page in
            let controller = ContentImageViewController(
                page: page,
                dataService: cacheableImageService,
                pageMarkerService: cacheablePageMarkers
            )
            return controller
        }
    }

    // MARK: Private

    private func createCahceableImageService(imageService: ImageDataService, pages: [Page]) -> PagesCacheableService<Page, ImagePage> {
        let cache = Cache<Page, ImagePage>()
        cache.countLimit = 5

        let operation = { @Sendable (page: Page) in
            try await imageService.imageForPage(page)
        }
        let dataService = PagesCacheableService(
            cache: cache,
            previousPagesCount: 1,
            nextPagesCount: 2,
            pages: pages,
            operation: operation
        )
        return dataService
    }

    private func createPageMarkersService(
        imageService: ImageDataService,
        reading: Reading,
        pages: [Page]
    ) -> PagesCacheableService<Page, PageMarkers>? {
        // Only hafs 1421 supports page markers
        guard reading == .hafs_1421 else {
            return nil
        }

        let cache = Cache<Page, PageMarkers>()
        cache.countLimit = 5

        let operation = { @Sendable (page: Page) in
            try await imageService.pageMarkers(page)
        }
        let dataService = PagesCacheableService(
            cache: cache,
            previousPagesCount: 1,
            nextPagesCount: 2,
            pages: pages,
            operation: operation
        )
        return dataService
    }
}

private extension Reading {
    var ayahInfoDatabase: URL {
        switch self {
        case .hafs_1405:
            return Bundle.main.url(forResource: "hafs_1405/images_1920/databases/ayahinfo_1920", withExtension: "db")!
        case .hafs_1421:
            return Bundle.main.url(forResource: "hafs_1421/images_1120/databases/ayahinfo_1120", withExtension: "db")!
        case .hafs_1440:
            return Bundle.main.url(forResource: "hafs_1440/images_1352/databases/ayahinfo_1352", withExtension: "db")!
        case .tajweed:
            return Bundle.main.url(forResource: "tajweed/images_1280/databases/ayahinfo_1280", withExtension: "db")!
        }
    }

    var images: URL {
        switch self {
        case .hafs_1405:
            return Bundle.main.url(forResource: "hafs_1405/images_1920/width_1920", withExtension: nil)!
        case .hafs_1421:
            return Bundle.main.url(forResource: "hafs_1421/images_1120/width_1120", withExtension: nil)!
        case .hafs_1440:
            return Bundle.main.url(forResource: "hafs_1440/images_1352/width_1352", withExtension: nil)!
        case .tajweed:
            return Bundle.main.url(forResource: "tajweed/images_1280/width_1280", withExtension: nil)!
        }
    }

    var cropInsets: UIEdgeInsets {
        switch self {
        case .hafs_1405:
            return UIEdgeInsets(top: 10, left: 34, bottom: 40, right: 24)
        case .hafs_1421:
            return .zero
        case .hafs_1440:
            return .zero
        case .tajweed:
            return .zero
        }
    }
}
