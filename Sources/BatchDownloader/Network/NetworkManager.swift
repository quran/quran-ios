//
//  NetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import PromiseKit

public final class NetworkManager {
    private let session: NetworkSession
    private let baseURL: URL
    public init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    init(session: NetworkSession, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    public func request(_ path: String, parameters: [(String, String)] = []) -> Promise<Data> {
        Promise { resolver in
            Task {
                do {
                    let data = try await request(path, parameters: parameters)
                    resolver.fulfill(data)
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }

    public func request(_ path: String, parameters: [(String, String)] = []) async throws -> Data {
        do {
            let request: URLRequest = Self.request(baseURL: baseURL, path: path, parameters: parameters)
            let (data, _) = try await session.data(for: request)
            return data
        } catch {
            throw NetworkError(error: error)
        }
    }

    static func request(baseURL: URL, path: String, parameters: [(String, String)] = []) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        return URLRequest(url: components.url!)
    }
}

// TODO: Remove PromiseKit
extension Resolver: @unchecked Sendable { }
