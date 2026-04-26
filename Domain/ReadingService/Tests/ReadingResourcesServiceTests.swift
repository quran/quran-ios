//
//  ReadingResourcesServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import AsyncAlgorithms
import AsyncUtilitiesForTesting
import BatchDownloader
import BatchDownloaderFake
import CombineSchedulers
import NetworkSupport
import NetworkSupportFake
import QuranKit
import SystemDependenciesFake
import XCTest
@testable import ReadingService

final class ReadingResourcesServiceTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        ReadingPreferences.shared.reading = .hafs_1405

        testScheduler = .immediate
        fileManager = FileSystemFake()
        remoteResources = ReadingRemoteResourcesFake()
        preferencesObservingStarted = AsyncChannelEventObserver()
        preferenceLoadingCompleted = AsyncChannelEventObserver()
        zipper = ZipperFake(fileManager: fileManager)

        testContext = BatchDownloaderFake.makeContext()
        (downloader, session) = await testContext.makeDownloader(fileManager: fileManager)

        downloadsObserver = AsyncChannel<SessionTask>()
        session.downloadsObserver = downloadsObserver

        service = ReadingResourcesService(
            fileManager: fileManager,
            zipper: zipper,
            scheduler: testScheduler,
            throttleInterval: .zero,
            preferencesObservingStarted: preferencesObservingStarted,
            preferenceLoadingCompleted: preferenceLoadingCompleted,
            downloader: downloader,
            remoteResources: remoteResources
        )
        collector = PublisherCollector(service.publisher)
    }

    override func tearDown() {
        testContext.tearDown()
        testContext = nil
        downloader = nil
        session = nil
        service = nil
    }

    func test_bundledResource() async throws {
        // Given
        ReadingPreferences.shared.reading = .hafs_1405
        // Assume all reading directories exist.
        fileManager.files = Set(Reading.allReadings.compactMap {
            remoteResources.resource(for: $0)?.downloadDestination.url
        })

        // Test
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertEqual(fileManager.files, []) // Delete other readings directories
    }

    func test_bundledResourceDeletesPreviouslyDownloadedReadingResources() async throws {
        // Given
        ReadingPreferences.shared.reading = .hafs_1405
        let downloadedReadingDirectory = try XCTUnwrap(remoteResources.resource(for: .hafs_1441)?.downloadDestination.url)
        fileManager.files = [downloadedReadingDirectory]

        // Test
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertEqual(fileManager.files, [])
    }

    func test_resourceDownloadedWhenExtractedVersionFileExistsAndPreviousSuccessFileExists() async throws {
        // Given
        let reading = Reading.tajweed
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        ReadingPreferences.shared.reading = reading
        fileManager.files = [remoteResource.extractedVersionFileURL, successFileURL(for: remoteResource, version: 1)]

        // Test
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertFalse(fileManager.removedItems.contains(remoteResource.downloadDestination.url))
        XCTAssertEqual(zipper.unzippedFiles, [])
        XCTAssertTrue(fileManager.files.contains(remoteResource.successFilePath.url))
    }

    func test_remoteResourceIsDownloadedWhenSuccessFileExists() throws {
        let reading = Reading.hafs_1441
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))

        fileManager.files.insert(remoteResource.successFilePath.url)

        XCTAssertTrue(remoteResource.isDownloaded(fileSystem: fileManager))
    }

    func test_remoteResourceIsDownloadedWhenExtractedVersionFileExists() throws {
        let reading = Reading.hafs_1441
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files = [remoteResource.extractedVersionFileURL, successFileURL(for: remoteResource, version: 1)]

        XCTAssertTrue(remoteResource.isDownloaded(fileSystem: fileManager))
    }

    func test_remoteResourceIsDownloadedWhenExtractedVersionFileExistsAndAnyOlderSuccessFileExists() throws {
        let reading = Reading.hafs_1441
        remoteResources.versions[reading] = 7
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files = [remoteResource.extractedVersionFileURL, successFileURL(for: remoteResource, version: 3)]

        XCTAssertTrue(remoteResource.isDownloaded(fileSystem: fileManager))
    }

    func test_remoteResourceIsNotDownloadedWhenExtractedVersionFileExistsWithoutPreviousSuccessFile() throws {
        let reading = Reading.hafs_1441
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files = [remoteResource.extractedVersionFileURL]

        XCTAssertFalse(remoteResource.isDownloaded(fileSystem: fileManager))
    }

    func test_remoteResourceIsNotDownloadedWithoutSuccessFile() throws {
        let reading = Reading.hafs_1441
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))

        XCTAssertFalse(remoteResource.isDownloaded(fileSystem: fileManager))
    }

    func test_naskhRemoteResourceUsesNaskhPathAndImageWidth() throws {
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: .naskh))

        XCTAssertEqual(remoteResource.downloadDestination.url.lastPathComponent, "naskh")
        XCTAssertEqual(remoteResource.zipFile.url.lastPathComponent, "naskh.zip")
        XCTAssertEqual(remoteResource.extractedVersionFileURL.lastPathComponent, ".v0")
        XCTAssertEqual(remoteResource.extractedVersionFileURL.deletingLastPathComponent().lastPathComponent, "width_1342")
        XCTAssertEqual(
            remoteResource.extractedVersionFileURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .lastPathComponent,
            "images_1342"
        )
    }

    func test_downloadResourceSuccessfully() async throws {
        // Given
        let reading = Reading.hafs_1440
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        ReadingPreferences.shared.reading = reading

        // Test
        await service.startLoadingResources()
        try await completeRunningDownload()

        // Then
        await waitForReady()
        XCTAssertEqual(collector.items.last, .ready)

        var lastProgress = 0.0
        for status in collector.items.dropLast() {
            switch status {
            case .downloading(let progress):
                XCTAssertGreaterThanOrEqual(progress, lastProgress)
                XCTAssertLessThanOrEqual(progress, 1)
                lastProgress = progress
            case .ready, .error:
                XCTFail("Unexpected statuses: \(collector.items)")
            }
        }

        try assertDownloadedFiles(reading)
        XCTAssertEqual(zipper.unzippedFiles, [remoteResource.zipFile.url])
    }

    func test_downloadUpgrade() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        remoteResources.versions[reading] = 1
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))

        // Already downloaded
        fileManager.files.insert(remoteResource.successFilePath.url)
        await service.startLoadingResources()
        await finishLoadingNoDownload()
        XCTAssertEqual(collector.items.last, .ready)
        collector.items = []

        // Test upgrade
        remoteResources.versions[reading] = 2
        await service.retry()

        // Then
        try await completeRunningDownload(initial: false)
        XCTAssertEqual(collector.items.last, .ready)
        try assertDownloadedFiles(reading)
    }

    func test_downloadUpgrade_skipsRedownloadWhenExtractedVersionFileExists() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        remoteResources.versions[reading] = 1
        let initialRemoteResource = try XCTUnwrap(remoteResources.resource(for: reading))

        fileManager.files.insert(initialRemoteResource.successFilePath.url)
        await service.startLoadingResources()
        await finishLoadingNoDownload()
        XCTAssertEqual(collector.items.last, .ready)
        collector.items = []

        // Test upgrade
        remoteResources.versions[reading] = 2
        let upgradedRemoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files.insert(upgradedRemoteResource.extractedVersionFileURL)
        await service.retry()
        await finishLoadingNoDownload(initial: false)

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        XCTAssertFalse(fileManager.removedItems.contains(upgradedRemoteResource.downloadDestination.url))
        XCTAssertEqual(zipper.unzippedFiles, [])
        XCTAssertTrue(fileManager.files.contains(upgradedRemoteResource.successFilePath.url))
    }

    func test_downloadUpgrade_skipsRedownloadWhenExtractedVersionFileExistsAndOlderSuccessFileExists() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        remoteResources.versions[reading] = 3
        let initialRemoteResource = try XCTUnwrap(remoteResources.resource(for: reading))

        fileManager.files.insert(initialRemoteResource.successFilePath.url)
        await service.startLoadingResources()
        await finishLoadingNoDownload()
        XCTAssertEqual(collector.items.last, .ready)
        collector.items = []

        // Test upgrade
        remoteResources.versions[reading] = 7
        let upgradedRemoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files.insert(upgradedRemoteResource.extractedVersionFileURL)
        await service.retry()
        await finishLoadingNoDownload(initial: false)

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        XCTAssertFalse(fileManager.removedItems.contains(upgradedRemoteResource.downloadDestination.url))
        XCTAssertEqual(zipper.unzippedFiles, [])
        XCTAssertTrue(fileManager.files.contains(upgradedRemoteResource.successFilePath.url))
    }

    func test_downloadResource_redownloadsWhenExtractedVersionFileExistsWithoutPreviousSuccessFile() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        fileManager.files = [remoteResource.extractedVersionFileURL]

        // Test
        await service.startLoadingResources()
        try await completeRunningDownload()

        // Then
        await waitForReady()
        XCTAssertEqual(collector.items.last, .ready)
        XCTAssertEqual(zipper.unzippedFiles, [remoteResource.zipFile.url])
        try assertDownloadedFiles(reading)
    }

    func test_downloadUpgrade_doesNotSkipForWrongExtractedVersionFile() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        remoteResources.versions[reading] = 2
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        let wrongVersionMarker = remoteResource.downloadDestination
            .appendingPathComponent("images_1352", isDirectory: true)
            .appendingPathComponent("width_1352", isDirectory: true)
            .appendingPathComponent(".v1", isDirectory: false)
        fileManager.files = [remoteResource.downloadDestination.url, wrongVersionMarker.url]

        // Test
        await service.startLoadingResources()
        try await completeRunningDownload()

        // Then
        await waitForReady()
        XCTAssertEqual(collector.items.last, .ready)
        XCTAssertEqual(zipper.unzippedFiles, [remoteResource.zipFile.url])
        try assertDownloadedFiles(reading)
    }

    func test_downloadResource_failedUnzip() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        let error = FileSystemError.noDiskSpace
        let partiallyExtractedFiles = zipper.zipContents(remoteResource.zipFile.url)
            .sorted { $0.path < $1.path }
            .prefix(2)
        zipper.partialFailure = .init(error: error, writtenFiles: partiallyExtractedFiles.count)

        // Test
        await service.startLoadingResources()
        try await completeRunningDownload()

        // Then
        XCTAssertEqual(collector.items.last, .error(error as NSError))
        XCTAssertEqual(fileManager.files, [remoteResource.downloadDestination.url])
        XCTAssertTrue(partiallyExtractedFiles.allSatisfy { !fileManager.files.contains($0) })

        // Retry should fix it
        await service.retry()
        try await completeRunningDownload(initial: false)
        XCTAssertEqual(collector.items.last, .ready)
        try assertDownloadedFiles(reading)
    }

    func test_downloadFailure() async throws {
        // Given
        let error = NetworkError.notConnectedToInternet
        let reading = Reading.tajweed
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        ReadingPreferences.shared.reading = reading

        fileManager.files = [
            // Old resources to delete
            remoteResource.downloadDestination.url,
        ]

        // Test
        await service.startLoadingResources()
        try await failRunningDownload(error)

        // Then
        XCTAssertEqual(collector.items.last, .error(error as NSError))
        XCTAssertEqual(fileManager.files, [])
        XCTAssertEqual(zipper.unzippedFiles, [])
    }

    func test_switch_bundleToRemote() async throws {
        // Given: Start with bundled reading
        let firstReading = Reading.hafs_1405
        ReadingPreferences.shared.reading = firstReading

        // Test: Complete the first reading.
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        collector.items = []
        XCTAssertEqual(fileManager.files, []) // No files since it's bundled

        // Given: Switch to remote
        let secondReading = Reading.hafs_1421
        ReadingPreferences.shared.reading = secondReading

        // Test
        try await completeRunningDownload(initial: false)

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        try assertDownloadedFiles(secondReading)
    }

    func test_switch_remoteToBundle() async throws {
        // Given: Start with remote resource
        let firstReading = Reading.tajweed
        ReadingPreferences.shared.reading = firstReading

        // Test: Complete the first reading.
        await service.startLoadingResources()
        try await completeRunningDownload(initial: true)

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        collector.items = []
        try assertDownloadedFiles(firstReading)

        // Given: Switch to bundled
        let secondReading = Reading.hafs_1405
        ReadingPreferences.shared.reading = secondReading

        // Test
        await finishLoadingNoDownload(initial: false)

        // Then
        XCTAssertEqual(collector.items.last, .ready)
        XCTAssertEqual(fileManager.files, []) // No files since it's bundled
    }

    func test_switch_remoteToRemote_cancelFirstDownload() async throws {
        // Given: Start with remote resource
        let firstReading = Reading.hafs_1440
        ReadingPreferences.shared.reading = firstReading
        await service.startLoadingResources()
        let firstDownload = try await runningDownload()

        // Given: Switch to bundled
        let secondReading = Reading.tajweed
        ReadingPreferences.shared.reading = secondReading

        // Test
        try await completeRunningDownload(initial: false)

        // Then
        XCTAssertTrue(firstDownload.isCancelled)
        await waitForReady()
        try assertDownloadedFiles(secondReading)
    }

    // MARK: Private

    private var service: ReadingResourcesService!
    private var collector: PublisherCollector<ReadingResourcesService.ResourceStatus>!
    private var remoteResources: ReadingRemoteResourcesFake!
    private var downloader: DownloadManager!
    private var downloadsObserver: AsyncChannel<SessionTask>!
    private var session: NetworkSessionFake!
    private var testContext: BatchDownloaderTestContext!
    private var zipper: ZipperFake!
    private var fileManager: FileSystemFake!
    private var preferenceLoadingCompleted: AsyncChannelEventObserver!
    private var preferencesObservingStarted: AsyncChannelEventObserver!
    private var testScheduler: AnySchedulerOf<DispatchQueue>!
    private let downloadURL = URL(validURL: "https://quran.com/xyz.zip")

    private func runningDownload(initial: Bool = true) async throws -> SessionTask {
        if initial {
            await preferencesObservingStarted.waitForNextEvent()
        }
        let nextDownload = await downloadsObserver.next()
        return try XCTUnwrap(nextDownload)
    }

    private func completeRunningDownload(initial: Bool = true) async throws {
        let download = try await runningDownload(initial: initial)
        fileManager.files.insert(downloadURL)
        await session.completeDownloadTask(
            download,
            location: downloadURL,
            totalBytes: 100,
            progressLoops: 1
        )
        await preferenceLoadingCompleted.waitForNextEvent()
    }

    private func failRunningDownload(_ error: Error) async throws {
        await preferencesObservingStarted.waitForNextEvent()
        let nextDownload = await downloadsObserver.next()
        let download = try XCTUnwrap(nextDownload)
        session.failDownloadTask(download, error: error)
        await preferenceLoadingCompleted.waitForNextEvent()
    }

    private func finishLoadingNoDownload(initial: Bool = true) async {
        if initial {
            await preferencesObservingStarted.waitForNextEvent()
        }
        await preferenceLoadingCompleted.waitForNextEvent()
    }

    private func assertDownloadedFiles(
        _ reading: Reading,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        var downloadedFiles: Set<URL> = [remoteResource.successFilePath.url,
                                         remoteResource.downloadDestination.url]
        downloadedFiles.formUnion(zipper.zipContents(remoteResource.zipFile.url))
        XCTAssertEqual(fileManager.files, downloadedFiles, file: file, line: line)
    }

    private func successFileURL(for remoteResource: RemoteResource, version: Int) -> URL {
        remoteResource.downloadDestination
            .appendingPathComponent("success-v\(version).txt", isDirectory: false)
            .url
    }

    private func waitForReady(file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0 ..< 10 {
            if collector.items.last == .ready {
                return
            }
            await Task.megaYield()
        }
        XCTAssertEqual(collector.items.last, .ready, file: file, line: line)
    }
}
