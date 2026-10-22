//
//  DownloadManagerFailureTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-21.
//

import AsyncUtilitiesForTesting
import BatchDownloaderFake
import NetworkSupport
import NetworkSupportFake
import Utilities
import XCTest
@testable import BatchDownloader

private typealias AsyncThrowingPublisher = Utilities.AsyncThrowingPublisher

final class DownloadManagerFailureTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        testContext = BatchDownloaderFake.makeContext()
        request1 = testContext.makeDownloadRequest("1")
        (downloader, session) = await testContext.makeDownloader()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        downloader = nil
        session = nil
        request1 = nil
        testContext = nil
    }

    func testDownloadFailWithResumeData() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        // fail download with resume data
        let task = try XCTUnwrap(details.task as? SessionTask)
        let resumeText = "some data"
        let error = URLError(.networkConnectionLost, userInfo: [
            NSURLSessionDownloadTaskResumeData: resumeText.data(using: .utf8) as Any,
        ])
        session?.failDownloadTask(task, error: error)

        // verify promise result
        await assertThrows(response.progress, NetworkError.connectionLost)

        // verify task
        await assertThrows(details.progress.values(), NetworkError.connectionLost)
        try await AsyncAssertEqual(try String(contentsOf: request1.resumePath), resumeText)
    }

    func testDownloadFailWithNoSpaceLeftOnDeviceThrowsNoDiskSpace() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        // A full device fails background downloads with ENOSPC.
        let task = try XCTUnwrap(details.task as? SessionTask)
        session?.failDownloadTask(task, error: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC)))

        await assertThrows(response.progress, FileSystemError.noDiskSpace)
        await assertThrows(details.progress.values(), FileSystemError.noDiskSpace)
    }

    func testDownloadFailWithNoSuchFileAndAmpleSpaceThrowsNetworkError() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        // The test host has plenty of free space, so ENOENT isn't a full device.
        let task = try XCTUnwrap(details.task as? SessionTask)
        session?.failDownloadTask(task, error: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)))

        let batchError = await thrownError(response.progress)
        guard case .unknown? = batchError as? NetworkError else {
            return XCTFail("Expected NetworkError.unknown, got \(String(describing: batchError))")
        }

        let requestError = await thrownError(details.progress.values())
        guard case .unknown? = requestError as? NetworkError else {
            return XCTFail("Expected NetworkError.unknown, got \(String(describing: requestError))")
        }
    }

    func testDownloadWhoseFileCouldNotBeKeptOnFullDeviceThrowsNoDiskSpace() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        let task = try XCTUnwrap(details.task as? SessionTask)
        failKeepingFile(of: task, statusCode: 200, error: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC)))

        await assertThrows(response.progress, FileSystemError.noDiskSpace)
        await assertThrows(details.progress.values(), FileSystemError.noDiskSpace)
    }

    func testDownloadWhoseFileCouldNotBeKeptThrowsFileSystemError() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        let task = try XCTUnwrap(details.task as? SessionTask)
        failKeepingFile(of: task, statusCode: 200, error: CocoaError(.fileWriteUnknown))

        let batchError = await thrownError(response.progress)
        guard case .unknown? = batchError as? FileSystemError else {
            return XCTFail("Expected FileSystemError.unknown, got \(String(describing: batchError))")
        }
    }

    func testResumedDownloadWhoseFileCouldNotBeKeptRemovesResumeData() async throws {
        // An earlier attempt saved resume data, so this download resumes from it.
        try FileManager.default.createDirectory(at: testContext.downloadsURL.url, withIntermediateDirectories: true)
        try XCTUnwrap("some data".data(using: .utf8)).write(to: request1.resumePath.url)

        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        let task = try XCTUnwrap(details.task as? SessionTask)
        failKeepingFile(of: task, statusCode: 200, error: CocoaError(.fileWriteUnknown))
        _ = await thrownError(response.progress)

        // The transfer used up the resume data, so a retry must start over.
        XCTAssertFalse(request1.resumePath.isReachable)
    }

    func testDownloadRejectedByServerWhoseFileCouldNotBeKeptThrowsServerError() async throws {
        let batch = DownloadBatchRequest(requests: [request1])
        let response = try await downloader.download(batch)
        let details = await response.details(of: request1)

        let task = try XCTUnwrap(details.task as? SessionTask)
        failKeepingFile(of: task, statusCode: 404, error: CocoaError(.fileWriteUnknown))

        let batchError = await thrownError(response.progress)
        guard case .serverError? = batchError as? NetworkError else {
            return XCTFail("Expected NetworkError.serverError, got \(String(describing: batchError))")
        }
    }

    // MARK: Private

    private var downloader: DownloadManager!
    private var session: NetworkSessionFake!
    private var testContext: BatchDownloaderTestContext!
    private var request1: DownloadRequest!

    /// Completes `task` the way NetworkSession does when the transfer finished but its file couldn't be kept.
    private func failKeepingFile(of task: SessionTask, statusCode: Int, error: Error) {
        task.response = HTTPURLResponse(url: request1.url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        session?.failDownloadTask(task, error: DownloadedFileMoveError(underlyingError: error))
    }

    private func thrownError(_ progress: AsyncThrowingPublisher<DownloadProgress>) async -> Error? {
        do {
            for try await _ in progress { }
            return nil
        } catch {
            return error
        }
    }

    private func assertThrows(
        _ progress: AsyncThrowingPublisher<DownloadProgress>,
        _ expectedError: (some Error)?,
        _ message: @autoclosure () -> String = "Didn't throw",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await AsyncAssertThrows(
            try await { for try await _ in progress { } }(),
            expectedError as NSError?,
            message(),
            file: file,
            line: line
        )
    }
}
