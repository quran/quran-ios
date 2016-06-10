//
//  SessionDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

private class RequestData: NSObject, NSSecureCoding {

    @objc private static func supportsSecureCoding() -> Bool {
        return true
    }

    let request: NSURLRequest
    let destination: String
    let resumeDataURL: String

    init(request: NSURLRequest, destination: String, resumeDataURL: String) {
        self.request = request
        self.destination = destination
        self.resumeDataURL = resumeDataURL
    }

    @objc required convenience init(coder aDecoder: NSCoder) {
        let request: NSURLRequest = cast(aDecoder.decodeObjectForKey("request"))
        let destination: String = cast(aDecoder.decodeObjectForKey("destination"))
        let resumeDataURL: String = cast(aDecoder.decodeObjectForKey("resumeDataURL"))
        self.init(request: request, destination: destination, resumeDataURL: resumeDataURL)
    }

    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(request, forKey: "request")
        aCoder.encodeObject(destination, forKey: "destination")
        aCoder.encodeObject(resumeDataURL, forKey: "resumeDataURL")
    }
}

class SessionDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate {

    let persistence: SimplePersistence
    private var dataRequests: [NSURLRequest: RequestData]

    var downloadRequests: [NSURLRequest: DownloadNetworkRequest] = [:]

    var backgroundSessionCompletionHandler: (() -> Void)?

    init(persistence: SimplePersistence) {
        self.persistence = persistence

        // initialize requests
        if let data = persistence.valueForKey(.DownloadRequests) {
            dataRequests = cast(NSKeyedUnarchiver.unarchiveObjectWithData(data))
        } else {
            dataRequests = [:]
        }
    }

    var isDownloading: Bool {
        return !dataRequests.isEmpty
    }

    func addRequestsData(requests: [(NSURLRequest, DownloadNetworkRequest)]) {
        for (request, downloadRequest) in requests {
            dataRequests[request] = RequestData(request: request,
                                                destination: downloadRequest.destination,
                                                resumeDataURL: downloadRequest.resumeDestination)
            addRequest(request, downloadRequest: downloadRequest)
        }
        updatePersistence()
    }

    func addRequest(request: NSURLRequest, downloadRequest: DownloadNetworkRequest) {
        downloadRequests[request] = downloadRequest
    }

    func getRequestDataForRequest(request: NSURLRequest) -> (destination: String, resumeData: String)? {
        if let requestData = dataRequests[request] {
            return (destination: requestData.destination, resumeData: requestData.resumeDataURL)
        }
        return nil
    }

    private func removeRequest(request: NSURLRequest) -> (RequestData?, DownloadNetworkRequest?) {
        let requestData = dataRequests.removeValueForKey(request)
        let downloadRequest = downloadRequests.removeValueForKey(request)

        updatePersistence()
        return (requestData, downloadRequest)
    }

    private func updatePersistence() {
        let encodedData: NSData? = NSKeyedArchiver.archivedDataWithRootObject(dataRequests)
        persistence.setValue(encodedData, forKey: .DownloadRequests)
    }

    func URLSession(session: NSURLSession,
                    downloadTask: NSURLSessionDownloadTask,
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

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        guard let request = downloadTask.originalRequest else {
            return
        }
        // move the file to the correct location
        if let requestData = dataRequests[request] {
            let fileManager = NSFileManager.defaultManager()

            let resumeURL = Files.DocumentsFolder.URLByAppendingPathComponent(requestData.resumeDataURL)
            let destinationURL = Files.DocumentsFolder.URLByAppendingPathComponent(requestData.destination)

            // remove the resume data
            let _ = try? fileManager.removeItemAtURL(resumeURL)
            // remove the existing file if exist.
            let _ = try? fileManager.removeItemAtURL(destinationURL)

            // move the file to destination
            do {
                if let directory = destinationURL.URLByDeletingLastPathComponent {
                    // ignore errors
                    let _ = try? fileManager.createDirectoryAtURL(directory,
                                                                  withIntermediateDirectories: true,
                                                                  attributes: nil)
                }
                try fileManager.copyItemAtURL(location, toURL: destinationURL)
            } catch let error {
                Crash.recordError(error)
                // early exist with error
                let (_, downloadRequest) = removeRequest(request)
                downloadRequest?.onCompletion?(.Failure(FileSystemError(error: error)))
            }
        } else {
            print("Missked saving task", downloadTask.currentRequest?.URL)
        }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

        guard let request = task.originalRequest else {
            return
        }

        // remove the request
        let (requestData, downloadRequest) = removeRequest(request)

        if let error = error {
            print("Network error occurred: \(error)")

            // save resume data, if found
            if let resumePath = requestData?.resumeDataURL, let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
                let resumeURL = Files.DocumentsFolder.URLByAppendingPathComponent(resumePath)
                resumeData.writeToURL(resumeURL, atomically: true)
            }

            if error as? NSURLError != NSURLError.Cancelled { // not cancelled by user
                let finalError: ErrorType
                if error is POSIXError && Int32(error.code) == ENOENT {
                    finalError = FileSystemError.NoDiskSpace
                } else {
                    finalError = NetworkError(error: error)
                }
                downloadRequest?.onCompletion?(.Failure(finalError))
            }
        } else {
            // success
            downloadRequest?.onCompletion?(.Success())
        }
    }

    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let handler = backgroundSessionCompletionHandler
        backgroundSessionCompletionHandler = nil
        handler?()
    }

    private func createDirectoryForPath(path: NSURL) {
        if let directory = path.URLByDeletingLastPathComponent {
            // ignore errors
            let _ = try? NSFileManager.defaultManager().createDirectoryAtURL(directory,
                                                                             withIntermediateDirectories: true,
                                                                             attributes: nil)
        }
    }
}
