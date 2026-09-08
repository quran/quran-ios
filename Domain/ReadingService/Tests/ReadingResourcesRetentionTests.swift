import AsyncUtilitiesForTesting
import BatchDownloaderFake
import CombineSchedulers
import QuranKit
import SystemDependenciesFake
import XCTest
@testable import ReadingService

final class ReadingResourcesRetentionTests: XCTestCase {
    func test_preservesDownloadedResourcesAcrossReadingSwitchesWhenCleanupDisabled() async {
        let originalReading = ReadingPreferences.shared.reading
        ReadingPreferences.shared.reading = .hafs_1405
        defer { ReadingPreferences.shared.reading = originalReading }

        let fileManager = FileSystemFake()
        let remoteResources = ReadingRemoteResourcesFake()
        let downloadedFiles = Set(Reading.allReadings.compactMap { remoteResources.resource(for: $0) }.flatMap {
            [$0.downloadDestination.url, $0.successFilePath.url, $0.extractedVersionFileURL]
        })
        fileManager.files = downloadedFiles
        let context = BatchDownloaderFake.makeContext()
        defer { context.tearDown() }
        let (downloader, session) = await context.makeDownloader(fileManager: fileManager)
        let loadingCompleted = AsyncChannelEventObserver()
        let service = ReadingResourcesService(
            fileManager: fileManager,
            scheduler: .immediate,
            throttleInterval: .zero,
            preferenceLoadingCompleted: loadingCompleted,
            downloader: downloader,
            remoteResources: remoteResources,
            removeOtherReadings: false
        )
        let collector = PublisherCollector(service.publisher)

        await service.startLoadingResources()
        await loadingCompleted.waitForNextEvent()
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertEqual(fileManager.files, downloadedFiles)

        ReadingPreferences.shared.reading = .hafs_1441
        await loadingCompleted.waitForNextEvent()
        XCTAssertEqual(collector.items, [.ready, .ready])
        XCTAssertEqual(fileManager.files, downloadedFiles)

        ReadingPreferences.shared.reading = .hafs_1421
        await loadingCompleted.waitForNextEvent()
        XCTAssertEqual(collector.items, [.ready, .ready, .ready])
        XCTAssertEqual(fileManager.files, downloadedFiles)
        XCTAssertTrue(session.downloads.isEmpty)
        await service.stopLoadingResources()
    }
}
