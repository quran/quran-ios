//
//  ContentImageBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/16/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Caching
import ImageService
import NoorUI
import PromiseKit
import QuranGeometry
import QuranKit
import QuranPagesFeature
import ReadingService
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

extension Page: Pageable { }
