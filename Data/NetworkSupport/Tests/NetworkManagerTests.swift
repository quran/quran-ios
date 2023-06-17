//
//  NetworkManagerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-05.
//

import AsyncUtilitiesForTesting
import NetworkSupportFake
import Utilities
import XCTest
@testable import NetworkSupport

class NetworkManagerTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        session = NetworkSessionFake(queue: .main, delegate: nil)
        networkManager = NetworkManager(session: session, baseURL: baseURL)
    }

    func testRequestCompletedSuccessfully() async throws {
        let path = "v1/products"
        let parameters = [("sort", "newest")]
        let request = NetworkManager.request(baseURL: baseURL, path: path, parameters: parameters)
        let body = "product1"
        session.dataResults[request.url!] = .success(body.data(using: .utf8)!)

        let result = try await networkManager.request(path, parameters: parameters)
        XCTAssertEqual(String(data: result, encoding: .utf8), body)
    }

    func testRequestFailure() async throws {
        let path = "v1/products"
        let parameters = [("sort", "newest")]
        let request = NetworkManager.request(baseURL: baseURL, path: path, parameters: parameters)
        let error = CocoaError(.coderReadCorrupt)
        session.dataResults[request.url!] = .failure(error)

        let result = await Result { try await networkManager.request(path, parameters: parameters) }

        assert(
            try result.get(),
            throws: NetworkError.unknown(error) as NSError
        )
    }

    // MARK: Private

    private var networkManager: NetworkManager!
    private var session: NetworkSessionFake!
    private let baseURL = URL(validURL: "http://example.com")
}
