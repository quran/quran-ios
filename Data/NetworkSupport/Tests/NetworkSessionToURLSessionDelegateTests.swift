//
//  NetworkSessionToURLSessionDelegateTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-21.
//

import AsyncUtilitiesForTesting
import Utilities
import XCTest
@testable import NetworkSupport

final class NetworkSessionToURLSessionDelegateTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        session = URLSession(configuration: .ephemeral)
        spy = NetworkSessionDelegateSpy()
        delegate = NetworkSessionToURLSessionDelegate(networkSessionDelegate: spy)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        spy = nil
        delegate = nil
        super.tearDown()
    }

    func testDownloadWhoseFileCannotBeMovedCompletesWithFileMoveError() async throws {
        let task = session.downloadTask(with: URL(validURL: "https://example.com/file.zip"))
        // URLSession's file is gone, so moving it to a temporary location fails.
        let missingLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        delegate.urlSession(session, downloadTask: task, didFinishDownloadingTo: missingLocation)
        delegate.urlSession(session, task: task, didCompleteWithError: nil)

        var events = spy.events.makeAsyncIterator()
        guard case .completed(let error) = await events.next() else {
            return XCTFail("Expected the task to complete without delivering a downloaded file")
        }
        let moveError = try XCTUnwrap(error as? DownloadedFileMoveError)
        let underlyingError = moveError.underlyingError as NSError
        XCTAssertEqual(underlyingError.domain, NSCocoaErrorDomain)
        XCTAssertEqual(underlyingError.code, CocoaError.fileNoSuchFile.rawValue)
    }

    func testDownloadWhoseFileIsMovedCompletesAfterDeliveringFile() async throws {
        let task = session.downloadTask(with: URL(validURL: "https://example.com/file.zip"))
        let location = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let text = "downloaded"
        try XCTUnwrap(text.data(using: .utf8)).write(to: location)

        delegate.urlSession(session, downloadTask: task, didFinishDownloadingTo: location)
        delegate.urlSession(session, task: task, didCompleteWithError: nil)

        // The spy suspends while handling the file, so a completion that didn't wait for it would arrive first.
        var events = spy.events.makeAsyncIterator()
        guard case .finishedDownloading(let contents) = await events.next() else {
            return XCTFail("Expected the downloaded file before the completion")
        }
        XCTAssertEqual(contents, text)
        guard case .completed(let error) = await events.next() else {
            return XCTFail("Expected the completion after the downloaded file")
        }
        XCTAssertNil(error)
    }

    // MARK: Private

    private var session: URLSession!
    private var spy: NetworkSessionDelegateSpy!
    private var delegate: NetworkSessionToURLSessionDelegate!
}

private final class NetworkSessionDelegateSpy: NetworkSessionDelegate {
    enum Event: Sendable {
        case finishedDownloading(contents: String?)
        case completed(Error?)
    }

    // MARK: Lifecycle

    init() {
        var continuation: AsyncStream<Event>.Continuation!
        events = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    // MARK: Internal

    let events: AsyncStream<Event>

    func networkSession(
        _ session: NetworkSession,
        downloadTask: NetworkSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) async {
    }

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) async {
        // The file is removed once this returns, so read it now.
        let contents = try? String(contentsOf: location, encoding: .utf8)
        // Suspend like a delegate that saves the file, giving other callbacks a chance to run first.
        await Task.megaYield()
        continuation.yield(.finishedDownloading(contents: contents))
    }

    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?) async {
        continuation.yield(.completed(sessionError))
    }

    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) async {
    }

    // MARK: Private

    private let continuation: AsyncStream<Event>.Continuation
}
