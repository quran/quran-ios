//
//  NetworkResponse.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
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
