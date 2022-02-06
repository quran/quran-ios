//
//  NetworkManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-05.
//

@testable import BatchDownloader
import XCTest

class NetworkManagerTests: XCTestCase {
    private var networkManager: NetworkManager!
    private var session: NetworkSessionFake!
    private let baseURL = URL(validURL: "http://example.com")

    override func setUpWithError() throws {
        session = NetworkSessionFake(queue: .main, delegate: nil)
        networkManager = NetworkManager(session: session, baseURL: baseURL)
    }

    func testRequestCompletedSuccessfully() throws {
        let promise = networkManager.request("v1/products", parameters: [("sort", "newest")])

        let body = "product1"
        let response = URLResponse()

        let task = try XCTUnwrap(session.dataTasks.first)
        XCTAssertEqual(task.originalRequest?.url?.absoluteString, "http://example.com/v1/products?sort=newest")

        session.dataTasks.first?.completionHandler?(body.data(using: .utf8), response, nil)

        let result = try wait(for: promise)
        XCTAssertEqual(String(data: result, encoding: .utf8), body)
    }

    func testRequestFailure() throws {
        let promise = networkManager.request("v1/products", parameters: [("sort", "newest")])
        let task = try XCTUnwrap(session.dataTasks.first)
        XCTAssertEqual(task.originalRequest?.url?.absoluteString, "http://example.com/v1/products?sort=newest")

        session.dataTasks.first?.completionHandler?(nil, nil, FileSystemError(error: CocoaError(.coderReadCorrupt)))

        assert(
            try wait(for: promise),
            throws: NetworkError.unknown(FileSystemError.unknown(CocoaError(.fileWriteOutOfSpace))) as NSError
        )
    }
}
