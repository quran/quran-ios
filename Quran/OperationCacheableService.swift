//
//  OperationCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/28/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

private func operationQueue() -> OperationQueue {
    let queue = OperationQueue()
    queue.name = "com.operation.operation-cacheable-service"
    return queue
}

class OperationCacheableService<Input: Hashable, Output>: CacheableService {

    private let cache: Cache<Input, Output>
    private let queue: OperationQueue

    private var inProgressOperations: [Input: AnyPreloadingOperationRepresentable<Output>] = [:]
    private let lock = NSLock()
    private let operationCreator: AnyCreator<AnyPreloadingOperationRepresentable<Output>, Input>

    init(queue              : OperationQueue = operationQueue(),
         cache              : Cache<Input, Output>,
         operationCreator   : AnyCreator<AnyPreloadingOperationRepresentable<Output>, Input>) {
        self.queue              = queue
        self.cache              = cache
        self.operationCreator   = operationCreator
    }

    func invalidate() {
        lock.execute {
            queue.cancelAllOperations()
            inProgressOperations.removeAll()
            cache.removeAllObjects()
        }
    }

    func get(_ input: Input) -> Promise<Output> {
        return lock.execute { () -> Promise<Output> in

            if let result = cache.object(forKey: input) {
//                print("already cached: \(input)")
                return Promise(value: result)
            } else  if let operation = inProgressOperations[input] {
//                print("queuing: \(input)")
                return operation.promise
            } else {
//                print("requesting: \(input)")

                // create the operation
                let operation = operationCreator.create(input)
                // add it to the in progress
                inProgressOperations[input] = operation

                // cache the result
                let promise = operation.promise
                    .then(on: .global()) { result -> Output in
                        self.lock.execute {
                            self.cache.setObject(result, forKey: input)
                            // remove from in progress
                            self.inProgressOperations.removeValue(forKey: input)
                        }
//                        print("retrieved: \(input)")
                        return result
                }
                queue.addOperation(operation.operation)
                return promise
            }
        }
    }

    func getCached(_ input: Input) -> Output? {
        return lock.execute {
            return cache.object(forKey: input)
        }
    }
}
