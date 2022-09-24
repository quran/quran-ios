//
//  OperationCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/28/17.
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
import Locking
import PromiseKit

class OperationCacheableService<Input: Hashable, Output> {
    private let cache: Cache<Input, Output>

    private var inProgressOperations: [Input: Promise<Output>] = [:]
    private let lock = NSLock()
    private let operation: (Input) -> Promise<Output>

    init(cache: Cache<Input, Output>, operation: @escaping (Input) -> Promise<Output>) {
        self.cache = cache
        self.operation = operation
    }

    func invalidate() {
        lock.sync {
            inProgressOperations.removeAll()
            cache.removeAllObjects()
        }
    }

    func get(_ input: Input) -> Promise<Output> {
        lock.sync { () -> Promise<Output> in

            if let result = cache.object(forKey: input) {
                return Promise.value(result)
            } else if let promise = inProgressOperations[input] {
                return promise
            } else {
                // create the operation
                let operationPromise = operation(input)
                // add it to the in progress
                inProgressOperations[input] = operationPromise

                // cache the result
                let promise = operationPromise.map { result -> Output in
                    self.lock.sync {
                        self.cache.setObject(result, forKey: input)
                        // remove from in progress
                        self.inProgressOperations.removeValue(forKey: input)
                    }
                    return result
                }
                return promise
            }
        }
    }

    func getCached(_ input: Input) -> Output? {
        lock.sync {
            cache.object(forKey: input)
        }
    }
}
