//
//  ReadingResourcesServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import AsyncUtilitiesForTesting
import QuranKit
import SystemDependenciesFake
import XCTest
@testable import ReadingService

final class ReadingResourcesServiceTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        ReadingPreferences.shared.reading = .hafs_1405
        bundle = SystemBundleFake()
        Reading.sortedReadings.forEach { reading in
            bundle.urls[reading.resourcesTag] = URL(fileURLWithPath: reading.resourcesTag)
        }
        fileManager = FileSystemFake()
        service = ReadingResourcesService(
            bundle: bundle,
            fileManager: fileManager,
            resourceRequestFactory: BundleResourceRequestFake.init
        )
        collector = PublisherCollector(service.publisher)
    }

    func testResourceAvailable() async throws {
        BundleResourceRequestFake.resourceAvailable = true
        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.ready])
        XCTAssertTrue(fileManager.files.contains(Reading.hafs_1405.directory))
    }

    func testResourceDownloading() async throws {
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())

        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.downloading(progress: 0),
                                         .downloading(progress: 1),
                                         .ready])
        XCTAssertTrue(fileManager.files.contains(Reading.hafs_1405.directory))
    }

    func testResourceDownloadFailure() async throws {
        let error = URLError(.notConnectedToInternet)
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .failure(error)

        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.downloading(progress: 0),
                                         .error(error as NSError)])
        XCTAssertFalse(fileManager.files.contains(Reading.hafs_1405.directory))
    }

    func testResourceSwitching() async throws {
        BundleResourceRequestFake.resourceAvailable = true
        await service.startLoadingResources()
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertTrue(fileManager.files.contains(Reading.hafs_1405.directory))

        // Switch preference
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())
        ReadingPreferences.shared.reading = .hafs_1440

        await Task.megaYield()

        XCTAssertEqual(collector.items, [.ready,
                                         .downloading(progress: 0),
                                         .downloading(progress: 1),
                                         .ready])
        XCTAssertTrue(fileManager.files.contains(Reading.hafs_1440.directory))
        XCTAssertFalse(fileManager.files.contains(Reading.hafs_1405.directory))
    }

    // MARK: Private

    private var service: ReadingResourcesService!
    private var collector: PublisherCollector<ReadingResourcesService.ResourceStatus>!
    private var bundle: SystemBundleFake!
    private var fileManager: FileSystemFake!
}
