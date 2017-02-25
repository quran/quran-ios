//
//  NetworkResponse.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import Moya

class NetworkResponse<Value> {

    let cancellable: Cancellable

    let progress: Foundation.Progress

    var result: Result<Value>? {
        didSet {
            if let result = result {
                onCompletion?(result)
            }
        }
    }

    var onCompletion: ((Result<Value>) -> Void)? {
        didSet {
            if let result = result {
                onCompletion?(result)
            }
        }
    }

    init(cancellable: Cancellable, progress: Foundation.Progress) {
        self.cancellable = cancellable
        self.progress = progress
    }

    func cancel() {
        cancellable.cancel()
    }

    var isCancelled: Bool {
        return cancellable.isCancelled
    }
}
