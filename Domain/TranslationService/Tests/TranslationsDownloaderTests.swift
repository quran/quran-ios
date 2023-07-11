//
//  TranslationsDownloaderTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import AsyncUtilitiesForTesting
import BatchDownloaderFake
import NetworkSupportFake
import SystemDependenciesFake
import TranslationServiceFake
import Utilities
import XCTest
@testable import BatchDownloader
@testable import TranslationService

class TranslationsDownloaderTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        fileSystem = FileSystemFake()
        (batchDownloader, session) = await BatchDownloaderFake.makeDownloader()
        downloader = TranslationsDownloader(downloader: batchDownloader)
    }

    override func tearDownWithError() throws {
        BatchDownloaderFake.tearDown()
        downloader = nil
        batchDownloader = nil
        session = nil
    }

    func test_download_newTranslation() async throws {
        let translation = TranslationTestData.khanTranslation

        let response = try await downloader.download(translation)
        XCTAssertEqual(response.urls, [translation.fileURL])
        XCTAssertEqual(response.destinations, [translation.localPath])
    }

    func test_runningDownloads_empty() async throws {
        let downloads = await downloader.runningTranslationDownloads()
        XCTAssertEqual(downloads, [])
    }

    func test_runningDownloads_downloading() async throws {
        let translation = TranslationTestData.khanTranslation

        let response = try await downloader.download(translation)

        let downloads = await downloader.runningTranslationDownloads()
        XCTAssertEqual(downloads, [response])
    }

    // MARK: Private

    private static let baseURL = URL(validURL: "http://example.com")

    private var downloader: TranslationsDownloader!
    private var batchDownloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var fileSystem: FileSystemFake!
}

private extension DownloadBatchResponse {
    nonisolated var urls: [URL?] {
        requests.map(\.request.url)
    }

    nonisolated var destinations: [RelativeFilePath] {
        requests.map(\.destination)
    }
}
