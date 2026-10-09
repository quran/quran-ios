//
//  DownloadBatchResponseTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import BatchDownloaderFake
import XCTest
@testable import BatchDownloader

final class DownloadBatchResponseTests: XCTestCase {
    // MARK: Internal

    func testRestoredBatchWithAllDownloadsCompletedFinishes() async {
        let response = await DownloadBatchResponse(batch: makeBatch(statuses: [.completed, .completed]))

        await assertFinishes(response)
    }

    // MARK: Private

    private func makeBatch(statuses: [Download.Status]) -> DownloadBatch {
        let context = BatchDownloaderFake.makeContext()
        let downloads = statuses.enumerated().map { index, status in
            Download(request: context.makeDownloadRequest("\(index)"), status: status, batchId: 1)
        }
        return DownloadBatch(id: 1, downloads: downloads)
    }

    private func assertFinishes(_ response: DownloadBatchResponse, file: StaticString = #filePath, line: UInt = #line) async {
        let finished = expectation(description: "progress finished")
        let iteration = Task {
            for try await _ in response.progress { }
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 5)
        iteration.cancel()
    }
}
