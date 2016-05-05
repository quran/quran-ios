//
//  NSLocking+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension NSLocking {

    @warn_unused_result
    func execute<T>(@noescape block: () -> T) -> T {
        lock()
        let result = block()
        unlock()
        return result
    }

    func execute(@noescape block: () -> Void) {
        lock()
        block()
        unlock()
    }
}
