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
import XCTest
@testable import BatchDownloader
@testable import TranslationService

class TranslationsDownloaderTests: XCTestCase {
    private var downloader: TranslationsDownloader!
    private var batchDownloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var fileSystem: FileSystemFake!

    private static let baseURL = URL(validURL: "http://example.com")

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
        await AsyncAssertEqual(await response.urls, [translation.fileURL])
        await AsyncAssertEqual(await response.destinations, [translation.localURL])
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
}

private extension DownloadBatchResponse {
    var urls: [URL?] {
        get async {
            await responses.asyncMap { await $0.download.request.request.url }
        }
    }

    var destinations: [URL] {
        get async {
            await responses.asyncMap { await $0.download.request.destinationURL }
        }
    }
}
