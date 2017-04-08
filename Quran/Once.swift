//
//  Once.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
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
