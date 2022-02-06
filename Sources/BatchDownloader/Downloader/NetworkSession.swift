//
//  NetworkSession.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import Foundation
import PromiseKit

protocol NetworkSession {
    func getTasksWithCompletionHandler(_ completionHandler: @escaping ([NetworkSessionDataTask],
                                                                       [NetworkSessionUploadTask],
                                                                       [NetworkSessionDownloadTask]) -> Void)
    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask
    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask
}

protocol NetworkSessionTask {
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

protocol NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession,
                        downloadTask: NetworkSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64)

    func networkSession(_ session: NetworkSession, downloadTask: NetworkSessionDownloadTask, didFinishDownloadingTo location: URL)
    func networkSession(_ session: NetworkSession, task: NetworkSessionTask, didCompleteWithError sessionError: Error?)

    func networkSessionDidFinishEvents(forBackgroundURLSession session: NetworkSession)
}

extension URLSession: NetworkSession {
    func getTasksWithCompletionHandler(
        _ completionHandler: @escaping ([NetworkSessionDataTask],
                                        [NetworkSessionUploadTask],
                                        [NetworkSessionDownloadTask]) -> Void)
    {
        getTasksWithCompletionHandler { (data: [URLSessionDataTask], uploads, downloads) in
            completionHandler(data, uploads, downloads)
        }
    }

    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask {
        downloadTask(with: request) as URLSessionDownloadTask
    }

    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask {
        downloadTask(withResumeData: resumeData) as URLSessionDownloadTask
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask {
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

final class NetworkSessionToURLSessionDelegate: NSObject, URLSessionDownloadDelegate {
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
        networkSessionDelegate.networkSession(session,
                                              downloadTask: downloadTask,
                                              didWriteData: bytesWritten,
                                              totalBytesWritten: totalBytesWritten,
                                              totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        networkSessionDelegate.networkSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError sessionError: Error?) {
        networkSessionDelegate.networkSession(session, task: task, didCompleteWithError: sessionError)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        networkSessionDelegate.networkSessionDidFinishEvents(forBackgroundURLSession: session)
    }
}
