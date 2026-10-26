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

/// `NetworkSessionToURLSessionDelegate` delivers these callbacks one at a time in URLSession's order, so each must return
/// promptly and never await something only a later callback brings (like a cancelled task's completion): that would
/// block every later callback, including the end of background events.
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

/// Forwards URLSession's callbacks to a `NetworkSessionDelegate`, one at a time in the order URLSession delivered them.
///
/// A download task's completion reaches the delegate only after the delegate handled its downloaded file, and the end of a
/// background session's events reaches it only after it handled every callback delivered before, so the app isn't
/// suspended before it saved them. This covers the work the delegate awaits in each callback, not unstructured work
/// it starts.
public final class NetworkSessionToURLSessionDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    // MARK: Lifecycle

    public init(networkSessionDelegate: NetworkSessionDelegate) {
        self.networkSessionDelegate = networkSessionDelegate
        let (callbacks, continuation) = AsyncStream.makeStream(of: Callback.self)
        self.callbacks = continuation
        Task {
            for await callback in callbacks {
                await callback()
            }
        }
    }

    deinit {
        // The worker still delivers the callbacks it received, then ends.
        callbacks.finish()
    }

    // MARK: Public

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let networkSessionDelegate = networkSessionDelegate
        callbacks.yield {
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
        do {
            // Move the file to a temporary location as URLSession deletes it once this method returns.
            try FileManager.default.moveItem(at: location, to: temporaryFile)
        } catch {
            crasher.recordError(
                error,
                reason: "Problem moving the downloaded file to a temporary location '\(temporaryFile)'"
            )
            // URLSession calls didCompleteWithError next, which reports this error.
            fileMoveErrors.withCriticalRegion { $0[downloadTask.taskIdentifier] = error }
            return
        }
        let networkSessionDelegate = networkSessionDelegate
        callbacks.yield {
            await networkSessionDelegate.networkSession(session, downloadTask: downloadTask, didFinishDownloadingTo: temporaryFile)
            try? FileManager.default.removeItem(at: temporaryFile)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {
        let fileMoveError = fileMoveErrors.withCriticalRegion { $0.removeValue(forKey: task.taskIdentifier) }
        let error = sessionError ?? fileMoveError.map(DownloadedFileMoveError.init)
        let networkSessionDelegate = networkSessionDelegate
        callbacks.yield {
            await networkSessionDelegate.networkSession(session, task: task, didCompleteWithError: error)
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let networkSessionDelegate = networkSessionDelegate
        callbacks.yield {
            await networkSessionDelegate.networkSessionDidFinishEvents(forBackgroundURLSession: session)
        }
    }

    // MARK: Internal

    let networkSessionDelegate: NetworkSessionDelegate

    // MARK: Private

    private typealias Callback = @Sendable () async -> Void

    /// Feeds the worker that forwards each callback to the delegate after the previous one finished.
    private let callbacks: AsyncStream<Callback>.Continuation

    /// The errors that kept downloaded files from the delegate, by task identifier, until their tasks complete.
    private let fileMoveErrors = ManagedCriticalState<[Int: Error]>([:])
}
