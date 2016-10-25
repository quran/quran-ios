//
//  Once.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

// class not struct to allow let declaration because once will be a mutating function.
final class Once {

    fileprivate (set) var executed = false

    fileprivate let lock = NSLock()

    func once(_ block: () -> Void) {

        // early check with no lock for performance optimization
        guard !executed else {
            return
        }

        let shouldExecute: Bool = lock.execute {
            // check again inside a lock to prevent 2 threads entering at the same time
            guard !executed else {
                return false
            }
            executed = true
            return true
        }
        if shouldExecute {
            block()
        }
    }
}
