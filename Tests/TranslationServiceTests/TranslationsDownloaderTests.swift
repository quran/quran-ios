//
//  TranslationsDownloaderTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

@testable import BatchDownloader
import SystemDependenciesFake
import TestUtilities
@testable import TranslationService
import XCTest

class TranslationsDownloaderTests: XCTestCase {
    private var downloader: TranslationsDownloader!
    private var batchDownloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var fileSystem: FileSystemFake!

    private static let baseURL = URL(validURL: "http://example.com")

    override func setUp() async throws {
        fileSystem = FileSystemFake()
        (batchDownloader, session) = await NetworkSessionFake.makeDownloader()
        downloader = TranslationsDownloader(downloader: batchDownloader)
    }

    override func tearDownWithError() throws {
        NetworkSessionFake.tearDown()
    }

    func test_download_newTranslation() async throws {
        let translation = TranslationTestData.khanTranslation

        let response = try await downloader.download(translation)
        await AsyncAssertEqual(await response.urls, [translation.fileURL])
        await AsyncAssertEqual(await response.destinations, [Translation.translationsPathComponent.stringByAppendingPath(translation.fileName)])
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

    var destinations: [String] {
        get async {
            await responses.asyncMap { await $0.download.request.destinationPath }
        }
    }
}
