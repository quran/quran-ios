//
//  NetworkManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-05.
//

@testable import BatchDownloader
import TestUtilities
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
        let path = "v1/products"
        let parameters = [("sort", "newest")]
        let request = NetworkManager.request(baseURL: baseURL, path: path, parameters: parameters)
        let body = "product1"
        session.dataResults[request.url!] = .success(body.data(using: .utf8)!)

        let result = try wait(for: networkManager.request(path, parameters: parameters))
        XCTAssertEqual(String(data: result, encoding: .utf8), body)
    }

    func testRequestFailure() throws {
        let path = "v1/products"
        let parameters = [("sort", "newest")]
        let request = NetworkManager.request(baseURL: baseURL, path: path, parameters: parameters)
        let error = FileSystemError(error: CocoaError(.coderReadCorrupt))
        session.dataResults[request.url!] = .failure(error)

        let promise = networkManager.request(path, parameters: parameters)

        assert(
            try wait(for: promise),
            throws: NetworkError.unknown(error) as NSError
        )
    }
}
