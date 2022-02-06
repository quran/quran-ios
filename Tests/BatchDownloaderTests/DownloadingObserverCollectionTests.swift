//
//  DownloadingObserverCollectionTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-02.
//

@testable import BatchDownloader
import XCTest

class DownloadingObserverCollectionTests: XCTestCase {
    private var observers: DownloadingObserverCollection<AudioDownload>!
    private var recorder: DownloadObserversRecorder<AudioDownload>!

    private let item1 = AudioDownload(name: "item1")
    private let item2 = AudioDownload(name: "item2")
    private let item3 = AudioDownload(name: "item3")

    override func setUpWithError() throws {
        observers = DownloadingObserverCollection()
        recorder = DownloadObserversRecorder(observer: observers)
    }

    private func waitForProgressUpdates() {
        // wait for the main thread dispatch async as completion is called on main thread
        wait(for: DispatchQueue.main)
    }

    func testStartingDownloadCompletedSuccessfully() {
        XCTAssertEqual(recorder.diffSinceLastCalled, [])

        // prepare response
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.progress.totalUnitCount = 1
        // start downloading
        observers.observe([item1, item2, item3], responses: [:])
        observers.startDownloading(item: item2, response: response)

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
        ])

        waitForProgressUpdates()

        // at the start, we get 0%
        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .progress(item2, 1, 0),
        ])

        response.progress.completedUnitCount = 0.5
        response.progress.completedUnitCount = 1
        waitForProgressUpdates()

        // get 50% then 100%
        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .progress(item2, 1, 0.5),
            .progress(item2, 1, 1.0),
        ])

        response.fulfill()
        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .completed(item2, 1),
        ])
    }

    func testStartingDownloadFailedToComplete() {
        // start downloading and immediately fail it
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.progress.totalUnitCount = 1
        observers.observe([item1, item2, item3], responses: [:])
        observers.startDownloading(item: item3, response: response)
        response.reject(FileSystemError(error: CocoaError(.fileWriteOutOfSpace)))

        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
            .progress(item3, 2, 0),

            // failed
            .itemsUpdated([item1, item2, item3]),
            .failed(item3, 2, FileSystemError.noDiskSpace as NSError),
        ])
    }

    func testObserveMethod() {
        let response1 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response2 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response3 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        for response in [response1, response2, response3] {
            response.progress.totalUnitCount = 1
        }

        observers.observe([item1, item2, item3], responses: [
            item1: response1,
            item2: response2,
            item3: response3,
        ])
        waitForProgressUpdates()

        XCTAssertEqual(Set(recorder.diffSinceLastCalled), [
            .itemsUpdated([item1, item2, item3]),
            .progress(item1, 0, 0),
            .progress(item2, 1, 0),
            .progress(item3, 2, 0),
        ])
    }

    func testStopDownloading() {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.progress.totalUnitCount = 1
        observers.observe([item1, item2, item3], responses: [item1: response])
        observers.stopDownloading(item1)
        observers.stopDownloading(item2)
        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
        ])

        // if promise fulfilled, we don't get notified
        response.fulfill()
        waitForProgressUpdates()
        XCTAssertTrue(recorder.diffSinceLastCalled.isEmpty)
    }

    func testStopDownloadingThenRedownloading() {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.progress.totalUnitCount = 1
        observers.observe([item1, item2, item3], responses: [item1: response])
        observers.stopDownloading(item1)
        observers.preparingDownloading(item1)
        observers.startDownloading(item: item1, response: response)
        response.fulfill()
        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
            .progress(item1, 0, 0),

            // completed
            .itemsUpdated([item1, item2, item3]),
            .completed(item1, 0),
        ])
    }

    func testCantRestartDownloadImmediately() {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.progress.totalUnitCount = 1
        observers.observe([item1, item2, item3], responses: [item1: response])
        observers.stopDownloading(item1)
        observers.startDownloading(item: item1, response: response)
        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
        ])
    }

    func testRemoveAllResponses() {
        let response1 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response2 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response3 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        for response in [response1, response2, response3] {
            response.progress.totalUnitCount = 1
        }
        observers.observe([item1, item2, item3], responses: [
            item1: response1,
            item2: response2,
            item3: response3,
        ])
        waitForProgressUpdates()
        // start the diff now
        _ = recorder.diffSinceLastCalled

        observers.removeAll()
        waitForProgressUpdates()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([]),
        ])

        response1.fulfill()

        XCTAssertEqual(recorder.diffSinceLastCalled, [])
    }
}
