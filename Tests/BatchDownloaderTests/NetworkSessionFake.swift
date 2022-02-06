//
//  NetworkSessionFake.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

@testable import BatchDownloader
import Foundation

final class NetworkSessionFake: NetworkSession {
    let queue: OperationQueue
    let delegate: NetworkSessionDelegate?
    var downloads: [Task] = []
    var dataTasks: [Task] = []

    private var taskIdentifierCounter = 0
    private var taskIdentifier: Int {
        let temp = taskIdentifierCounter
        taskIdentifierCounter += 1
        return temp
    }

    init(queue: OperationQueue, delegate: NetworkSessionDelegate? = nil, downloads: [Task] = []) {
        self.queue = queue
        self.delegate = delegate
        self.downloads = downloads
    }

    func getTasksWithCompletionHandler(_ completionHandler: @escaping ([NetworkSessionDataTask],
                                                                       [NetworkSessionUploadTask],
                                                                       [NetworkSessionDownloadTask]) -> Void)
    {
        queue.addOperation {
            completionHandler([], [], self.downloads)
        }
    }

    func downloadTask(withResumeData resumeData: Data) -> NetworkSessionDownloadTask {
        let task = Task(taskIdentifier: taskIdentifier)
        downloads.append(task)
        task.resumeData = resumeData
        return task
    }

    func downloadTask(with request: URLRequest) -> NetworkSessionDownloadTask {
        let task = Task(taskIdentifier: taskIdentifier)
        task.originalRequest = request
        downloads.append(task)
        return task
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask {
        let task = Task(taskIdentifier: taskIdentifier)
        task.originalRequest = request
        task.completionHandler = completionHandler
        dataTasks.append(task)
        return task
    }

    func completeDownloadTask(_ task: Task, location: URL, totalBytes: Int, progressLoops: Int) {
        let step = Int64(1 / Double(progressLoops) * Double(totalBytes))
        for i in 0 ... progressLoops {
            let written = Int64(Double(i) / Double(progressLoops) * Double(totalBytes))
            queue.addOperation {
                self.delegate?.networkSession(self,
                                              downloadTask: task,
                                              didWriteData: step,
                                              totalBytesWritten: written,
                                              totalBytesExpectedToWrite: Int64(totalBytes))
            }
        }

        queue.addOperation {
            task.response = HTTPURLResponse(url: task.originalRequest!.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            self.delegate?.networkSession(self, downloadTask: task, didFinishDownloadingTo: location)
            self.delegate?.networkSession(self, task: task, didCompleteWithError: nil)
            self.downloads = self.downloads.filter { $0 == task }
        }
    }

    func failDownloadTask(_ task: Task, error: Error) {
        queue.addOperation {
            self.delegate?.networkSession(self, task: task, didCompleteWithError: error)
        }
    }

    func cancelTask(_ task: Task) {
        queue.addOperation {
            self.delegate?.networkSession(self, task: task, didCompleteWithError: URLError(.cancelled))
        }
    }

    func finishBackgroundEvents() {
        queue.addOperation {
            self.delegate?.networkSessionDidFinishEvents(forBackgroundURLSession: self)
        }
    }
}

final class Task: NetworkSessionDownloadTask, NetworkSessionDataTask, Hashable {
    let taskIdentifier: Int
    var originalRequest: URLRequest?
    var currentRequest: URLRequest?
    var response: URLResponse?
    var resumeData: Data?

    var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

    weak var session: NetworkSessionFake?

    init(taskIdentifier: Int) {
        self.taskIdentifier = taskIdentifier
    }

    var isCancelled = false

    func cancel() {
        isCancelled = true
        session?.cancelTask(self)
    }

    func resume() {
        isCancelled = false
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.taskIdentifier == rhs.taskIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(taskIdentifier)
    }
}
