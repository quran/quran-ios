//
//  ReadingResourcesServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import AsyncUtilitiesForTesting
@testable import ReadingService
import XCTest
import SystemDependenciesFake

final class ReadingResourcesServiceTests: XCTestCase {
    private var service: ReadingResourcesService!
    private var collector: PublisherCollector<ReadingResourcesService.ResourceStatus>!

    override func setUp() {
        ReadingPreferences.shared.reading = .hafs_1405
        service = ReadingResourcesService(resourceRequestFactory: BundleResourceRequestFake.init)
        collector = PublisherCollector(service.publisher)
    }

    func testResourceAvailable() async throws {
        BundleResourceRequestFake.resourceAvailable = true
        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.ready])
    }

    func testResourceDownloading() async throws {
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())

        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.downloading(progress: 0),
                                         .downloading(progress: 1),
                                         .ready])
    }

    func testResourceDownloadFailure() async throws {
        let error = URLError(.notConnectedToInternet)
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .failure(error)

        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.downloading(progress: 0),
                                         .error(error as NSError)])
    }

    func testResourceSwitching() async throws {
        BundleResourceRequestFake.resourceAvailable = true
        await service.startLoadingResources()
        XCTAssertEqual(collector.items, [.ready])

        // Switch preference
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())
        ReadingPreferences.shared.reading = .hafs_1440

        await Task.megaYield()

        XCTAssertEqual(collector.items, [.ready,
                                         .downloading(progress: 0),
                                         .downloading(progress: 1),
                                         .ready])
    }
}
