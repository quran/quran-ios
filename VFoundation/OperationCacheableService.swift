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

import PromiseKit

open class OperationCacheableService<Input: Hashable, Output>: CacheableService {

    public class func defaultOperationQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "com.operation.operation-cacheable-service"
        return queue
    }

    private let cache: Cache<Input, Output>
    private let queue: OperationQueue

    private var inProgressOperations: [Input: AnyPreloadingOperationRepresentable<Output>] = [:]
    private let lock = NSLock()
    private let operationCreator: AnyCreator<Input, AnyPreloadingOperationRepresentable<Output>>

    public init(queue              : OperationQueue = defaultOperationQueue(),
                cache              : Cache<Input, Output>,
                operationCreator   : AnyCreator<Input, AnyPreloadingOperationRepresentable<Output>>) {
        self.queue              = queue
        self.cache              = cache
        self.operationCreator   = operationCreator
    }

    open func invalidate() {
        lock.synchronized {
            queue.cancelAllOperations()
            inProgressOperations.removeAll()
            cache.removeAllObjects()
        }
    }

    open func get(_ input: Input) -> Guarantee<Output> {
        return lock.synchronized { () -> Guarantee<Output> in

            if let result = cache.object(forKey: input) {
                return Guarantee.value(result)
            } else  if let operation = inProgressOperations[input] {
                return operation.guarantee
            } else {
                // create the operation
                let operation = operationCreator.create(input)
                // add it to the in progress
                inProgressOperations[input] = operation

                // cache the result
                let guarantee = operation.guarantee.map { result -> Output in
                    self.lock.synchronized {
                        self.cache.setObject(result, forKey: input)
                        // remove from in progress
                        self.inProgressOperations.removeValue(forKey: input)
                    }
                    return result
                }
                queue.addOperation(operation.operation)
                return guarantee
            }
        }
    }

    open func getCached(_ input: Input) -> Output? {
        return lock.synchronized {
            return cache.object(forKey: input)
        }
    }
}
