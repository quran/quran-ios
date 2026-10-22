//
//  NetworkSession.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import Crashing
import Foundation
import Utilities

public protocol NetworkSession: AnyObject, Sendable {
    var delegateQueue: OperationQueue { get }
    func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask])
    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask
    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public protocol NetworkSessionTask: AnyObject, Sendable {
    var taskIdentifier: Int { get }
    var originalRequest: URLRequest? { get }
    var currentRequest: URLRequest? { get }
    var response: URLResponse? { get }
    func cancel()
    func resume()
}

public protocol NetworkSessionDownloadTask: NetworkSessionTask {
}

public protocol NetworkSessionUploadTask: NetworkSessionTask {
}

public protocol NetworkSessionDataTask: NetworkSessionTask {
}

public protocol NetworkSessionDelegate: Sendable {
    func networkSession(
        _ session: NetworkSession,
        downloadTask: NetworkSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) async

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) async
    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?) async

    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) async
}

extension URLSession: NetworkSession {
    public func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask]) {
        await tasks
    }

    public func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask {
        downloadTask(with: request) as URLSessionDownloadTask
    }

    public func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask {
        downloadTask(withResumeData: resumeData) as URLSessionDownloadTask
    }
}

extension URLSessionTask: NetworkSessionTask {
}

extension URLSessionDownloadTask: NetworkSessionDownloadTask {
}

extension URLSessionUploadTask: NetworkSessionUploadTask {
}

extension URLSessionDataTask: NetworkSessionDataTask {
}

/// A download task's transfer succeeded, but its downloaded file couldn't be kept for the delegate.
///
/// `NetworkSessionToURLSessionDelegate` records `underlyingError`, then completes such a task with this
/// error instead of `nil`, so the download fails rather than completing without its file.
public struct DownloadedFileMoveError: Error {
    // MARK: Lifecycle

    public init(underlyingError: Error) {
        self.underlyingError = underlyingError
    }

    // MARK: Public

    public let underlyingError: Error
}

/// Forwards URLSession's callbacks to a `NetworkSessionDelegate`, each in its own task.
///
/// A download task's completion reaches the delegate only after the delegate handled its downloaded file.
public final class NetworkSessionToURLSessionDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    // MARK: Lifecycle

    public init(networkSessionDelegate: NetworkSessionDelegate) {
        self.networkSessionDelegate = networkSessionDelegate
    }

    // MARK: Public

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task {
            await networkSessionDelegate.networkSession(
                session,
                downloadTask: downloadTask,
                didWriteData: bytesWritten,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let filePath = UUID().uuidString
        let temporaryFile = temporaryDirectory.appendingPathComponent(filePath)
        let delivery: Task<Error?, Never>
        do {
            // Move the file to a temporary location as URLSession would delete it before the async task starts.
            try FileManager.default.moveItem(at: location, to: temporaryFile)
            delivery = Task {
                await networkSessionDelegate.networkSession(session, downloadTask: downloadTask, didFinishDownloadingTo: temporaryFile)
                try? FileManager.default.removeItem(at: temporaryFile)
                return nil
            }
        } catch {
            crasher.recordError(
                error,
                reason: "Problem moving the downloaded file to a temporary location '\(temporaryFile)'"
            )
            delivery = Task { error }
        }
        // URLSession calls didCompleteWithError next, which waits for this delivery.
        deliveries.withCriticalRegion { $0[downloadTask.taskIdentifier] = delivery }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {
        let delivery = deliveries.withCriticalRegion { $0.removeValue(forKey: task.taskIdentifier) }
        Task {
            // The delegate must have the file before it learns the task completed.
            let fileMoveError = await delivery?.value
            let error = sessionError ?? fileMoveError.map(DownloadedFileMoveError.init)
            await networkSessionDelegate.networkSession(session, task: task, didCompleteWithError: error)
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task {
            await networkSessionDelegate.networkSessionDidFinishEvents(forBackgroundURLSession: session)
        }
    }

    // MARK: Internal

    let networkSessionDelegate: NetworkSessionDelegate

    // MARK: Private

    /// The pending deliveries of downloaded files, by task identifier, until their tasks complete.
    ///
    /// Each delivery finishes once the delegate handled the file, or with the error that kept the file from it.
    private let deliveries = ManagedCriticalState<[Int: Task<Error?, Never>]>([:])
}
