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

        (downloader, session) = await BatchDownloaderFake.makeDownloader(fileManager: fileManager)

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
        BatchDownloaderFake.tearDown()
        downloader = nil
        session = nil
        service = nil
    }

    func test_bundledResource() async throws {
        // Given
        ReadingPreferences.shared.reading = .hafs_1405
        // Assume all reading directories exist.
        fileManager.files = Set(Reading.sortedReadings.compactMap {
            remoteResources.resource(for: $0)?.downloadDestination.url
        })

        // Test
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items, [.ready])
        XCTAssertEqual(fileManager.files, []) // Delete other readings directories
    }

    func test_resourceDownloadedAndUnzipped() async throws {
        // Given
        let reading = Reading.tajweed
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        ReadingPreferences.shared.reading = reading
        fileManager.files.insert(remoteResource.successFilePath.url)

        // Test
        await service.startLoadingResources()
        await finishLoadingNoDownload()

        // Then
        XCTAssertEqual(collector.items, [.ready])
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
        XCTAssertEqual(collector.items, [.downloading(progress: 0),
                                         .downloading(progress: 1),
                                         .ready])
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

    func test_downloadResource_failedUnzip() async throws {
        // Given
        let reading = Reading.hafs_1440
        ReadingPreferences.shared.reading = reading
        let remoteResource = try XCTUnwrap(remoteResources.resource(for: reading))
        let error = FileSystemError.noDiskSpace
        zipper.failures = [error]

        // Test
        await service.startLoadingResources()
        try await completeRunningDownload()

        // Then
        XCTAssertEqual(collector.items.last, .error(error as NSError))
        XCTAssertEqual(fileManager.files, [remoteResource.downloadDestination.url])

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
