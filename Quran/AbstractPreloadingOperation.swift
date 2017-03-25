//
//  AbstractPreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/24/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

class AbstractPreloadingOperation<T>: Operation, PreloadingOperationRepresentable {

    var operation: Operation {
        return self
    }

    private let pending = Promise<T>.pending()
    var promise: Promise<T> {
        return pending.promise
    }

    func reject(_ error: Error) {
        guard !promise.isResolved else {
            return
        }
        pending.reject(error)
    }

    func fulfill(_ value: T) {
        guard !promise.isResolved else {
            return
        }
        pending.fulfill(value)
    }
}
