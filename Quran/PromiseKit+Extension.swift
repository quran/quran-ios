//
//  PromiseKit+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit
import UIKit

extension Promise {

    @discardableResult
    func catchToAlertView(viewController: UIViewController?) -> Promise {
        return self.`catch`(on: .main) { [weak viewController] error in
            viewController?.showErrorAlert(error: error)
        }
    }
}

extension Promise {

    public func cauterize(tag: String?) {
        `catch` { error in
            let message: String
            if let tag = tag {
                message = "PromiseKit: [\(tag)] unhandled error: \(error)"
            } else {
                message = "PromiseKit: unhandled error: \(error)"
            }
            CLog(message)
        }
    }
}

extension URLSession {
    public func getTasks() -> Promise<([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])> {
        return wrap(getTasksWithCompletionHandler)
    }
}

extension OperationQueue {

    func promise<T>(execute body: @escaping () throws -> T) -> Promise<T> {
        return Promise(resolvers: { (fulfill, reject) in
            addOperation {
                do {
                    fulfill(try body())
                } catch {
                    reject(error)
                }
            }
        })
    }
}
