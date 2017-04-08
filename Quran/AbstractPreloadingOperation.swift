//
//  AbstractPreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/24/17.
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
