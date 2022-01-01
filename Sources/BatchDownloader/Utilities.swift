//
//  Utilities.swift
//
//
//  Created by Mohamed Afifi on 2021-12-31.
//

import Foundation
import PromiseKit

extension OperationQueue {
    func async<T>(_ namespace: PMKNamespacer, execute body: @escaping () throws -> T) -> Promise<T> {
        Promise(resolver: { resolver in
            addOperation {
                do {
                    resolver.fulfill(try body())
                } catch {
                    resolver.reject(error)
                }
            }
        })
    }

    func async<T>(_ namespace: PMKNamespacer, execute body: @escaping () -> T) -> Guarantee<T> {
        Guarantee { resolver in
            addOperation { resolver(body()) }
        }
    }
}

extension URLSession {
    func getTasks() -> Guarantee<([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])> {
        Guarantee { resolver in
            getTasksWithCompletionHandler { resolver(($0, $1, $2)) }
        }
    }
}
