//
//  NetworkSession.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import Crashing
import Foundation

protocol NetworkSession: Sendable {
    var delegateQueue: OperationQueue { get }
    func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask])
    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask
    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask
    func dataTask(with request: URLRequest, completionHandler: @Sendable @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

protocol NetworkSessionTask: AnyObject, Sendable {
    var taskIdentifier: Int { get }
    var originalRequest: URLRequest? { get }
    var currentRequest: URLRequest? { get }
    var response: URLResponse? { get }
    func cancel()
    func resume()
}

protocol NetworkSessionDownloadTask: NetworkSessionTask {
}

protocol NetworkSessionUploadTask: NetworkSessionTask {
}

protocol NetworkSessionDataTask: NetworkSessionTask {
}

protocol NetworkSessionDelegate: Sendable {
    func networkSession(_ session: NetworkSession,
                        downloadTask: NetworkSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) async

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL) async
    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?) async

    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession) async
}

extension URLSession: NetworkSession {
    func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask]) {
        await tasks
    }

    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask {
        downloadTask(with: request) as URLSessionDownloadTask
    }

    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask {
        downloadTask(withResumeData: resumeData) as URLSessionDownloadTask
    }

    func dataTask(with request: URLRequest, completionHandler: @Sendable @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask {
        dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
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

final class NetworkSessionToURLSessionDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    let networkSessionDelegate: NetworkSessionDelegate
    init(networkSessionDelegate: NetworkSessionDelegate) {
        self.networkSessionDelegate = networkSessionDelegate
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64)
    {
        Task {
            await networkSessionDelegate.networkSession(session,
                                                        downloadTask: downloadTask,
                                                        didWriteData: bytesWritten,
                                                        totalBytesWritten: totalBytesWritten,
                                                        totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let filePath = UUID().uuidString
        let temporaryFile = temporaryDirectory.appendingPathComponent(filePath)
        do {
            // Move the file to a temporary location as URLSession would delete it before the async task starts.
            try FileManager.default.moveItem(at: location, to: temporaryFile)
            Task {
                await networkSessionDelegate.networkSession(session, downloadTask: downloadTask, didFinishDownloadingTo: temporaryFile)
                try? FileManager.default.removeItem(at: temporaryFile)
            }
        } catch {
            crasher.recordError(
                error,
                reason: "Problem moving the downloaded file to a temporary location '\(temporaryFile)'"
            )
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {
        Task {
            await networkSessionDelegate.networkSession(session, task: task, didCompleteWithError: sessionError)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task {
            await networkSessionDelegate.networkSessionDidFinishEvents(forBackgroundURLSession: session)
        }
    }
}
