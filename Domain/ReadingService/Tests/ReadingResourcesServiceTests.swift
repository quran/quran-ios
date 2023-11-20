//
//  ReadingResourcesServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import AsyncAlgorithms
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
        preferencesObservingStarted = AsyncChannelEventObserver()
        preferenceLoadingCompleted = AsyncChannelEventObserver()
        service = ReadingResourcesService(
            bundle: bundle,
            fileManager: fileManager,
            preferencesObservingStarted: preferencesObservingStarted,
            preferenceLoadingCompleted: preferenceLoadingCompleted,
            resourceRequestFactory: BundleResourceRequestFake.init
        )
        collector = PublisherCollector(service.publisher)
    }

    override func tearDown() {
        service = nil
    }

    func test_resourceAvailable_notDownloaded() async throws {
        BundleResourceRequestFake.resourceAvailable = true
        await service.startLoadingResources()

        XCTAssertEqual(collector.items, [.ready])
        XCTAssertTrue(fileManager.files.contains(Reading.hafs_1405.directory))
    }

    func test_resourceNotAvailable_downloaded() async throws {
        fileManager.files.insert(Reading.hafs_1405.successFilePath)
        BundleResourceRequestFake.resourceAvailable = false
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

        await preferencesObservingStarted.waitForNextEvent()

        // Switch preference
        BundleResourceRequestFake.resourceAvailable = false
        BundleResourceRequestFake.downloadResult = .success(())
        ReadingPreferences.shared.reading = .hafs_1440

        await preferenceLoadingCompleted.waitForNextEvent()

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
    private var preferenceLoadingCompleted: AsyncChannelEventObserver!
    private var preferencesObservingStarted: AsyncChannelEventObserver!
}
