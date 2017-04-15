//
//  PromiseKit+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
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

    public func cauterize(tag: StaticString?) {
        `catch` { error in
            let message: String
            if let tag = tag {
                message = "PromiseKit: [\(tag)] unhandled error: \(error)"
            } else {
                message = "PromiseKit: unhandled error: \(error)"
            }
            Crash.recordError(error, reason: message)
        }
    }

    public func cauterize(function: StaticString = #function) {
        return cauterize(tag: function)
    }

    public func suppress() {
        return cauterize(tag: "Suppress")
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

extension DispatchQueue {
    public final func promise2<T>(execute body: @escaping () throws -> T) -> Promise<T> {
        return Promise(resolvers: { (fulfill, reject) in
            if self === zalgo || self === waldo && !Thread.isMainThread {
                fulfill(try body())
            } else {
                async {
                    do {
                        fulfill(try body())
                    } catch {
                        reject(error)
                    }
                }
            }
        })
    }
}
