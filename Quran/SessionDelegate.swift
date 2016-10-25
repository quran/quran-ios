//
//  SessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

private class RequestData: NSObject, NSSecureCoding {

    @objc fileprivate static var supportsSecureCoding: Bool {
        return true
    }

    let request: URLRequest
    let destination: String
    let resumeDataURL: String

    init(request: URLRequest, destination: String, resumeDataURL: String) {
        self.request = request
        self.destination = destination
        self.resumeDataURL = resumeDataURL
    }

    @objc required convenience init(coder aDecoder: NSCoder) {
        let request: URLRequest = cast(aDecoder.decodeObject(forKey: "request"))
        let destination: String = cast(aDecoder.decodeObject(forKey: "destination"))
        let resumeDataURL: String = cast(aDecoder.decodeObject(forKey: "resumeDataURL"))
        self.init(request: request, destination: destination, resumeDataURL: resumeDataURL)
    }

    @objc func encode(with aCoder: NSCoder) {
        aCoder.encode(request, forKey: "request")
        aCoder.encode(destination, forKey: "destination")
        aCoder.encode(resumeDataURL, forKey: "resumeDataURL")
    }
}

class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {

    let persistence: SimplePersistence
    fileprivate var dataRequests: [URLRequest: RequestData]

    var downloadRequests: [URLRequest: DownloadNetworkRequest] = [:]

    var backgroundSessionCompletionHandler: (() -> Void)?

    init(persistence: SimplePersistence) {
        self.persistence = persistence

        // initialize requests
        if let data = persistence.valueForKey(.DownloadRequests) {
            dataRequests = cast(NSKeyedUnarchiver.unarchiveObject(with: data))
        } else {
            dataRequests = [:]
        }
    }

    var isDownloading: Bool {
        return !dataRequests.isEmpty
    }

    func addRequestsData(_ requests: [(URLRequest, DownloadNetworkRequest)]) {
        for (request, downloadRequest) in requests {
            dataRequests[request] = RequestData(request: request,
                                                destination: downloadRequest.destination,
                                                resumeDataURL: downloadRequest.resumeDestination)
            addRequest(request, downloadRequest: downloadRequest)
        }
        updatePersistence()
    }

    func addRequest(_ request: URLRequest, downloadRequest: DownloadNetworkRequest) {
        downloadRequests[request] = downloadRequest
    }

    func getRequestDataForRequest(_ request: URLRequest) -> (destination: String, resumeData: String)? {
        if let requestData = dataRequests[request] {
            return (destination: requestData.destination, resumeData: requestData.resumeDataURL)
        }
        return nil
    }

    fileprivate func removeRequest(_ request: URLRequest) -> (RequestData?, DownloadNetworkRequest?) {
        let requestData = dataRequests.removeValue(forKey: request)
        let downloadRequest = downloadRequests.removeValue(forKey: request)

        updatePersistence()
        return (requestData, downloadRequest)
    }

    fileprivate func updatePersistence() {
        let encodedData: Data? = NSKeyedArchiver.archivedData(withRootObject: dataRequests)
        persistence.setValue(encodedData, forKey: .DownloadRequests)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard let request = downloadTask.originalRequest else {
            return
        }

        guard let downloadRequest = downloadRequests[request] else {
            return
        }
        downloadRequest.progress.totalUnitCount = totalBytesExpectedToWrite
        downloadRequest.progress.completedUnitCount = totalBytesWritten
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard let request = downloadTask.originalRequest else {
            return
        }
        // move the file to the correct location
        if let requestData = dataRequests[request] {
            let fileManager = FileManager.default

            let resumeURL = Files.DocumentsFolder.appendingPathComponent(requestData.resumeDataURL)
            let destinationURL = Files.DocumentsFolder.appendingPathComponent(requestData.destination)

            // remove the resume data
            let _ = try? fileManager.removeItem(at: resumeURL)
            // remove the existing file if exist.
            let _ = try? fileManager.removeItem(at: destinationURL)

            // move the file to destination
            do {
                let directory = destinationURL.deletingLastPathComponent()
                let _ = try? fileManager.createDirectory(at: directory,
                                withIntermediateDirectories: true,
                                                 attributes: nil)
                try fileManager.copyItem(at: location, to: destinationURL)
            } catch let error {
                Crash.recordError(error)
                // early exist with error
                let (_, downloadRequest) = removeRequest(request)
                downloadRequest?.onCompletion?(.failure(FileSystemError(error: error)))
            }
        } else {
            print("Missed saving task", downloadTask.currentRequest?.url)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let request = task.originalRequest else {
            return
        }

        // remove the request
        let (requestData, downloadRequest) = removeRequest(request)

        if let error = error {
            print("Network error occurred: \(error)")

            // save resume data, if found
            if let resumePath = requestData?.resumeDataURL, let resumeData =
                (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                let resumeURL = Files.DocumentsFolder.appendingPathComponent(resumePath)
                try? resumeData.write(to: resumeURL, options: [.atomic])
            }

            if ((error as? URLError)?.code) != URLError.cancelled { // not cancelled by user
                let finalError: Error
                if error is POSIXErrorCode && Int32((error as NSError).code) == ENOENT {
                    finalError = FileSystemError.noDiskSpace
                } else {
                    finalError = NetworkError(error: error)
                }
                downloadRequest?.onCompletion?(.failure(finalError))
            }
        } else {
            // success
            downloadRequest?.onCompletion?(.success())
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    fileprivate func createDirectoryForPath(_ path: Foundation.URL) {
        let directory = path.deletingLastPathComponent()
        // ignore errors
        let _ = try? FileManager.default.createDirectory(at: directory,
                                withIntermediateDirectories: true,
                                                 attributes: nil)
    }
}
