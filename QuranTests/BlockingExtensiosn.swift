//
//  BlockingExtensiosn.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

private let defaultTimeout: TimeInterval = 10

extension Promise {
    func wait(timeout: TimeInterval = defaultTimeout) throws -> T {
        let lock = RunLoopLock(timeout: timeout)

        var result: Result<T>!
        lock.dispatch {
            self.tap { r in
                result = r
                lock.stop()
            }
        }

        try lock.run()

        switch result! {
        case .fulfilled(let value):
            return value
        case .rejected(let error):
            throw error
        }
    }
}

extension URLSession {
    func syncDataTask(with url: URL, timeout: TimeInterval = defaultTimeout) throws -> Data {
        let lock = RunLoopLock(timeout: timeout)

        var data: Data!
        var error: Error!

        lock.dispatch {
            let task = self.dataTask(with: url) { (d, response, e) in
                data = d
                error = e
                lock.stop()
            }
            task.resume()
        }

        try lock.run()

        if let d = data {
            return d
        } else {
            throw error!
        }
    }
}
