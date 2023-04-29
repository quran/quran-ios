//
//  DownloadingObserverCollectionTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-02.
//

@testable import BatchDownloader
import XCTest
import TestUtilities

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

    func testStartingDownloadCompletedSuccessfully() async {
        XCTAssertEqual(recorder.diffSinceLastCalled, [])

        // prepare response
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.updateProgress(total: 1)

        // start downloading
        await observers.observe([item1, item2, item3], responses: [:])
        await observers.startDownloading(item: item2, response: response)
        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
            .progress(item2, 1, 0.0),
        ])

        response.updateProgress(completed: 0.5)
        response.updateProgress(completed: 1)
        await Task.megaYield()

        // get 50% then 100%
        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .progress(item2, 1, 0.5),
            .progress(item2, 1, 1.0),
        ])

        response.fulfill()
        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .completed(item2, 1),
        ])
    }

    func testStartingDownloadFailedToComplete() async {
        // start downloading and immediately fail it
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.updateProgress(total: 1)
        await observers.observe([item1, item2, item3], responses: [:])
        await observers.startDownloading(item: item3, response: response)
        response.reject(FileSystemError(error: CocoaError(.fileWriteOutOfSpace)))

        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
            .progress(item3, 2, 0),

            // failed
            .itemsUpdated([item1, item2, item3]),
            .failed(item3, 2, FileSystemError.noDiskSpace as NSError),
        ])
    }

    func testObserveMethod() async {
        let response1 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response2 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response3 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        for response in [response1, response2, response3] {
            response.updateProgress(total: 1)
        }

        await observers.observe([item1, item2, item3], responses: [
            item1: response1,
            item2: response2,
            item3: response3,
        ])

        await Task.megaYield()

        XCTAssertEqual(Set(recorder.diffSinceLastCalled), [
            .itemsUpdated([item1, item2, item3]),
            .progress(item1, 0, 0),
            .progress(item2, 1, 0),
            .progress(item3, 2, 0),
        ])
    }

    func testStopDownloading() async {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.updateProgress(total: 1)

        await observers.observe([item1, item2, item3], responses: [item1: response])
        await observers.stopDownloading(item1)
        await observers.stopDownloading(item2)
        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
            .itemsUpdated([item1, item2, item3]),
            .itemsUpdated([item1, item2, item3]),
        ])

        // if promise fulfilled, we don't get notified
        response.fulfill()
        await Task.megaYield()

        XCTAssertTrue(recorder.diffSinceLastCalled.isEmpty)
    }

    func testStopDownloadingThenRedownloading() async {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.updateProgress(total: 1)
        await observers.observe([item1, item2, item3], responses: [item1: response])
        await observers.stopDownloading(item1)
        observers.preparingDownloading(item1)
        await observers.startDownloading(item: item1, response: response)
        response.fulfill()
        await Task.megaYield()

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

    func testCantRestartDownloadImmediately() async {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.updateProgress(total: 1)
        await observers.observe([item1, item2, item3], responses: [item1: response])
        await observers.stopDownloading(item1)
        await observers.startDownloading(item: item1, response: response)

        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
            .itemsUpdated([item1, item2, item3]),
            .cancel(response: response),
        ])
    }

    func testRemoveAllResponses() async {
        let response1 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response2 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        let response3 = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        for response in [response1, response2, response3] {
            response.updateProgress(total: 1)
        }
        await observers.observe([item1, item2, item3], responses: [
            item1: response1,
            item2: response2,
            item3: response3,
        ])
        // start the diff now
        _ = recorder.diffSinceLastCalled

        await observers.removeAll()
        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [
            .itemsUpdated([]),
        ])

        response1.fulfill()
        await Task.megaYield()

        XCTAssertEqual(recorder.diffSinceLastCalled, [])
    }
}
